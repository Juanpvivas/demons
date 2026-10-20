extends GutTest
## 005/T005: nivel y física reales. No sustituye la cámara, el tablero ni
## las reglas de gasto en el fixture. Los Managers compartidos se restauran.
const LevelScene := preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
const SoldierScene := preload("res://scenes/units/Soldado.tscn")
const EnemyScene := preload("res://scenes/enemies/EnemigoBase.tscn")
const Config := preload("res://resources/levels/monte_calvo_board.tres")
var _saved_ammo: int
var _saved_state: int
var _saved_waves: Dictionary
var _host: Node2D
var _level: Node2D


func before_each() -> void:
	_saved_ammo = EconomyManager.collected_ammo
	_saved_state = GameStateManager._current_state
	_saved_waves = {}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_waves[key] = WaveManager.get(key)
	EconomyManager.collected_ammo = 0
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	_host = Node2D.new()
	viewport.add_child(_host)


func after_each() -> void:
	EconomyManager.collected_ammo = _saved_ammo
	GameStateManager._current_state = _saved_state
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _load_level() -> void:
	_level = LevelScene.instantiate()
	_host.add_child(_level)
	# Aislar el tablero de la temporización de oleadas (T006 la comprueba).
	var spawner: Node = _level.get("_wave_spawner")
	spawner.process_mode = Node.PROCESS_MODE_DISABLED


func _soldiers(parent: Node) -> Array[Soldado]:
	var result: Array[Soldado] = []
	for child: Node in parent.get_children():
		if child is Soldado and not child.is_queued_for_deletion():
			result.append(child as Soldado)
		result.append_array(_soldiers(child))
	return result


func _remove_defenders() -> void:
	for soldier: Soldado in _soldiers(_level):
		soldier.take_damage(9999)
	await wait_physics_frames(2)


func _enemy_at(position: Vector2, lane: int, parent: Node, speed := 120.0) -> Enemigo:
	var enemy := EnemyScene.instantiate() as Enemigo
	enemy.stats = enemy.stats.duplicate()
	enemy.stats.move_speed = speed
	enemy.position = position
	parent.add_child(enemy)
	enemy.prepare_for_spawn(enemy.stats, position, lane, Enemigo.SpawnOrigin.WAVE)
	return enemy


func test_new_match_has_five_charged_reserved_defenders_and_zero_reserve_without_charging() -> void:
	EconomyManager.collected_ammo = 37
	_load_level()
	assert_eq(EconomyManager.collected_ammo, 0, "Partida nueva empieza en cero; dotación gratuita")
	assert_eq(_soldiers(_level).size(), 5, "Una defensa viva por cada una de las cinco trincheras")
	var board: BoardManager = _level.get("_board_manager")
	for home: Vector2i in Config.home_cells:
		var owner := board.get_occupant(home) as Soldado
		assert_not_null(owner, "Plaza inicial reservada " + str(home))
		if owner == null:
			continue
		assert_eq(owner.global_position, Vector2(home) * 96.0 + Vector2(48, 48))
		assert_eq(owner._current_ammo, owner.stats.max_ammo)
		assert_eq(owner._current_health, owner.stats.max_health)


func test_invalid_cells_and_grid_borders_reject_before_spending_or_occupying() -> void:
	_load_level()
	await _remove_defenders()
	EconomyManager.collected_ammo = 1000
	var board: BoardManager = _level.get("_board_manager")
	var invalid: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 6), Vector2i(2, 1), Vector2i(6, 5)]
	for world: Vector2 in [Vector2(95.99, 144), Vector2(192, 144), Vector2(144, 95.99), Vector2(144, 576)]:
		invalid.append(_level.call("_world_to_cell", world))
	for cell: Vector2i in invalid:
		var before_count := _soldiers(_level).size()
		var before_ammo := EconomyManager.collected_ammo
		_level.call("_try_deploy_soldado", cell)
		assert_eq(EconomyManager.collected_ammo, before_ammo, "Punto inválido no cobra " + str(cell))
		assert_eq(_soldiers(_level).size(), before_count, "Punto inválido no crea unidad")
		assert_true(board.is_cell_free(cell), "Punto inválido no ocupa tablero")


