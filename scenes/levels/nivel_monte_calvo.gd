## Composición de Monte Calvo: cinco plazas, entrada horizontal y economía.
## La ocupación se asocia al origen, independientemente de la posición del actor.
extends Node2D

## El nivel propaga intenciones; la raíz conserva la autoridad de navegación.
signal retry_requested
signal menu_requested
## 017/I2 (prerrequisito T027): firma neutral para un futuro aviso de
## éxito/fallo de guardado del comandante hacia la raíz (contrato §6, texto
## de fallo terminal mostrado en resultado o menú). No se emite todavía;
## T037 decidirá el momento exacto y T042 su presentación.
signal commander_save_feedback(message: String)

@export var board_config: LaneBoardConfig = preload("res://resources/levels/monte_calvo_board.tres")
@export var soldado_scene: PackedScene = preload("res://scenes/units/Soldado.tscn")
@export var soldado_deploy_stats: UnitStats = preload("res://resources/units/soldado_base_stats.tres")
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/EnemigoBase.tscn")
@export var initial_enemy_stats: EnemyStats = preload("res://resources/enemies/enemigo_infanteria_base.tres")
## 017/I2 (prerrequisito T027): mismo balance compartido referenciado por
## `game_root.gd`; necesario para la futura `CommanderSession.begin_match()`.
@export var commander_config: CommanderConfig = preload("res://resources/director/monte_calvo_commander.tres")

@export var waves: Array[WaveData] = [
	preload("res://resources/waves/nivel_montecalvo_oleada_01.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_02.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_03.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_04.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_05.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_06.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_07.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_08.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_09.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_10.tres"),
]

## Compatibilidad de setup para spawners sin configuración por carriles.
@export var wave_spawn_position: Vector2 = Vector2(1008, 336)

const _ENEMY_POOL_INITIAL_SIZE := 10

## 017/I2 T032: propiedades de inyección que `game_root.gd::_start_match()`
## asigna antes de `add_child(_current_level)`, siguiendo el mismo patrón que
## `soldier.stats`/`soldier.board_config` en `_create_soldier()`. En una
## escena directa de desarrollo sin raíz (`commander_store` sigue `null` al
## llegar a `_ready()`), el nivel crea su propio almacén TRANSIENT — contrato
## §4, "usar almacén TRANSIENT sin rutas reales; esa ejecución no acredita
## persistencia".
var commander_store: CommanderMemoryStore
var commander_seed: int = 0
## 017/I2 T032: sesión real del comandante, instanciada en `_ready()` tras
## crear los defensores y antes de `WaveManager.start_waves()` (contrato §4).
var commander_session: CommanderSession
## 017/I2 T037: generación de memoria que `commander_store.load_compatible()`
## reportó al instanciar `commander_session` (contrato §4, "guardar sólo con
## Store verificado"). `CommanderMemoryStore.save()` exige exactamente esa
## generación de origen (igual a `candidate.memory.generation`, intacta desde
## `finish()`) para aceptar el guardado; capturada aquí porque es el único
## punto donde el nivel conoce el resultado real de `load_compatible()`.
var _commander_expected_generation: int = 0

var _board_manager := BoardManager.new()
var _wave_spawner := WaveSpawner.new()
var _combat_visual_effects := CombatVisualEffects.new()
var _combat_audio := CombatAudio.new()
var _deploying_cells: Dictionary[Vector2i, bool] = {}
var _selected_soldier: Soldado
var _selected_home := Vector2i(-1, -1)
var _closing: bool = false

@onready var _tablero: TileMap = $Tablero
@onready var _posicion_defendida: Area2D = $PosicionDefendida
@onready var _defended_shape: CollisionShape2D = $PosicionDefendida/CollisionShape2D
@onready var _legacy_trenches: Node2D = $MonteCalvoVisual/Trincheras
@onready var _board_visual: LaneBoardVisual = $HorizontalBoardVisual
@onready var _hud = $HUD


func request_trench_reload(home_cell: Vector2i, expected_instance_id: int) -> bool:
	if _closing or GameStateManager._current_state != GameStateManager.GameState.PLAYING \
			or not board_config.home_cells.has(home_cell):
		return false
	var soldier := _board_manager.get_occupant(home_cell) as Soldado
	if not is_instance_valid(soldier) or soldier.get_instance_id() != expected_instance_id:
		return false
	var state := soldier.get_reload_state()
	if not state.alive or state.home_cell != home_cell:
		return false
	return soldier.request_reload()


