## Composición de Monte Calvo: cinco plazas, entrada horizontal y economía.
## La ocupación se asocia al origen, independientemente de la posición del actor.
extends Node2D

## El nivel propaga intenciones; la raíz conserva la autoridad de navegación.
signal retry_requested
signal menu_requested

@export var board_config: LaneBoardConfig = preload("res://resources/levels/monte_calvo_board.tres")
@export var soldado_scene: PackedScene = preload("res://scenes/units/Soldado.tscn")
@export var soldado_deploy_stats: UnitStats = preload("res://resources/units/soldado_base_stats.tres")
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/EnemigoBase.tscn")
@export var initial_enemy_stats: EnemyStats = preload("res://resources/enemies/enemigo_infanteria_base.tres")

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

var _board_manager := BoardManager.new()
var _wave_spawner := WaveSpawner.new()
var _combat_visual_effects := CombatVisualEffects.new()
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

	for home: Vector2i in board_config.home_cells:
		_create_soldier(home)

	var defended_body := RectangleShape2D.new()
	defended_body.size = board_config.defended_rect.size
	_defended_shape.shape = defended_body
	_posicion_defendida.position = board_config.defended_rect.get_center()
	_posicion_defendida.body_entered.connect(_on_posicion_defendida_body_entered)

	add_child(_wave_spawner)
	_wave_spawner.setup(enemy_scene, _ENEMY_POOL_INITIAL_SIZE, wave_spawn_position,
		_combat_visual_effects, board_config)
	_wave_spawner.spawn_initial_enemy(initial_enemy_stats)
	WaveManager.start_waves(waves)


func _on_retry_requested() -> void:
	if not _closing:
		retry_requested.emit()


func _on_menu_requested() -> void:
	if not _closing:
		menu_requested.emit()


## El cierre es local: la raíz cancela los Managers antes de retirar el nivel.
func close_match() -> void:
	if _closing:
		return
	_closing = true
	_combat_visual_effects.close_match()
	set_process_unhandled_input(false)
	_wave_spawner.close_match()
	_hud.close_match()
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
	_hud.register_trench_reload(cell, soldier, _tablero.to_global(_tablero.map_to_local(cell)))


func _on_posicion_defendida_body_entered(body: Node2D) -> void:
	if _closing or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return
	var enemy := body as Enemigo
	if enemy == null or not enemy.is_targetable():
		return
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