func test_first_middle_last_home_accept_replacements_at_grid_centers_once() -> void:
	_load_level()
	await _remove_defenders()
	var board: BoardManager = _level.get("_board_manager")
	var cost: int = _level.soldado_deploy_stats.deploy_ammo_cost
	EconomyManager.collected_ammo = cost * 3
	for lane in [0, 2, 4]:
		var home: Vector2i = Config.home_cells[lane]
		var before_ammo := EconomyManager.collected_ammo
		var before_count := _soldiers(_level).size()
		_level.call("_try_deploy_soldado", home)
		assert_eq(EconomyManager.collected_ammo, before_ammo - cost)
		assert_eq(_soldiers(_level).size(), before_count + 1)
		var owner := board.get_occupant(home) as Soldado
		assert_not_null(owner)
		if owner == null:
			continue
		assert_eq(owner.global_position, Vector2(144, 144 + 96 * lane))
		assert_eq(owner._current_ammo, owner.stats.max_ammo)
		_level.call("_try_deploy_soldado", home)
		assert_eq(EconomyManager.collected_ammo, before_ammo - cost, "Plaza ya reservada no cobra otra vez")
		assert_same(board.get_occupant(home), owner)


func test_insufficient_funds_leave_all_valid_free_slots_unchanged() -> void:
	_load_level()
	await _remove_defenders()
	EconomyManager.collected_ammo = 0
	var board: BoardManager = _level.get("_board_manager")
	for home: Vector2i in Config.home_cells:
		_level.call("_try_deploy_soldado", home)
		assert_true(board.is_cell_free(home))
	assert_eq(EconomyManager.collected_ammo, 0)
	assert_eq(_soldiers(_level).size(), 0)


func test_origin_stays_reserved_when_owner_is_outside_and_death_frees_only_that_origin() -> void:
	_load_level()
	var board: BoardManager = _level.get("_board_manager")
	var home: Vector2i = Config.home_cells[2]
	EconomyManager.collected_ammo = 100
	if board.is_cell_free(home):
		_level.call("_try_deploy_soldado", home)
	var owner := board.get_occupant(home) as Soldado
	assert_not_null(owner, "Precondición: dueño real en una plaza válida")
	if owner == null:
		return
	# Fixture de ubicación exterior; el desplazamiento real se prueba en T020/21.
	owner.global_position += Vector2(192, 0)
	var outside_cell: Vector2i = _level.call("_world_to_cell", owner.global_position)
	var before_ammo := EconomyManager.collected_ammo
	var before_count := _soldiers(_level).size()
	_level.call("_try_deploy_soldado", home)
	assert_eq(EconomyManager.collected_ammo, before_ammo)
	assert_eq(_soldiers(_level).size(), before_count)
	assert_same(board.get_occupant(home), owner)
	owner.take_damage(9999)
	assert_true(board.is_cell_free(home), "Muerte libera inmediatamente el origen lejano")
	assert_true(board.is_cell_free(outside_cell), "No registra la posición exterior como plaza")
	_level.call("_try_deploy_soldado", home)
	var replacement := board.get_occupant(home) as Soldado
	assert_not_null(replacement)
	if replacement != null:
		assert_ne(replacement.get_instance_id(), owner.get_instance_id())
		assert_eq(replacement.global_position, Vector2(144, 336))


func test_real_enemies_advance_left_without_vertical_drift_in_each_of_five_rows() -> void:
	var enemies: Array[Enemigo] = []
	var starts: Array[Vector2] = []
	for lane in 5:
		var start: Vector2 = Config.spawn_positions[lane]
		starts.append(start)
		enemies.append(_enemy_at(start, lane, _host, 40.0))
	await wait_physics_frames(6)
	for lane in 5:
		assert_lt(enemies[lane].global_position.x, starts[lane].x, "Avance físico −X, fila " + str(lane + 1))
		assert_almost_eq(enemies[lane].global_position.y, starts[lane].y, 0.01, "Fila constante")


