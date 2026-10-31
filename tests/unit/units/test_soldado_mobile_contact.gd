extends GutTest
## 005/T021: contacto por cuerpos/consultas reales, nunca callbacks simulados.
const SoldierScene := preload("res://scenes/units/Soldado.tscn")
const EnemyScene := preload("res://scenes/enemies/EnemigoBase.tscn")
const LevelScene := preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
const UnitData := preload("res://resources/units/soldado_base_stats.tres")
const EnemyData := preload("res://resources/enemies/enemigo_infanteria_base.tres")
var _world: Node2D
var _soldier: Soldado
var _saved_state: int
var _saved_ammo: int
var _saved_waves: Dictionary


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	_saved_ammo = EconomyManager.collected_ammo
	_saved_waves = {}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_waves[key] = WaveManager.get(key)
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
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _defender(row := 2, health := 500, ammo := 1) -> Soldado:
	_soldier = SoldierScene.instantiate() as Soldado
	_soldier.stats = UnitData.duplicate() as UnitStats
	_soldier.stats.max_ammo = ammo
	_soldier.stats.max_health = health
	_soldier.position = Vector2(144, 144 + 96 * row)
	_soldier.set_grid_cell(Vector2i(1, row + 1))
	_world.add_child(_soldier)
	return _soldier


func _enemy(position: Vector2, row := 2, health := 500, speed := 40.0) -> Enemigo:
	var enemy := EnemyScene.instantiate() as Enemigo
	var data := EnemyData.duplicate() as EnemyStats
	data.max_health = health
	data.move_speed = speed
	data.rifle_damage = 0 # Contacto móvil con enemigo sin fusil.
	enemy.stats = data
	enemy.position = position
	_world.add_child(enemy)
	enemy.prepare_for_spawn(data, position, row, Enemigo.SpawnOrigin.INITIAL)
	return enemy


func _empty_rifle() -> void:
	_enemy(_soldier.global_position + Vector2(200, 0), _soldier.get_lane_id(),
		UnitData.damage_per_shot, 0.0)
	await wait_physics_frames(8)
	assert_eq(_soldier.get("_current_ammo"), 0, "Precondición: última bala real")


func test_two_moving_bodies_approach_stop_and_exchange_real_damage_in_each_lane(
		row = use_parameters([0, 1, 2, 3, 4])) -> void:
	_defender(row)
	await _empty_rifle()
	var home := _soldier.global_position
	var enemy := _enemy(home + Vector2(240, 0), row)
	var enemy_start := enemy.global_position
	var minimum_gap := INF
	for tick in 180:
		await wait_physics_frames(1)
		minimum_gap = minf(minimum_gap, enemy.global_position.x - _soldier.global_position.x)
	assert_gt(_soldier.global_position.x, home.x + 20.0, "El defensor también se movió realmente")
	assert_lt(enemy.global_position.x, enemy_start.x - 20.0, "El atacante mantiene su avance real")
	assert_gte(minimum_gap, 47.7, "Cuerpos48×48 no se atraviesan durante ningún tick")
	assert_lte(enemy.global_position.x - _soldier.global_position.x, 88.1,
		"El rango64 a offset32 solapa el cuerpo enemigo antes del contacto")
	assert_almost_eq(_soldier.global_position.y, home.y, 0.01)
	assert_almost_eq(enemy.global_position.y, home.y, 0.01)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.MELEE_CONTACT)
	assert_lt(_soldier.get("_current_health"), 500, "Contacto causa daño entrante real")
	assert_lt(enemy.get("_current_health"), 500, "El machete causa daño real")
	assert_eq(_soldier.get("_current_morale"), UnitData.moral_per_kill,
		"Impactos de machete no añaden moral")
	var stopped := _soldier.global_position
	await wait_physics_frames(18)
	assert_almost_eq(_soldier.global_position.x, stopped.x, 0.02, "Combate detenido, sin atravesar")