func select_trench(cell: Vector2i) -> bool:
	if _closing or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return false
	if not board_config.home_cells.has(cell):
		return false
	var soldier := _board_manager.get_occupant(cell) as Soldado
	if not is_instance_valid(soldier) or not soldier.get_reload_state().alive:
		return false
	_selected_home = cell
	_selected_soldier = soldier
	_hud.set_selected_soldier(soldier)
	return true


func get_selected_soldier() -> Soldado:
	if is_instance_valid(_selected_soldier) and _selected_soldier.get_reload_state().alive \
			and _board_manager.get_occupant(_selected_home) == _selected_soldier:
		return _selected_soldier
	return null


## La identidad será obligatoria para rechazar intenciones de dueños anteriores.
func request_selected_reload(expected_instance_id: int) -> bool:
	if _closing:
		return false
	var soldier := get_selected_soldier()
	if soldier == null or soldier.get_instance_id() != expected_instance_id:
		return false
	return soldier.request_reload()


func _ready() -> void:
	assert(board_config != null, "Monte Calvo requiere su configuración de tablero")
	GameStateManager.start_new_match()
	_legacy_trenches.visible = false
	_board_visual.board_config = board_config
	EconomyManager.reset_ammo_pool()
	_hud.trench_reload_requested.connect(request_trench_reload)
	$Camera2D.framing_changed.connect(_hud.update_trench_reload_layout)
	_hud.retry_requested.connect(_on_retry_requested)
	_hud.menu_requested.connect(_on_menu_requested)
	add_child(_combat_visual_effects)
	_combat_visual_effects.setup()
	add_child(_combat_audio)
	_combat_audio.setup(preload("res://resources/audio/combat_audio_profile.tres"))

	for home: Vector2i in board_config.home_cells:
		_create_soldier(home)

	_setup_commander_session()
	# 017/I2 T037 (contrato §4, "conectar una vez por nivel y desconectar al
	# cerrar"): única consolidación real de la sesión, en el mismo momento
	# en que el resultado terminal se vuelve público para el resto del juego.
	GameStateManager.game_won.connect(_on_commander_game_won)
	GameStateManager.game_lost.connect(_on_commander_game_lost)

	var defended_body := RectangleShape2D.new()
	defended_body.size = board_config.defended_rect.size
	_defended_shape.shape = defended_body
	_posicion_defendida.position = board_config.defended_rect.get_center()
	_posicion_defendida.body_entered.connect(_on_posicion_defendida_body_entered)

	add_child(_wave_spawner)
	_wave_spawner.setup(enemy_scene, _ENEMY_POOL_INITIAL_SIZE, wave_spawn_position,
		_combat_visual_effects, board_config, _combat_audio, commander_session, _board_manager)
	_wave_spawner.spawn_initial_enemy(initial_enemy_stats)
	WaveManager.start_waves(waves)


## 017/I2 T032 (contrato §4, "Nivel `_ready()`: ... Configurar Session tras
## crear defensores y antes del primer WAVE"): escena directa sin raíz
## (`commander_store` sigue `null` porque nadie la inyectó) usa un almacén
## TRANSIENT propio, sin rutas reales; producción recibe siempre el
## `CommanderMemoryStore` compartido de `game_root.gd::_start_match()`
## (contrato §4, "El nivel de producción siempre instala el comandante").
func _setup_commander_session() -> void:
	if commander_store == null:
		commander_store = CommanderMemoryStore.new()
		commander_store.transient = true
	var load_result: Dictionary = commander_store.load_compatible(commander_config)
	var loaded_memory: Dictionary = load_result.get("memory", {})
	_commander_expected_generation = int(loaded_memory.get("generation", 0))
	commander_session = CommanderSession.new()
	commander_session.begin_match(_commander_match_id(), commander_seed, commander_config, loaded_memory)


## Identidad de partida sin rutas de archivo: suficiente para diagnóstico
## (`get_decision_snapshot()`) sin acreditar persistencia por sí sola.
func _commander_match_id() -> String:
	return "monte_calvo:%d:%d" % [commander_seed, Time.get_ticks_usec()]