func test_real_contact_blocks_one_row_without_stopping_enemies_in_other_rows() -> void:
	var soldier := SoldierScene.instantiate() as Soldado
	soldier.position = Vector2(144, 336)
	_host.add_child(soldier)
	soldier.set_grid_cell(Config.home_cells[2])
	soldier.set_physics_process(false) # Solo inmoviliza ataques; colisión permanece real.
	var blocked := _enemy_at(Vector2(192, 336), 2, _host)
	var upper := _enemy_at(Vector2(192, 144), 0, _host)
	var lower := _enemy_at(Vector2(192, 528), 4, _host)
	await wait_physics_frames(4)
	var blocked_at := blocked.global_position
	var upper_at := upper.global_position
	var lower_at := lower.global_position
	await wait_physics_frames(5)
	assert_lte(blocked.global_position.distance_to(blocked_at), 0.01, "Contacto real no atraviesa al defensor")
	assert_gt(blocked.get_slide_collision_count(), 0)
	assert_lt(upper.global_position.x, upper_at.x, "La fila superior sigue avanzando")
	assert_lt(lower.global_position.x, lower_at.x, "La fila inferior sigue avanzando")
	assert_almost_eq(upper.global_position.y, 144.0, 0.01)
	assert_almost_eq(lower.global_position.y, 528.0, 0.01)


func test_real_left_crossing_in_every_row_reports_lost_once() -> void:
	_load_level()
	await _remove_defenders()
	for node: Node in get_tree().get_nodes_in_group(Enemigo.ENEMY_GROUP):
		if _level.is_ancestor_of(node):
			node.set_physics_process(false)
	watch_signals(GameStateManager)
	for lane in 5:
		GameStateManager._current_state = GameStateManager.GameState.PLAYING
		var enemy := _enemy_at(Vector2(144, 144 + 96 * lane), lane, _level)
		var signals_before: int = get_signal_emit_count(GameStateManager, "game_lost")
		# 24 ticks: 48px a120/s; el borde del cuerpo debe entrar en zona x48..96.
		await wait_physics_frames(24)
		assert_eq(GameStateManager._current_state, GameStateManager.GameState.LOST, "Cruce físico izquierdo fila " + str(lane + 1))
		assert_signal_emit_count(GameStateManager, "game_lost", signals_before + 1)
		if GameStateManager._current_state == GameStateManager.GameState.LOST:
			GameStateManager.report_reached_defended_position()
			assert_signal_emit_count(GameStateManager, "game_lost", signals_before + 1, "Terminal no duplica derrota")
		enemy.take_damage(9999)
		await wait_physics_frames(2)


func test_terminal_rejects_late_deployment_without_cost_or_occupancy() -> void:
	_load_level()
	await _remove_defenders()
	var board: BoardManager = _level.get("_board_manager")
	EconomyManager.collected_ammo = 100
	for terminal in [GameStateManager.GameState.WON, GameStateManager.GameState.LOST]:
		GameStateManager._current_state = terminal
		var home: Vector2i = Config.home_cells[terminal - GameStateManager.GameState.WON]
		var before_count := _soldiers(_level).size()
		var before_ammo := EconomyManager.collected_ammo
		_level.call("_try_deploy_soldado", home)
		assert_eq(EconomyManager.collected_ammo, before_ammo, "Terminal no cobra")
		assert_eq(_soldiers(_level).size(), before_count)
		assert_true(board.is_cell_free(home))


func _assert_no_combat_after_terminal(terminal: int) -> void:
	var soldier := SoldierScene.instantiate() as Soldado
	soldier.position = Vector2(144, 336)
	_host.add_child(soldier)
	soldier.set_grid_cell(Config.home_cells[2])
	# Un blanco de control para el eje anterior y otro para el nuevo. Así
	# la aserción de detención no depende de que ya se haya orientado el fusil.
	var right := _enemy_at(Vector2(336, 336), 2, _host)
	var above := _enemy_at(Vector2(144, 144), 0, _host)
	for enemy: Enemigo in [right, above]:
		enemy.stats.max_health = 500
		enemy.prepare_for_spawn(enemy.stats, enemy.global_position, enemy.lane_id)
		enemy.set_physics_process(false) # Fijar blancos; soldado sí procesa.
	await wait_physics_frames(3)
	assert_lt(soldier._current_ammo, soldier.stats.max_ammo, "Control: combate real activo antes del terminal")
	var ammo := soldier._current_ammo
	var right_health := right._current_health
	var above_health := above._current_health
	GameStateManager._current_state = terminal
	# 45 ticks superan el cooldown de fusil1/1.5s sin modificar su cadencia.
	await wait_physics_frames(45)
	assert_eq(soldier._current_ammo, ammo, "Terminal no consume más disparos")
	assert_eq(right._current_health, right_health, "Terminal no aplica más daño")
	assert_eq(above._current_health, above_health)


func test_won_stops_real_combat_without_waiting_for_attack_animation() -> void:
	await _assert_no_combat_after_terminal(GameStateManager.GameState.WON)