func test_machete_cooldown_and_morale_damage_survive_real_mobile_contact() -> void:
	_defender()
	await _empty_rifle()
	var enemy := _enemy(Vector2(224, 336), 2, 500, 0.0)
	var damage := roundi(UnitData.machete_base_damage + UnitData.moral_per_kill * UnitData.machete_moral_multiplier)
	await wait_physics_frames(8)
	assert_eq(enemy.get("_current_health"), 500 - damage, "Primer golpe real usa moral conservada")
	await wait_physics_frames(20)
	assert_eq(enemy.get("_current_health"), 500 - damage, "No duplica golpe antes de1/1.5s")
	await wait_physics_frames(18)
	assert_eq(enemy.get("_current_health"), 500 - 2 * damage, "Conserva cadencia machete de producción")
	assert_eq(_soldier.get("_current_morale"), UnitData.moral_per_kill)


func test_first_real_machete_hit_stops_advance_before_body_collision() -> void:
	_defender()
	await _empty_rifle()
	var home := _soldier.global_position
	var enemy := _enemy(home + Vector2(240, 0))
	for step in 150:
		await wait_physics_frames(1)
		if enemy.get("_current_health") < 500:
			break
	assert_lt(enemy.get("_current_health"), 500, "Se observa el primer impacto real de machete")
	var first_hit_position := _soldier.global_position
	var enemy_at_hit := enemy.global_position
	var gap_at_hit := enemy_at_hit.x - first_hit_position.x
	assert_gt(first_hit_position.x, home.x + 20.0, "El golpe se alcanza después de salir físicamente")
	assert_gt(gap_at_hit, 60.0, "Todavía no chocan los cuerpos48×48: detenerse no es sólo colisión")
	await wait_physics_frames(10)
	assert_lt(enemy.global_position.x, enemy_at_hit.x - 5.0,
		"Durante la observación el enemigo sigue aproximándose")
	assert_gt(enemy.global_position.x - _soldier.global_position.x, 55.0,
		"La observación completa ocurre antes del choque de los cuerpos")
	assert_almost_eq(_soldier.global_position.x, first_hit_position.x, 0.02,
		"Desde que golpea dentro del alcance deja de avanzar, aunque el enemigo siga moviéndose")
	assert_almost_eq(_soldier.global_position.y, home.y, 0.01)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.MELEE_CONTACT)


func test_externally_freed_contact_target_causes_wait_then_new_front_resumes(
		retirement = use_parameters(["damage", "queue_free"])) -> void:
	_defender()
	await _empty_rifle()
	var home := _soldier.global_position
	var enemy := _enemy(home + Vector2(240, 0))
	for step in 150:
		await wait_physics_frames(1)
		if enemy.get("_current_health") < 500:
			break
	assert_lt(enemy.get("_current_health"), 500, "El blanco recibió un golpe real antes del retiro externo")
	assert_gt(_soldier.global_position.x, home.x + 20.0, "El contacto ocurrió fuera de la trinchera")
	# La retirada ocurre en idle, como el control externo Web, no durante
	# physics_frame cuando el soldado aún podría limpiar el foco ese tick.
	await get_tree().process_frame
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.MELEE_CONTACT)
	assert_same(_soldier.get("_current_melee_target"), enemy,
		"Precondición: la consulta física adquirió este blanco real, sin inyectarlo")
	var stopped := _soldier.global_position
	var health: int = _soldier.get("_current_health")
	if retirement == "damage":
		assert_true(enemy.take_damage(9999), "La baja externa usa el contrato real sin pool")
	else:
		enemy.queue_free()
	await wait_physics_frames(3)
	assert_false(is_instance_valid(enemy), "Se ejercita un nodo realmente liberado, no sólo inactivo")
	await wait_physics_frames(12)
	assert_eq(_soldier.global_position, stopped, "Sin blanco frontal espera donde combatía")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.WAITING)
	assert_eq(_soldier.get("_current_health"), health, "No recibe daño de la referencia liberada")
	assert_eq(_soldier.get("_current_morale"), UnitData.moral_per_kill)
	var next := _enemy(stopped + Vector2(240, 0))
	await wait_physics_frames(24)
	assert_gt(_soldier.global_position.x, stopped.x + 10.0, "Un frontal nuevo reanuda el avance real")
	assert_almost_eq(_soldier.global_position.y, home.y, 0.01)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.ADVANCING)
	assert_eq(next.get("_current_health"), 500, "No arrastra el ataque anterior fuera de alcance")


