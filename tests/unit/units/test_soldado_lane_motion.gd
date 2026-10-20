extends GutTest
## 005/T020: movimiento observable con actores y ticks físicos reales.
## No se inyectan blancos ni se invocan callbacks de detección/ataque.
const SoldierScene := preload("res://scenes/units/Soldado.tscn")
const EnemyScene := preload("res://scenes/enemies/EnemigoBase.tscn")
const UnitData := preload("res://resources/units/soldado_base_stats.tres")
const EnemyData := preload("res://resources/enemies/enemigo_infanteria_base.tres")
var _world: Node2D
var _soldier: Soldado
var _saved_state: int
var _saved_ammo: int


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	_saved_ammo = EconomyManager.collected_ammo
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	_world = Node2D.new()
	viewport.add_child(_world)
	_soldier = null


func after_each() -> void:
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo


func _defender(row := 2, speed := 40.0) -> Soldado:
	_soldier = SoldierScene.instantiate() as Soldado
	_soldier.stats = UnitData.duplicate() as UnitStats
	_soldier.stats.max_ammo = 1
	_soldier.stats.max_health = 500
	_soldier.stats.advance_speed = speed
	_soldier.position = Vector2(144, 144 + row * 96)
	_soldier.set_grid_cell(Vector2i(1, row + 1))
	_world.add_child(_soldier)
	return _soldier


func _enemy(position: Vector2, row := 2, speed := 40.0, health := 500) -> Enemigo:
	var enemy := EnemyScene.instantiate() as Enemigo
	var data := EnemyData.duplicate() as EnemyStats
	data.max_health = health
	data.move_speed = speed
	enemy.stats = data
	enemy.position = position
	_world.add_child(enemy)
	enemy.prepare_for_spawn(data, position, row, Enemigo.SpawnOrigin.INITIAL)
	return enemy


func _empty_rifle() -> void:
	# Una eliminación real con la última bala deja al soldado sin frontal.
	_enemy(_soldier.global_position + Vector2(200, 0), _soldier.get_lane_id(), 0.0,
		UnitData.damage_per_shot)
	await wait_physics_frames(8)
	assert_eq(_soldier.get("_current_ammo"), 0, "Precondición: agotamiento mediante disparo real")
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.MELEE)


func test_last_bullet_survivor_starts_same_actor_advancing_right_in_every_lane(
		row = use_parameters([0, 1, 2, 3, 4])) -> void:
	_defender(row)
	var identity := _soldier.get_instance_id()
	var home := _soldier.global_position
	var enemy := _enemy(home + Vector2(220, 0), row)
	watch_signals(_soldier)
	await wait_physics_frames(24)
	assert_eq(_soldier.get_instance_id(), identity, "Sale el mismo actor, sin una copia")
	assert_eq(_soldier.get("_current_ammo"), 0)
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.MELEE)
	assert_signal_emit_count(_soldier, "ammo_depleted", 1)
	assert_gt(_soldier.global_position.x, home.x + 5.0, "Carga cero inicia avance físico +X")
	assert_almost_eq(_soldier.global_position.y, home.y, 0.01, "La fila no cambia")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.ADVANCING)
	assert_eq(_soldier.get_home_position(), home, "El origen no sigue al actor")
	assert_eq(enemy.get("_current_health"), 500 - UnitData.damage_per_shot,
		"Sin alcance de machete no causa daño adicional ni vuelve a disparar")


func test_last_bullet_killing_only_enemy_waits_home_with_single_reward_and_morale() -> void:
	_defender()
	var home := _soldier.global_position
	var drops: Array[int] = []
	var enemy := _enemy(home + Vector2(200, 0), 2, 0.0, UnitData.damage_per_shot)
	enemy.enemy_defeated.connect(func(amount: int, _where: Vector2) -> void: drops.append(amount))
	watch_signals(_soldier)
	await wait_physics_frames(30)
	assert_eq(_soldier.global_position, home, "Sin otro frontal no abandona la trinchera")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.HOME)
	assert_eq(_soldier.get("_current_ammo"), 0)
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.MELEE)
	assert_eq(_soldier.get("_current_morale"), UnitData.moral_per_kill)
	assert_eq(drops, [EnemyData.ammo_drop])
	assert_signal_emit_count(_soldier, "ammo_depleted", 1)
	assert_signal_emit_count(_soldier, "moral_changed", 1)


func test_after_last_bullet_kill_a_distant_front_enemy_starts_advance() -> void:
	_defender()
	await _empty_rifle()
	var home := _soldier.global_position
	var enemy := _enemy(Vector2(1008, home.y))
	await wait_physics_frames(30)
	assert_gt(_soldier.global_position.x, home.x + 10.0, "Busca frontales más allá del fusil")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.ADVANCING)
	assert_eq(enemy.get("_current_health"), 500, "Acercarse no inflige daño a distancia")


func test_enemies_behind_or_in_other_rows_do_not_trigger_departure_then_front_resumes() -> void:
	_defender()
	await _empty_rifle()
	var home := _soldier.global_position
	var behind := _enemy(home + Vector2(-96, 0), 2)
	var above := _enemy(home + Vector2(220, -96), 1)
	var below := _enemy(home + Vector2(500, 96), 3)
	await wait_physics_frames(24)
	assert_eq(_soldier.global_position, home, "No persigue detrás ni cambia de fila")
	for enemy: Enemigo in [behind, above, below]:
		assert_eq(enemy.get("_current_health"), 500, "Ninguno es blanco del machete")
	_enemy(Vector2(1008, home.y))
	await wait_physics_frames(24)
	assert_gt(_soldier.global_position.x, home.x + 5.0, "Nuevo frontal reanuda la defensa")
	assert_almost_eq(_soldier.global_position.y, home.y, 0.01)


