extends GutTest
## T016: test de `scenes/enemies/enemigo.gd` (`Enemigo`, `EnemigoBase.tscn`)
## — cubre "recepción de daño" y "cálculo de daño"/"muerte" de
## `constitution.md` Principio II, y la emisión de `enemy_defeated` con la
## munición que suelta el enemigo derrotado (FR-007, `spec.md` User Story 2
## Acceptance Scenario 1, `contracts/signals.md` sección `Enemigo`).
##
## `Enemigo` (T018/T025/T026) ya existe en este punto (implementado por
## dev-godot en paralelo a T015, que usaba `enemigo_double.gd` como stand-in
## del contrato). Este archivo prueba la implementación real, no el double.
##
## `reached_defended_position()` (T043) e integración con `ObjectPool`
## (T042) están fuera de alcance de esta tarea — no se testean aquí.
##
## IMPORTANTE (mismo patrón que `tests/unit/units/test_soldado.gd`):
## `enemigo.gd` copia `stats.max_health` a `_current_health` en `_ready()`
## (snapshot de una sola vez, `docs/ARCHITECTURE.md` §4.3). Por eso
## cualquier `EnemyStats` con overrides debe asignarse ANTES de agregar el
## enemigo al árbol (ver `_spawn_enemy`).

const ENEMY_SCENE_PATH := "res://scenes/enemies/EnemigoBase.tscn"
const ENEMY_STATS_SCRIPT_PATH := "res://resources/schemas/enemy_stats.gd"

# Defaults calcados de `resources/enemies/enemigo_infanteria_base.tres`; cada
# test que necesite un valor distinto pasa overrides a `_spawn_enemy`.
const DEFAULT_MAX_HEALTH := 15
const DEFAULT_MOVE_SPEED := 40.0
const DEFAULT_MELEE_DAMAGE := 5
const DEFAULT_AMMO_DROP := 3

var _enemy: Node
var _stats: Resource


func before_each() -> void:
	_enemy = null
	_stats = null


## Crea un `EnemyStats` con los defaults de este archivo (más overrides),
## instancia `EnemigoBase.tscn` con ese `stats` ya asignado, y lo agrega al
## árbol — en ese orden, para que `_ready()` snapshotee la salud correcta.
func _spawn_enemy(overrides: Dictionary = {}) -> Node:
	_stats = load(ENEMY_STATS_SCRIPT_PATH).new()
	_stats.max_health = overrides.get("max_health", DEFAULT_MAX_HEALTH)
	_stats.move_speed = overrides.get("move_speed", DEFAULT_MOVE_SPEED)
	_stats.melee_damage = overrides.get("melee_damage", DEFAULT_MELEE_DAMAGE)
	_stats.ammo_drop = overrides.get("ammo_drop", DEFAULT_AMMO_DROP)

	_enemy = load(ENEMY_SCENE_PATH).instantiate()
	_enemy.stats = _stats
	add_child_autofree(_enemy)
	return _enemy


## --- Carga de la escena (confirmación pedida por el orquestador: dev-godot
## no pudo validar que `EnemigoBase.tscn` cargue/parsee sin errores) ---

func test_enemigo_base_scene_instantiates_and_joins_enemies_group() -> void:
	# Given/When: se instancia EnemigoBase.tscn y entra al árbol
	var enemy := _spawn_enemy()

	# Then: no hubo errores de carga/parseo y el enemigo queda en el grupo
	# "enemies" que usa `Soldado` para detectarlo (contrato de `soldado.gd`)
	assert_true(is_instance_valid(enemy), "EnemigoBase.tscn debe instanciar sin errores")
	assert_true(
		enemy.is_in_group("enemies"),
		"el enemigo debe unirse al grupo 'enemies' en _ready()"
	)


## --- Recepción de daño (constitution.md Principio II) ---

func test_take_damage_returns_false_when_the_hit_does_not_deplete_health() -> void:
	# Given: un enemigo con salud de sobra respecto al golpe
	var enemy := _spawn_enemy({"max_health": 15})

	# When: recibe un golpe que no lo mata
	var died: bool = enemy.take_damage(5)

	# Then: take_damage reporta que ese golpe no fue letal
	assert_false(died, "take_damage debe retornar false cuando el enemigo sobrevive al golpe")


func test_take_damage_accumulates_across_multiple_calls_before_dying() -> void:
	# Given: un enemigo con 15 de salud
	var enemy := _spawn_enemy({"max_health": 15})

	# When/Then: dos golpes de 5 (10/15 acumulado) no matan; el tercero,
	# que completa exactamente los 15, sí
	assert_false(enemy.take_damage(5), "primer golpe (5/15 acumulado) no debe matar")
	assert_false(enemy.take_damage(5), "segundo golpe (10/15 acumulado) no debe matar")
	assert_true(
		enemy.take_damage(5),
		"el golpe que completa exactamente max_health acumulado debe reportar la muerte"
	)