func test_externally_freed_rifle_target_keeps_home_then_acquires_new_real_target(
		retirement = use_parameters(["damage", "queue_free"])) -> void:
	_defender(2, 500, 5)
	var home := _soldier.global_position
	var enemy := _enemy(home + Vector2(200, 0), 2, 500, 0.0)
	await wait_physics_frames(8)
	assert_lt(enemy.get("_current_health"), 500, "La consulta física produjo un disparo real")
	assert_gt(_soldier.get("_current_ammo"), 0, "Conserva carga para permanecer en modo fusil")
	await get_tree().process_frame
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.RIFLE)
	assert_same(_soldier.get("_current_target"), enemy,
		"Precondición: este blanco fue adquirido realmente antes de liberarlo en idle")
	var remaining: int = _soldier.get("_current_ammo")
	if retirement == "damage":
		assert_true(enemy.take_damage(9999), "Retiro externo real, sin adjudicar una baja al fusil")
	else:
		enemy.queue_free()
	await wait_physics_frames(3)
	assert_false(is_instance_valid(enemy))
	await wait_physics_frames(12)
	assert_eq(_soldier.global_position, home)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.HOME)
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.RIFLE)
	assert_eq(_soldier.get("_current_ammo"), remaining, "No dispara al blanco liberado")
	assert_eq(_soldier.get("_current_health"), 500)
	assert_eq(_soldier.get("_current_morale"), 0.0, "La retirada externa no concede moral")
	var next := _enemy(home + Vector2(200, 0), 2, 500, 0.0)
	await wait_physics_frames(48)
	assert_lt(next.get("_current_health"), 500, "Un blanco real nuevo vuelve a recibir disparos")
	assert_same(_soldier.get("_current_target"), next)
	assert_lt(_soldier.get("_current_ammo"), remaining)
	assert_eq(_soldier.global_position, home)
	assert_eq(_soldier.get("_mode"), Soldado.SoldierMode.RIFLE)


func test_enemy_contact_really_kills_the_defender_after_departure_and_reports_home_once() -> void:
	_defender(2, 10)
	await _empty_rifle()
	var deaths: Array[Vector2i] = []
	var snapshots: Array[Dictionary] = []
	_soldier.soldier_defeated.connect(func(cell: Vector2i) -> void: deaths.append(cell))
	_soldier.defeat_visual_requested.connect(func(snapshot: Dictionary) -> void: snapshots.append(snapshot))
	var enemy := _enemy(Vector2(384, 336))
	await wait_physics_frames(330)
	assert_false(is_instance_valid(_soldier), "Daño enemigo real puede derrotar al defensor móvil")
	assert_eq(deaths, [Vector2i(1, 3)], "La derrota notifica una vez la trinchera original")
	assert_eq(snapshots.size(), 1)
	if snapshots.size() == 1:
		assert_gt((snapshots[0]["world_position"] as Vector2).x, 164.0,
			"La derrota y su efecto ocurren fuera tras una salida física")
	assert_lt(enemy.get("_current_health"), 500, "Ambos combatieron antes de morir el soldado")
	assert_gt(enemy.get("_current_health"), 0)


