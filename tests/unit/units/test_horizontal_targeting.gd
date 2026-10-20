extends GutTest
## 005/I1 T007: FR-004/009 con escenas y detección física reales.
## El enemigo conserva su cuerpo 48×48 y take_damage de producción. Solo se
## detiene su locomoción para medir posiciones/rangos sin depender del avance.
## Nunca se invocan callbacks de detección ni se inyectan candidatos/blancos.

const SOLDIER_SCENE: PackedScene = preload("res://scenes/units/Soldado.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/EnemigoBase.tscn")
const UNIT_STATS: UnitStats = preload("res://resources/units/soldado_base_stats.tres")
const ENEMY_STATS: EnemyStats = preload("res://resources/enemies/enemigo_infanteria_base.tres")
const DETECTION_FRAMES := 8

var _world: Node2D
var _soldier: Soldado
var _saved_game_state: int


func before_each() -> void:
	_saved_game_state = GameStateManager.get("_current_state")
	GameStateManager.set("_current_state", GameStateManager.GameState.PLAYING)
	_world = Node2D.new()
	add_child_autofree(_world)
	_soldier = null


func after_each() -> void:
	GameStateManager.set("_current_state", _saved_game_state)


func _spawn_soldier(row: int = 2, ammo: int = UNIT_STATS.max_ammo) -> Soldado:
	_soldier = SOLDIER_SCENE.instantiate() as Soldado
	_soldier.stats = UNIT_STATS.duplicate() as UnitStats
	_soldier.stats.max_ammo = ammo
	_soldier.position = Vector2(144, 144 + 96 * row)
	_soldier.set_grid_cell(Vector2i(1, row + 1))
	_world.add_child(_soldier)
	return _soldier


func _enemy_at(offset: Vector2, row: int = 2, health: int = 500) -> Enemigo:
	var enemy := ENEMY_SCENE.instantiate() as Enemigo
	var stats := ENEMY_STATS.duplicate() as EnemyStats
	stats.max_health = health
	enemy.stats = stats
	_world.add_child(enemy)
	enemy.prepare_for_spawn(stats, _soldier.global_position + offset,
		row, Enemigo.SpawnOrigin.INITIAL)
	enemy.set_physics_process(false)
	return enemy


func _health(enemy: Enemigo) -> int:
	# No hay getter público de salud; se observa el resultado real del impacto.
	return enemy.get("_current_health")


func _ammo() -> int:
	return _soldier.get("_current_ammo")


func test_loaded_soldier_fires_right_in_each_row_and_stays_home(
		row = use_parameters([0, 1, 2, 3, 4])) -> void:
	_spawn_soldier(row)
	var home := _soldier.global_position
	var enemy := _enemy_at(Vector2(150, 0), row, ENEMY_STATS.max_health)
	watch_signals(_soldier)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), ENEMY_STATS.max_health - UNIT_STATS.damage_per_shot,
		"Fila %d: el objetivo a derecha recibe exactamente un disparo" % (row + 1))
	assert_eq(_ammo(), UNIT_STATS.max_ammo - 1, "Cada disparo consume una bala individual")
	assert_eq(_soldier.global_position, home, "Con carga permanece en su trinchera")
	assert_signal_not_emitted(_soldier, "moral_changed", "Un impacto sin baja no suma moral")


func test_rifle_reaches_the_direct_diagonal_cells_above_and_below(
		neighbor = use_parameters([1, 3])) -> void:
	_spawn_soldier()
	var enemy := _enemy_at(Vector2(96, (neighbor - 2) * 96), neighbor)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500 - UNIT_STATS.damage_per_shot,
		"La diagonal contigua es elegible aunque los cuerpos sean tangentes al broadphase antiguo")


func test_rifle_includes_both_sides_inside_the_direct_diagonal_cell(
		offset_x = use_parameters([49.0, 143.0])) -> void:
	_spawn_soldier()
	var enemy := _enemy_at(Vector2(offset_x, -96), 1)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500 - UNIT_STATS.damage_per_shot,
		"Los centros x193 y x287 pertenecen a la celda diagonal x2")


func test_rifle_excludes_neighbors_outside_the_direct_diagonal_cell(
		offset_x = use_parameters([47.0, 145.0])) -> void:
	_spawn_soldier()
	var enemy := _enemy_at(Vector2(offset_x, -96), 1)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500, "Ni x191 ni x289 son la celda diagonal directamente contigua")
	assert_eq(_ammo(), UNIT_STATS.max_ammo, "Una diagonal inválida no consume carga")