func test_lost_stops_real_combat_without_waiting_for_attack_animation() -> void:
	await _assert_no_combat_after_terminal(GameStateManager.GameState.LOST)


func _one_wave_fixture() -> Array[WaveData]:
	var entry := WaveSpawnEntry.new()
	entry.enemy_stats = load("res://resources/enemies/enemigo_infanteria_base.tres")
	entry.count = 1
	entry.spawn_interval = 0.05
	var wave := WaveData.new()
	wave.wave_number = 1
	wave.spawn_entries = [entry]
	return [wave]


func _active_wave_enemies(spawner: WaveSpawner) -> Array:
	return spawner._enemy_pool.get_children().filter(func(node: Node):
		return node is Enemigo and node.is_targetable() and node.spawn_origin == Enemigo.SpawnOrigin.WAVE)


func _assert_new_match_clears_a_real_terminal(terminal: int) -> void:
	watch_signals(GameStateManager)
	_level = LevelScene.instantiate()
	_level.waves = _one_wave_fixture()
	_host.add_child(_level)
	if terminal == GameStateManager.GameState.WON:
		var first_spawner: WaveSpawner = _level.get("_wave_spawner")
		await wait_until(func(): return not _active_wave_enemies(first_spawner).is_empty(), 0.5)
		var waves := _active_wave_enemies(first_spawner)
		assert_eq(waves.size(), 1, "Control: una oleada real activa su enemigo")
		if waves.size() != 1:
			return
		(waves[0] as Enemigo).take_damage(9999)
	else:
		(_level.get("_wave_spawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
		var board: BoardManager = _level.get("_board_manager")
		var owner := board.get_occupant(Config.home_cells[0]) as Soldado
		assert_not_null(owner)
		if owner == null:
			return
		owner.take_damage(9999)
		_enemy_at(Vector2(144, 144), 0, _level)
		await wait_physics_frames(24)
	assert_eq(GameStateManager._current_state, terminal, "Control: terminal por combate/Managers/física reales")
	var won_before: int = get_signal_emit_count(GameStateManager, "game_won")
	var lost_before: int = get_signal_emit_count(GameStateManager, "game_lost")
	var previous := _level
	previous.queue_free() # Acción bajo prueba: descargar la partida terminada.
	await wait_physics_frames(2)
	assert_false(is_instance_valid(previous), "La partida anterior sí se retiró")
	EconomyManager.collected_ammo = 31
	# No reset de GameStateManager desde el fixture entre las dos partidas.
	_level = LevelScene.instantiate()
	_level.waves = _one_wave_fixture()
	_host.add_child(_level)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING, "Una nueva partida no hereda WON/LOST")
	assert_eq(EconomyManager.collected_ammo, 0)
	assert_eq(_soldiers(_level).size(), 5)
	for soldier: Soldado in _soldiers(_level):
		assert_eq(soldier._current_ammo, soldier.stats.max_ammo)
	var spawner: WaveSpawner = _level.get("_wave_spawner")
	var initials := spawner._enemy_pool.get_children().filter(func(node: Node):
		return node is Enemigo and node.is_targetable() and node.spawn_origin == Enemigo.SpawnOrigin.INITIAL)
	assert_eq(initials.size(), 1, "La nueva partida activa su inicial t0")
	if initials.size() == 1:
		assert_eq(initials[0].lane_id, 2)
		assert_eq(initials[0].global_position, Vector2(1008, 336))
	await wait_until(func(): return not _active_wave_enemies(spawner).is_empty(), 0.5)
	var wave_enemies := _active_wave_enemies(spawner)
	assert_eq(wave_enemies.size(), 1, "La nueva oleada sigue activa tras reiniciar")
	if wave_enemies.size() == 1:
		assert_eq(wave_enemies[0].lane_id, 0, "El primer WAVE vuelve a fila1")
	assert_signal_emit_count(GameStateManager, "game_won", won_before, "Sin victoria tardía heredada")
	assert_signal_emit_count(GameStateManager, "game_lost", lost_before, "Sin derrota tardía heredada")


func test_new_match_after_real_won_resets_state_initial_and_wave_cursor() -> void:
	await _assert_new_match_clears_a_real_terminal(GameStateManager.GameState.WON)


func test_new_match_after_real_lost_resets_state_initial_and_wave_cursor() -> void:
	await _assert_new_match_clears_a_real_terminal(GameStateManager.GameState.LOST)