func test_multiple_attackers_each_damage_once_per_existing_one_second_pulse() -> void:
	_defender()
	await _empty_rifle()
	# Dos cuerpos reales tangentes entre sí, ambos dentro de la fila central.
	# Velocidad0 aísla la cadencia; el acercamiento móvil se prueba arriba.
	_enemy(Vector2(214, 312), 2, 500, 0.0)
	_enemy(Vector2(214, 360), 2, 500, 0.0)
	await wait_physics_frames(8)
	assert_eq(_soldier.get("_current_health"), 500 - 2 * EnemyData.melee_damage,
		"Un pulso aplica un ataque de cada enemigo, sin duplicar Area+consulta")
	await wait_physics_frames(38)
	assert_eq(_soldier.get("_current_health"), 500 - 2 * EnemyData.melee_damage,
		"Antes de1s no hay otro ataque entrante")
	await wait_physics_frames(22)
	assert_eq(_soldier.get("_current_health"), 500 - 4 * EnemyData.melee_damage,
		"El siguiente pulso conserva1s y todos los atacantes válidos")


func test_other_lane_enemy_passes_while_contact_in_this_lane_stays_blocked() -> void:
	_defender()
	await _empty_rifle()
	var contact := _enemy(Vector2(224, 336))
	await wait_physics_frames(50)
	var other := _enemy(Vector2(260, 240), 1)
	var other_start := other.global_position
	await wait_physics_frames(90)
	assert_lt(other.global_position.x, other_start.x - 50.0, "No bloquea el carril vecino")
	assert_eq(other.get("_current_health"), 500, "Machete no afecta otra fila")
	assert_gte(contact.global_position.x - _soldier.global_position.x, 47.7)
	assert_almost_eq(_soldier.global_position.y, 336.0, 0.01)
	assert_almost_eq(other.global_position.y, 240.0, 0.01)


func test_released_pursuit_target_and_same_node_reused_in_other_lane_leave_no_old_attack() -> void:
	_defender()
	await _empty_rifle()
	var pool := ObjectPool.new()
	_world.add_child(pool)
	pool.setup(EnemyScene, 1)
	var enemy := pool.acquire() as Enemigo
	enemy.set_pool(pool)
	var data := EnemyData.duplicate() as EnemyStats
	data.max_health = 500
	enemy.prepare_for_spawn(data, Vector2(1008, 336), 2, Enemigo.SpawnOrigin.WAVE)
	var generation := enemy.activation_generation
	await wait_physics_frames(30)
	assert_gt(_soldier.global_position.x, 154.0, "El cuerpo empezó a perseguir ese uso del nodo")
	pool.release(enemy)
	await wait_physics_frames(3)
	var stopped := _soldier.global_position
	await wait_physics_frames(12)
	assert_eq(_soldier.global_position, stopped, "Un nodo inactivo ya no sostiene avance")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.WAITING)
	var reused := pool.acquire() as Enemigo
	assert_same(reused, enemy, "Se prueba la misma instancia física")
	reused.prepare_for_spawn(data, stopped + Vector2(64, 96), 3, Enemigo.SpawnOrigin.INITIAL)
	await wait_physics_frames(48)
	assert_gt(reused.activation_generation, generation)
	assert_eq(reused.get("_current_health"), 500, "Otra activación/fila no recibe intención antigua")
	assert_eq(_soldier.global_position, stopped)


func test_real_machete_kill_recycles_same_enemy_without_second_drop_or_stale_hit() -> void:
	_defender()
	await _empty_rifle()
	var pool := ObjectPool.new()
	_world.add_child(pool)
	pool.setup(EnemyScene, 1)
	var enemy := pool.acquire() as Enemigo
	enemy.set_pool(pool)
	var first := EnemyData.duplicate() as EnemyStats
	first.rifle_damage = 0
	first.max_health = roundi(UnitData.machete_base_damage + UnitData.moral_per_kill * UnitData.machete_moral_multiplier)
	var next := EnemyData.duplicate() as EnemyStats
	next.rifle_damage = 0
	next.max_health = 500
	var defeats: Array[int] = []
	enemy.enemy_defeated.connect(func(amount: int, _where: Vector2) -> void:
		defeats.append(amount)
		pool.release(enemy)
		var reused := pool.acquire() as Enemigo
		reused.prepare_for_spawn(next, _soldier.global_position + Vector2(64, 96), 3,
			Enemigo.SpawnOrigin.INITIAL))
	enemy.prepare_for_spawn(first, Vector2(384, 336), 2, Enemigo.SpawnOrigin.WAVE)
	var initial_generation := enemy.activation_generation
	await wait_physics_frames(170)
	assert_gt(_soldier.global_position.x, 164.0, "El golpe ocurre después de una salida real")
	assert_eq(defeats, [EnemyData.ammo_drop], "El machete provoca una única baja/recompensa")
	assert_gt(enemy.activation_generation, initial_generation)
	assert_eq(enemy.get("_current_health"), 500, "Reutilización síncrona no recibe un golpe viejo")
	assert_eq(_soldier.get("_current_morale"), UnitData.moral_per_kill + UnitData.machete_moral_per_kill,
		"Una baja de fusil1 y la original de machete2; reciclado no duplica crédito")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.WAITING)