func test_take_damage_returns_true_on_lethal_call_even_with_overkill_damage() -> void:
	# Given: un enemigo con salud baja
	var enemy := _spawn_enemy({"max_health": 10})

	# When: recibe un golpe muchísimo mayor a su salud restante
	var died: bool = enemy.take_damage(999)

	# Then: igual reporta la muerte (no se espera un daño "exacto" para matar)
	assert_true(died, "un golpe que excede la salud restante debe reportar la muerte igualmente")


func test_take_damage_returns_false_on_repeated_calls_after_the_lethal_hit() -> void:
	# Given: un enemigo ya eliminado por una llamada anterior (su queue_free
	# es diferido, así que el nodo puede seguir recibiendo llamadas en el
	# mismo frame)
	var enemy := _spawn_enemy({"max_health": 10})
	var first_call_died: bool = enemy.take_damage(10)

	# When: se le vuelve a llamar take_damage tras la muerte
	var second_call_died: bool = enemy.take_damage(5)

	# Then: solo la llamada que efectivamente mató reporta true; las
	# llamadas posteriores sobre un enemigo ya derrotado deben ser inertes
	assert_true(first_call_died, "precondición: el primer golpe debe haber matado al enemigo")
	assert_false(
		second_call_died,
		"una llamada a take_damage sobre un enemigo ya derrotado no debe reportar una nueva muerte"
	)


## --- Emisión de enemy_defeated con ammo_drop (FR-007, contracts/signals.md) ---

func test_enemy_defeated_is_not_emitted_when_a_hit_does_not_kill() -> void:
	# Given: un enemigo con salud de sobra
	var enemy := _spawn_enemy({"max_health": 15})
	watch_signals(enemy)

	# When: recibe un golpe que no lo mata
	enemy.take_damage(5)

	# Then: no se emite enemy_defeated
	assert_signal_not_emitted(
		enemy, "enemy_defeated",
		"enemy_defeated no debe emitirse mientras el enemigo sigue con salud > 0"
	)


func test_enemy_defeated_is_emitted_with_stats_ammo_drop_and_death_position_on_lethal_hit() -> void:
	# Given: un enemigo con un ammo_drop configurado explícitamente, en una
	# posición conocida
	var enemy := _spawn_enemy({"max_health": 10, "ammo_drop": 7})
	enemy.global_position = Vector2(123.0, 456.0)
	watch_signals(enemy)

	# When: recibe un golpe letal
	enemy.take_damage(10)

	# Then: enemy_defeated se emite con exactamente stats.ammo_drop y la
	# posición global del enemigo en el momento de morir (FR-007,
	# spec.md User Story 2 Acceptance Scenario 1)
	assert_signal_emitted(
		enemy, "enemy_defeated",
		"enemy_defeated debe emitirse al recibir un golpe letal (FR-007)"
	)
	var params: Array = get_signal_parameters(enemy, "enemy_defeated")
	assert_eq(
		params[0], 7,
		"el payload ammo_dropped de enemy_defeated debe ser exactamente stats.ammo_drop"
	)
	assert_eq(
		params[1], Vector2(123.0, 456.0),
		"el payload position de enemy_defeated debe ser la posición global del enemigo al morir"
	)


func test_enemy_defeated_is_emitted_exactly_once_despite_repeated_calls_after_death() -> void:
	# Given: un enemigo que recibe un golpe letal
	var enemy := _spawn_enemy({"max_health": 10})
	watch_signals(enemy)
	enemy.take_damage(10)

	# When: llega una llamada defensiva adicional tras la muerte (antes de
	# que se procese el queue_free diferido)
	enemy.take_damage(5)

	# Then: enemy_defeated no debe duplicarse por esa llamada extra
	assert_signal_emit_count(
		enemy, "enemy_defeated", 1,
		"enemy_defeated debe emitirse exactamente una vez, sin importar llamadas repetidas post-muerte"
	)


func test_enemy_is_removed_from_the_scene_tree_after_being_defeated() -> void:
	# Given: un enemigo en el árbol
	var enemy := _spawn_enemy({"max_health": 5})

	# When: recibe un golpe letal y transcurre al menos un frame (queue_free
	# es diferido, no inmediato — docs/ARCHITECTURE.md §4.5)
	enemy.take_damage(5)
	await wait_physics_frames(1)

	# Then: el nodo queda liberado del árbol
	assert_false(
		is_instance_valid(enemy),
		"el enemigo debe quedar liberado (queue_free) tras ser derrotado"
	)


# 015/T005: escenario aislado, actores de producción y World2D propio.
func _ranged_fixture(target_position := Vector2(144, 336), contact := false) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	var soldier: Soldado = load("res://scenes/units/Soldado.tscn").instantiate()
	soldier.stats = soldier.stats.duplicate()
	soldier.stats.damage_per_shot = 0 # Blanco vivo; la prueba no mide el fusil colombiano.
	soldier.set_grid_cell(Vector2i(1, 3))
	soldier.position = target_position
	viewport.add_child(soldier)
	soldier.set_physics_process(contact)
	var enemy: Enemigo = load(ENEMY_SCENE_PATH).instantiate()
	enemy.stats = enemy.stats.duplicate()
	enemy.stats.max_health = 1000
	enemy.stats.rifle_range = 864.0
	enemy.stats.rifle_damage = 2
	enemy.stats.rifle_interval = 0.2
	enemy.position = Vector2(204 if contact else 1008, 336)
	enemy.lane_id = 2
	viewport.add_child(enemy)
	watch_signals(enemy)
	return {"enemy": enemy, "soldier": soldier}