func test_lost_front_target_waits_at_current_position_then_reacquires() -> void:
	_defender()
	await _empty_rifle()
	var target := _enemy(Vector2(1008, 336))
	await wait_physics_frames(30)
	assert_gt(_soldier.global_position.x, _soldier.get_home_position().x + 10.0)
	target.take_damage(9999)
	await wait_physics_frames(3)
	var waiting_position := _soldier.global_position
	await wait_physics_frames(24)
	assert_eq(_soldier.global_position, waiting_position, "Espera donde perdió el frontal")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.WAITING)
	_enemy(Vector2(1008, 336))
	await wait_physics_frames(24)
	assert_gt(_soldier.global_position.x, waiting_position.x + 5.0)
	assert_eq(_soldier.get_home_position(), Vector2(144, 336))


func test_advance_uses_own_40_speed_with_different_enemy_speeds(
		enemy_speed = use_parameters([20.0, 80.0])) -> void:
	_defender()
	await _empty_rifle()
	var enemy := _enemy(Vector2(1008, 336), 2, enemy_speed)
	await wait_physics_frames(8)
	var start := _soldier.global_position
	var enemy_start := enemy.global_position
	var frame := Engine.get_physics_frames()
	await wait_physics_frames(36)
	var elapsed := float(Engine.get_physics_frames() - frame) / Engine.physics_ticks_per_second
	assert_almost_eq(_soldier.global_position.x - start.x, 40.0 * elapsed, 0.75,
		"40 unidades/s del soldado, independiente del enemigo")
	assert_almost_eq(enemy_start.x - enemy.global_position.x, enemy_speed * elapsed, 1.5)
	assert_almost_eq(_soldier.global_position.y, start.y, 0.01)
	assert_eq(_soldier.get("_current_health"), 500)
	assert_eq(_soldier.get("_current_morale"), UnitData.moral_per_kill)
	assert_eq(_soldier.get("_current_ammo"), 0)
	assert_eq(_soldier.stats.advance_speed, 40.0, "No se mutan los datos compartidos")


func test_adjusting_own_advance_resource_changes_speed_without_enemy_dependency() -> void:
	_defender(2, 73.0)
	await _empty_rifle()
	_enemy(Vector2(1008, 336), 2, 20.0)
	await wait_physics_frames(8)
	var start := _soldier.global_position.x
	var frame := Engine.get_physics_frames()
	await wait_physics_frames(30)
	var elapsed := float(Engine.get_physics_frames() - frame) / Engine.physics_ticks_per_second
	assert_almost_eq(_soldier.global_position.x - start, 73.0 * elapsed, 1.3,
		"La velocidad ajustable se lee de UnitStats, sin fijarla en código")
	assert_eq(UnitData.advance_speed, 40.0)
	assert_eq(UnitData.return_speed, 40.0)


func test_terminal_cancels_advance_and_late_combat() -> void:
	_defender()
	await _empty_rifle()
	var enemy := _enemy(Vector2(1008, 336))
	await wait_physics_frames(24)
	assert_gt(_soldier.global_position.x, 149.0, "Precondición: estaba saliendo")
	GameStateManager.report_reached_defended_position()
	var final_position := _soldier.global_position
	var health: int = enemy.get("_current_health")
	await wait_physics_frames(24)
	assert_eq(_soldier.global_position, final_position)
	assert_eq(enemy.get("_current_health"), health)
	assert_eq(_soldier.get("_current_ammo"), 0)


func test_legacy_reload_outside_home_rejects_without_spend_or_rifle_until_i3() -> void:
	_defender()
	await _empty_rifle()
	# Fixture espacial explícito: la salida real tiene sus pruebas anteriores.
	# Aísla esta protección incluso mientras la locomoción aún está en RED.
	_soldier.global_position += Vector2(192, 0)
	_soldier.take_damage(7)
	EconomyManager.collected_ammo = 100
	var position_before := _soldier.global_position
	var health: int = _soldier.get("_current_health")
	var morale: float = _soldier.get("_current_morale")
	_soldier.reload()
	assert_eq(EconomyManager.collected_ammo, 100, "Recarga exterior requiere el retorno futuro de I3")
	assert_eq(_soldier.get("_current_ammo"), 0)
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.MELEE, "No dispara fusil fuera de HOME")
	assert_eq(_soldier.get("_current_health"), health)
	assert_eq(_soldier.get("_current_morale"), morale)
	assert_eq(_soldier.global_position, position_before)


func test_legacy_reload_at_home_preserves_existing_cost_and_morale() -> void:
	_defender()
	await _empty_rifle()
	EconomyManager.collected_ammo = 100
	_soldier.reload()
	assert_eq(EconomyManager.collected_ammo, 100 - UnitData.deploy_ammo_cost)
	assert_eq(_soldier.get("_current_ammo"), 1)
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.RIFLE)
	assert_eq(_soldier.get("_current_morale"), UnitData.moral_per_kill)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.HOME)