func test_owner_really_leaves_origin_stays_reserved_then_death_frees_one_replacement() -> void:
	var level := LevelScene.instantiate() as Node2D
	var data := UnitData.duplicate() as UnitStats
	data.max_ammo = 1
	level.set("soldado_deploy_stats", data)
	_world.add_child(level)
	var spawner: Node = level.get("_wave_spawner")
	spawner.process_mode = Node.PROCESS_MODE_DISABLED
	var board: BoardManager = level.get("_board_manager")
	var home := Vector2i(1, 3)
	_soldier = board.get_occupant(home) as Soldado
	await _empty_rifle()
	_enemy(Vector2(1008, 336))
	await wait_physics_frames(30)
	assert_gt(_soldier.global_position.x, 154.0, "Sale físicamente antes de verificar la reserva")
	assert_same(board.get_occupant(home), _soldier)
	EconomyManager.collected_ammo = 100
	level.call("_try_deploy_soldado", home)
	assert_eq(EconomyManager.collected_ammo, 100, "Origen reservado rechaza reemplazo sin cobrar")
	assert_same(board.get_occupant(home), _soldier)
	var id := _soldier.get_instance_id()
	var defeated_cells: Array[Vector2i] = []
	_soldier.soldier_defeated.connect(func(cell: Vector2i) -> void: defeated_cells.append(cell))
	_soldier.take_damage(9999)
	assert_true(board.is_cell_free(home), "La muerte libera origen inmediatamente, sin esperar caída")
	assert_eq(defeated_cells, [home])
	level.call("_try_deploy_soldado", home)
	level.call("_try_deploy_soldado", home)
	var replacement := board.get_occupant(home) as Soldado
	assert_not_null(replacement)
	if replacement != null:
		assert_ne(replacement.get_instance_id(), id)
		assert_eq(replacement.global_position, Vector2(144, 336))
	assert_eq(EconomyManager.collected_ammo, 100 - UnitData.deploy_ammo_cost)


func test_last_wave_kill_stops_incoming_damage_in_the_same_physics_tick() -> void:
	_defender()
	var wave := WaveData.new()
	var entry := WaveSpawnEntry.new()
	entry.count = 1
	entry.enemy_stats = EnemyData
	wave.spawn_entries.assign([entry])
	WaveManager.start_waves([wave])
	var last := _enemy(Vector2(212, 312), 2, UnitData.damage_per_shot, 0.0)
	last.enemy_defeated.connect(func(_amount: int, _where: Vector2) -> void:
		WaveManager.notify_enemy_defeated())
	var uncounted := _enemy(Vector2(216, 360), 2, 500, 0.0)
	watch_signals(GameStateManager)
	await wait_physics_frames(12)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON)
	assert_signal_emit_count(GameStateManager, "game_won", 1)
	assert_eq(_soldier.get("_current_health"), 500,
		"La baja terminal cancela daño entrante del mismo tick antes de otro atacante")
	assert_eq(uncounted.get("_current_health"), 500)
	assert_eq(_soldier.global_position, Vector2(144, 336))