func _on_retry_requested() -> void:
	if not _closing:
		retry_requested.emit()


func _on_menu_requested() -> void:
	if not _closing:
		menu_requested.emit()


## 017/I2 T037 (contrato §4, "conectar una vez por nivel y desconectar al
## cerrar"; requisito 6, "única consolidación por terminal real"): conectadas
## en `_ready()` y desconectadas en `close_match()`. Cada handler delega en
## `_consolidate_commander_result()`, que guarda el mismo comportamiento para
## WON/LOST salvo el resultado pasado a `CommanderSession.finish()`.
func _on_commander_game_won() -> void:
	_consolidate_commander_result(GameStateManager.GameState.WON)


func _on_commander_game_lost() -> void:
	_consolidate_commander_result(GameStateManager.GameState.LOST)


## Guard (contrato §4): nada que consolidar sin sesión activa — cubre tanto
## una sesión nunca activada (config inválida) como una ya `FINALIZED`/
## `ABANDONED` (evita una doble consolidación si este handler se disparara
## más de una vez, aunque `GameStateManager` no emita el resultado dos veces
## hoy). `commander_session.finish()` deja el estado en `FINALIZED` y
## devuelve si la experiencia cambió; sólo con `changed == true` se guarda
## (contrato §3, "cambiar=false conserva exactamente la memoria anterior, sin
## guardar"). El resultado de `commander_store.save()` (contrato §6, errores
## de save) se reporta por `commander_save_feedback` para que US3 (T042) lo
## muestre; los textos exactos son los del contrato §6, último párrafo
## ("No se pudo guardar lo aprendido..."/"Lo aprendido se conservará sólo
## mientras esta sesión esté abierta"), consumidos por `game_root.gd` al
## volver al menú tras un resultado real.
func _consolidate_commander_result(result: int) -> void:
	if commander_session == null or commander_session.get_decision_snapshot().get("state") != "ACTIVE":
		return
	var candidate: Dictionary = commander_session.finish(result)
	if not candidate.get("changed", false):
		return
	var save_result: Dictionary = commander_store.save(candidate, _commander_expected_generation)
	var status: String = save_result.get("status", "")
	if status == "OK":
		if commander_store.transient:
			commander_save_feedback.emit("Lo aprendido se conservará sólo mientras esta sesión esté abierta")
		else:
			commander_save_feedback.emit("El comandante aprendió de esta partida y guardó su memoria.")
	else:
		commander_save_feedback.emit("No se pudo guardar lo aprendido. Puedes seguir jugando")


## El cierre es local: la raíz cancela los Managers antes de retirar el nivel.
func close_match() -> void:
	if _closing:
		return
	_closing = true
	# Contrato §4, "`close_match()`/`_exit_tree()`: abandonar sólo si aún
	# ACTIVE; nunca consolidar": MENU (vía `_on_retry_requested`/
	# `_on_menu_requested`) nunca es un resultado WON/LOST, así que este
	# cierre nunca intenta reconstruir uno. Si la sesión ya quedó FINALIZED
	# (T037) o nunca llegó a activarse, no hay nada que hacer aquí.
	if commander_session != null and commander_session.get_decision_snapshot().get("state") == "ACTIVE":
		commander_session.abandon()
	if GameStateManager.game_won.is_connected(_on_commander_game_won):
		GameStateManager.game_won.disconnect(_on_commander_game_won)
	if GameStateManager.game_lost.is_connected(_on_commander_game_lost):
		GameStateManager.game_lost.disconnect(_on_commander_game_lost)
	_combat_audio.close_match()
	_combat_visual_effects.close_match()
	set_process_unhandled_input(false)
	_wave_spawner.close_match()
	_hud.close_match()
	for audio: Node in find_children("*", "AudioStreamPlayer", true, false):
		(audio as AudioStreamPlayer).stop()
	if $Camera2D.framing_changed.is_connected(_hud.update_trench_reload_layout):
		$Camera2D.framing_changed.disconnect(_hud.update_trench_reload_layout)
	_selected_soldier = null
	_selected_home = Vector2i(-1, -1)
	_deploying_cells.clear()
	if _posicion_defendida.body_entered.is_connected(_on_posicion_defendida_body_entered):
		_posicion_defendida.body_entered.disconnect(_on_posicion_defendida_body_entered)
	for child: Node in get_children():
		if child != _hud:
			child.process_mode = Node.PROCESS_MODE_DISABLED