func test_rifle_cannot_reach_two_rows_away(
		row = use_parameters([0, 4])) -> void:
	_spawn_soldier()
	var enemy := _enemy_at(Vector2(96, (row - 2) * 96), row)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500, "Dos filas de separación quedan excluidas")
	assert_eq(_ammo(), UNIT_STATS.max_ammo)


func test_rifle_does_not_invent_outer_diagonals_for_first_and_fifth_rows(
		row = use_parameters([0, 4])) -> void:
	_spawn_soldier(row)
	var outside_row: int = -1 if row == 0 else 5
	var enemy := _enemy_at(Vector2(96, (outside_row - row) * 96), outside_row)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500, "Fuera de las cinco filas no existe una diagonal elegible")
	assert_eq(_ammo(), UNIT_STATS.max_ammo)


func test_rifle_excludes_a_target_behind_the_soldier() -> void:
	_spawn_soldier()
	var enemy := _enemy_at(Vector2(-96, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500, "El fusil solo combate hacia +X")
	assert_eq(_ammo(), UNIT_STATS.max_ammo)


func test_rifle_rejects_the_old_vertical_front() -> void:
	_spawn_soldier()
	var enemy := _enemy_at(Vector2(0, -150), 0)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500, "La antigua dirección −Y ya no es el frente colombiano")
	assert_eq(_ammo(), UNIT_STATS.max_ammo)