func test_enemy_rifle_acquires_stops_and_fires_at_its_interval() -> void:
	var previous = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var f := _ranged_fixture()
	await wait_physics_frames(3)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 1, "Primer tiro inmediato por física real")
	assert_eq(f.soldier.get_reload_state().health, 28, "Un tiro, un daño de perfil")
	assert_almost_eq(f.enemy.position.x, 1008.0, 0.01, "Se detiene al adquirir blanco")
	await wait_physics_frames(14)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 2, "Segundo tiro tras intervalo0.2, sin ráfaga")
	assert_eq(f.soldier.get_reload_state().health, 26)
	GameStateManager._current_state = previous


func test_enemy_rejects_nonfrontal_other_lane_out_of_range_and_dead_targets(
	position = use_parameters([Vector2(1100, 336), Vector2(144, 240), Vector2(80, 336)])) -> void:
	var previous = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var f := _ranged_fixture(position)
	await wait_physics_frames(3)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 0)
	assert_eq(f.soldier.get_reload_state().health, 30)
	assert_lt(f.enemy.position.x, 1008.0, "Sin blanco elegible continúa marcha")
	GameStateManager._current_state = previous


func test_enemy_lost_target_resumes_march_and_reacquires_a_living_replacement() -> void:
	var previous = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var f := _ranged_fixture()
	await wait_physics_frames(3)
	f.soldier.position.y = 240
	var before: float = f.enemy.position.x
	await wait_physics_frames(3)
	assert_lt(f.enemy.position.x, before, "Salir de carril libera la marcha")
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 1)
	f.soldier.position = Vector2(144, 336)
	await wait_physics_frames(3)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 2, "Nueva adquisición inmediata")
	f.soldier.take_damage(999)
	await wait_physics_frames(2)
	before = f.enemy.position.x
	await wait_physics_frames(3)
	assert_lt(f.enemy.position.x, before, "Un cadáver nunca mantiene fijado al enemigo")
	var replacement: Soldado = load("res://scenes/units/Soldado.tscn").instantiate()
	replacement.position = Vector2(144, 336)
	replacement.set_grid_cell(Vector2i(1, 3))
	f.enemy.get_parent().add_child(replacement)
	replacement.set_physics_process(false)
	await wait_physics_frames(3)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 3, "Adquiere otro nodo vivo tras retirar el anterior")
	assert_eq(replacement.get_reload_state().health, 28)
	GameStateManager._current_state = previous


func test_enemy_contact_keeps_melee_without_adding_rifle_damage() -> void:
	var previous = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var f := _ranged_fixture(Vector2(144, 336), true)
	await wait_physics_frames(5)
	assert_eq(f.soldier.get_reload_state().health, 25, "Contacto vigente5, sin sumar fusil2")
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 0)
	GameStateManager._current_state = previous


func test_enemy_pause_terminal_and_reactivation_do_not_carry_target_or_backlog() -> void:
	var previous = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var f := _ranged_fixture()
	await wait_physics_frames(3)
	GameStateManager._current_state = GameStateManager.GameState.PAUSED
	var before: Vector2 = f.enemy.position
	await wait_physics_frames(20)
	assert_eq(f.enemy.position, before)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 1)
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	await wait_physics_frames(2)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 1, "Sin descargar ráfaga atrasada")
	f.enemy.on_pool_released()
	f.enemy.prepare_for_spawn(f.enemy.stats, Vector2(1008, 240), 1)
	await wait_physics_frames(3)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 1, "Activación nueva no hereda blanco del otro carril")
	f.enemy.prepare_for_spawn(f.enemy.stats, Vector2(1008, 336), 2)
	await wait_physics_frames(3)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 2, "Activación válida empieza limpia")
	GameStateManager._current_state = GameStateManager.GameState.WON
	await wait_physics_frames(20)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 2)
	GameStateManager._current_state = previous


func test_enemy_revalidates_shooter_and_target_after_synchronous_shot_listeners(
	scenario = use_parameters(["target_moves", "shooter_recycled"])) -> void:
	var previous = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var f := _ranged_fixture()
	f.enemy.rifle_shot_visual_requested.connect(func(_snapshot: Dictionary):
		if scenario == "target_moves":
			f.soldier.position.y = 240
		else:
			f.enemy.on_pool_released()
			f.enemy.prepare_for_spawn(f.enemy.stats, Vector2(1008, 240), 1))
	await wait_physics_frames(3)
	assert_eq(get_signal_emit_count(f.enemy, "rifle_shot_visual_requested"), 1, "Control: listeners síncronos se ejecutan desde el tiro real")
	assert_eq(f.soldier.get_reload_state().health, 30, "No aplicar hitscan a contexto invalidado durante callbacks")
	if scenario == "shooter_recycled": assert_eq(f.enemy.activation_generation, 1)
	GameStateManager._current_state = previous