func _exit_tree() -> void:
	close_match()


func _unhandled_input(event: InputEvent) -> void:
	if _closing or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return
	if not event.is_action_pressed("select_cell"):
		return

	var screen_position: Vector2
	if event is InputEventMouseButton:
		screen_position = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		screen_position = (event as InputEventScreenTouch).position
	else:
		return

	var world_position := _screen_to_world(screen_position)
	# _unhandled_input precede al physics picking: este gesto sigue siendo
	# exclusivamente una recogida, también con mouse emulado de touch.
	if _has_pickable_ammo_at(world_position):
		return
	var cell := _world_to_cell(world_position)
	if not select_trench(cell):
		_try_deploy_soldado(cell)
	get_viewport().set_input_as_handled()


func _has_pickable_ammo_at(world_position: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_point(query, 64):
		var pickup := hit["collider"] as AmmoPickup
		if pickup != null and pickup.input_pickable and pickup.is_visible_in_tree():
			return true
	return false


func _try_deploy_soldado(cell: Vector2i) -> void:
	if _closing or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return
	if not board_config.home_cells.has(cell) or not _board_manager.is_cell_free(cell):
		return
	if _deploying_cells.has(cell):
		return
	# Un listener síncrono del gasto tampoco puede crear un segundo dueño.
	_deploying_cells[cell] = true
	if EconomyManager.try_spend_ammo(soldado_deploy_stats.deploy_ammo_cost):
		_create_soldier(cell)
	_deploying_cells.erase(cell)


func _create_soldier(cell: Vector2i) -> void:
	var soldier := soldado_scene.instantiate() as Soldado
	soldier.stats = soldado_deploy_stats
	soldier.board_config = board_config
	soldier.position = to_local(_tablero.to_global(_tablero.map_to_local(cell)))
	soldier.set_grid_cell(cell)
	soldier.soldier_defeated.connect(_on_soldado_defeated)
	_board_manager.occupy_cell(cell, soldier)
	add_child(soldier)
	_combat_visual_effects.register_actor(soldier)
	_combat_audio.register_actor(soldier)
	var lane := board_config.home_cells.find(cell) + 1
	var pieces: Array[Sprite2D] = [
		get_node("MonteCalvoVisual/TrincherasLaterales/Posterior%d" % lane) as Sprite2D,
		get_node("MonteCalvoVisual/TrincherasLaterales/Parapeto%d" % lane) as Sprite2D,
	]
	_hud.register_trench_reload(cell, soldier, _tablero.to_global(_tablero.map_to_local(cell)), pieces)


## 017/I2 T037 (contrato §4, "registrar `record_breach` antes de notificar"):
## sólo un cruce WAVE real con sesión inyectada cierra su propio registro del
## comandante ANTES de `GameStateManager.report_reached_defended_position()`
## — esa notificación puede disparar de forma síncrona el `game_lost` que
## consolida la sesión, así que el registro debe quedar `BREACHED` primero.
## El INITIAL nunca pasa por `register_spawn()` (FR-001): nunca llama
## `record_breach` para no abrir/cerrar un registro que jamás existió.
func _on_posicion_defendida_body_entered(body: Node2D) -> void:
	if _closing or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return
	var enemy := body as Enemigo
	if enemy == null or not enemy.is_targetable():
		return
	if enemy.spawn_origin == Enemigo.SpawnOrigin.WAVE and commander_session != null:
		commander_session.record_breach(enemy.get_instance_id(), enemy.activation_generation)
	enemy.notify_reached_defended_position()
	GameStateManager.report_reached_defended_position()


func _on_soldado_defeated(grid_cell: Vector2i) -> void:
	if _closing:
		return
	_board_manager.free_cell(grid_cell)
	_hud.unregister_trench_reload(grid_cell)
	if grid_cell == _selected_home:
		_selected_soldier = null
		_selected_home = Vector2i(-1, -1)
		_hud.set_selected_soldier(null)


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * screen_position


func _world_to_cell(world_position: Vector2) -> Vector2i:
	return _tablero.local_to_map(_tablero.to_local(world_position))