func test_longitudinal_range_uses_body_overlap_beyond_center_distance_264() -> void:
	_spawn_soldier()
	# Centro +287: borde izquierdo +263 solapa un píxel con [24,264].
	var enemy := _enemy_at(Vector2(287, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500 - UNIT_STATS.damage_per_shot,
		"264 limita la forma del fusil; el cuerpo enemigo puede solaparla con su centro a287")


func test_longitudinal_range_does_not_expand_past_the_authored_shape() -> void:
	_spawn_soldier()
	# Centro +289: borde izquierdo +265, fuera de [24,264].
	var enemy := _enemy_at(Vector2(289, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500, "Ensanchar el broadphase transversal no aumenta el alcance longitudinal")
	assert_eq(_ammo(), UNIT_STATS.max_ammo)


func test_near_longitudinal_edge_uses_body_overlap_and_keeps_the_front_filter() -> void:
	_spawn_soldier()
	# Centro +1: borde derecho +25 solapa [24,264]; centro −1 termina en+23.
	# Se conservan cuerpos reales48×48 y no se simulan callbacks de Area2D.
	var frontal := _enemy_at(Vector2(1, 0))
	var behind := _enemy_at(Vector2(-1, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(frontal), 500 - UNIT_STATS.damage_per_shot,
		"El borde proximal también se decide por el cuerpo, sin exigir centro≥24")
	assert_eq(_health(behind), 500, "El solape no autoriza atacar un centro detrás")
	assert_eq(_ammo(), UNIT_STATS.max_ammo - 1)


func test_a_new_more_advanced_enemy_does_not_steal_a_valid_target() -> void:
	_spawn_soldier()
	var current := _enemy_at(Vector2(206, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(current), 500 - UNIT_STATS.damage_per_shot,
		"Un impacto real establece el primer blanco con el soldado activo")
	var newcomer := _enemy_at(Vector2(96, -96), 1)
	var interval_frames := ceili(Engine.physics_ticks_per_second / UNIT_STATS.fire_rate)
	await wait_physics_frames(interval_frames)
	assert_eq(_health(current), 500 - 2 * UNIT_STATS.damage_per_shot,
		"El siguiente disparo sigue sobre el primer blanco válido")
	assert_eq(_health(newcomer), 500, "El recién llegado con menorX no roba foco")
	assert_eq(_ammo(), UNIT_STATS.max_ammo - 2, "No se divide fuego ni se consume una bala por candidato")


func test_losing_the_current_target_chooses_smallest_x_instead_of_largest_y() -> void:
	_spawn_soldier()
	var former := _enemy_at(Vector2(206, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(former), 500 - UNIT_STATS.damage_per_shot,
		"El disparo previo confirma qué blanco estaba adquirido")
	var most_advanced := _enemy_at(Vector2(96, -96), 1)
	var less_advanced := _enemy_at(Vector2(176, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	former.global_position = Vector2(-500, 336)
	var interval_frames := ceili(Engine.physics_ticks_per_second / UNIT_STATS.fire_rate)
	await wait_physics_frames(interval_frames)
	assert_eq(_health(most_advanced), 500 - UNIT_STATS.damage_per_shot,
		"Al perder blanco, x240 es más avanzado que x320 aunque suY sea menor")
	assert_eq(_health(less_advanced), 500)
	assert_eq(_health(former), 500 - UNIT_STATS.damage_per_shot,
		"El blanco que salió conserva solo el daño anterior a su salida")
	assert_eq(_ammo(), UNIT_STATS.max_ammo - 2)


func test_a_target_that_moves_to_a_deeper_diagonal_becomes_ineligible() -> void:
	_spawn_soldier()
	var former := _enemy_at(Vector2(96, -96), 1)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(former), 500 - UNIT_STATS.damage_per_shot,
		"Un disparo confirma la adquisición en la diagonal contigua")
	var eligible := _enemy_at(Vector2(186, 0))
	await wait_physics_frames(DETECTION_FRAMES)
	# x300 sigue en el broadphase y dentro del alcance, pero ya es celda x3.
	former.global_position.x = 300
	var interval_frames := ceili(Engine.physics_ticks_per_second / UNIT_STATS.fire_rate)
	await wait_physics_frames(interval_frames)
	assert_eq(_health(former), 500 - UNIT_STATS.damage_per_shot,
		"No recibe otro disparo tras salir de la diagonal válida aunque conserve solape amplio")
	assert_eq(_health(eligible), 500 - UNIT_STATS.damage_per_shot)
	assert_eq(_ammo(), UNIT_STATS.max_ammo - 2)


func test_rifle_preserves_production_cadence_and_does_not_award_morale_per_hit() -> void:
	_spawn_soldier()
	var enemy := _enemy_at(Vector2(150, 0))
	watch_signals(_soldier)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(_health(enemy), 500 - UNIT_STATS.damage_per_shot)
	var interval_frames := ceili(Engine.physics_ticks_per_second / UNIT_STATS.fire_rate)
	await wait_physics_frames(interval_frames - DETECTION_FRAMES - 4)
	assert_eq(_health(enemy), 500 - UNIT_STATS.damage_per_shot,
		"Antes de completar1/1.5s no se permite otro disparo")
	await wait_physics_frames(16)
	assert_eq(_health(enemy), 500 - 2 * UNIT_STATS.damage_per_shot)
	assert_eq(_ammo(), UNIT_STATS.max_ammo - 2)
	assert_signal_not_emitted(_soldier, "moral_changed", "Dos impactos no letales no dan moral")


func test_three_production_rifle_shots_kill_and_award_morale_once() -> void:
	_spawn_soldier()
	var defeats: Array = []
	var enemy := _enemy_at(Vector2(150, 0), 2, ENEMY_STATS.max_health)
	enemy.enemy_defeated.connect(func(amount: int, _position: Vector2) -> void:
		defeats.append(amount))
	watch_signals(_soldier)
	var interval_frames := ceili(Engine.physics_ticks_per_second / UNIT_STATS.fire_rate)
	await wait_physics_frames(2 * interval_frames + 16)
	assert_eq(defeats, [ENEMY_STATS.ammo_drop], "La baja/drop de producción se confirman una sola vez")
	assert_eq(_ammo(), UNIT_STATS.max_ammo - 3, "15salud requieren3disparos de5daño")
	assert_eq(_soldier.get("_current_morale"), UNIT_STATS.moral_per_kill)
	assert_signal_emit_count(_soldier, "moral_changed", 1, "Solo la eliminación concede moral")


func test_last_bullet_kill_awards_morale_once_and_switches_to_machete() -> void:
	_spawn_soldier(2, 1)
	var defeats: Array = []
	var enemy := _enemy_at(Vector2(150, 0), 2, UNIT_STATS.damage_per_shot)
	enemy.enemy_defeated.connect(func(amount: int, _position: Vector2) -> void:
		defeats.append(amount))
	watch_signals(_soldier)
	await wait_physics_frames(DETECTION_FRAMES)
	assert_eq(defeats, [ENEMY_STATS.ammo_drop], "Última bala y baja simultánea producen un único drop")
	assert_eq(_ammo(), 0)
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.MELEE)
	assert_eq(_soldier.get("_current_morale"), UNIT_STATS.moral_per_kill)
	assert_signal_emit_count(_soldier, "ammo_depleted", 1)
	assert_signal_emit_count(_soldier, "moral_changed", 1)
