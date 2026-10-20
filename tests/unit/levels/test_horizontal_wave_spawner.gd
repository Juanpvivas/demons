extends GutTest
## 005/T006: reparto horizontal y origen por activación con pool/Managers reales.
## Los timeouts controlados recorren la cola productiva sin esperar los 99
## intervalos autorados; la espera inicial tiene su comprobación temporal aparte.

const ENEMY_SCENE := preload("res://scenes/enemies/EnemigoBase.tscn")
const BOARD := preload("res://resources/levels/monte_calvo_board.tres")
const BASE_STATS := preload("res://resources/enemies/enemigo_infanteria_base.tres")
const WAVE_PATH := "res://resources/waves/nivel_montecalvo_oleada_%02d.tres"

var _spawner: WaveSpawner
var _effects: CombatVisualEffects
var _wave_before: Dictionary
var _state_before: int
var _ammo_before: int


func before_each() -> void:
	_wave_before = {}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_wave_before[key] = WaveManager.get(key)
	_state_before = GameStateManager._current_state
	_ammo_before = EconomyManager.collected_ammo
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	_effects = CombatVisualEffects.new()
	add_child_autofree(_effects)
	_effects.setup(3)
	_spawner = _new_spawner()


func after_each() -> void:
	for key: String in _wave_before:
		WaveManager.set(key, _wave_before[key])
	GameStateManager._current_state = _state_before
	EconomyManager.collected_ammo = _ammo_before


func _new_spawner() -> WaveSpawner:
	var spawner := WaveSpawner.new()
	add_child_autofree(spawner)
	spawner.setup(ENEMY_SCENE, 1, Vector2(576, 50), _effects, BOARD)
	# No se mide desplazamiento aquí: conservar la posición exacta de aparición
	# permite comprobar la asignación, sin sustituir al enemigo ni su colisión.
	for child: Node in spawner._enemy_pool.get_children():
		if child is Enemigo:
			child.set_physics_process(false)
	spawner._enemy_pool.instance_created.connect(func(node: Node): node.set_physics_process(false))
	return spawner


func _entry(count: int, interval: float = 0.25, stats: EnemyStats = BASE_STATS) -> WaveSpawnEntry:
	var entry := WaveSpawnEntry.new()
	entry.enemy_stats = stats
	entry.count = count
	entry.spawn_interval = interval
	return entry


func _wave(number: int, entries: Array[WaveSpawnEntry]) -> WaveData:
	var wave := WaveData.new()
	wave.wave_number = number
	wave.spawn_entries = entries
	return wave


func _active(spawner: WaveSpawner = null) -> Array[Enemigo]:
	if spawner == null:
		spawner = _spawner
	var enemies: Array[Enemigo] = []
	for child: Node in spawner._enemy_pool.get_children():
		if child is Enemigo and child.process_mode != Node.PROCESS_MODE_DISABLED:
			enemies.append(child)
	return enemies


func _expire_spawn_timer(spawner: WaveSpawner = null) -> void:
	if spawner == null:
		spawner = _spawner
	spawner._spawn_timer.stop()
	spawner._spawn_timer.timeout.emit()
	spawner._spawn_timer.stop()


func _activate(origin: Enemigo.SpawnOrigin, lane: int, stats: EnemyStats = BASE_STATS) -> Enemigo:
	var enemy := _spawner._enemy_pool.acquire() as Enemigo
	enemy.prepare_for_spawn(stats, BOARD.spawn_positions[lane], lane, origin)
	return enemy


func _production_waves() -> Array[WaveData]:
	var waves: Array[WaveData] = []
	for number in range(1, 11):
		waves.append(load(WAVE_PATH % number) as WaveData)
	return waves


func test_initial_enemy_is_active_at_t0_in_central_lane_and_same_pool() -> void:
	var initial := _spawner.spawn_initial_enemy(BASE_STATS)
	assert_not_null(initial, "El atacante inicial debe activarse inmediatamente, antes de cualquier timeout")
	if initial == null:
		return # Ausencia semántica ya afirmada; no desreferenciar el stub.
	assert_eq(_active(), [initial], "Exactamente un inicial activo, perteneciente al pool común")
	assert_eq(initial.lane_id, 2, "Fila central 3 de UI, índice interno 2")
	assert_eq(initial.spawn_origin, Enemigo.SpawnOrigin.INITIAL)
	assert_eq(initial.global_position, Vector2(1008, 336))
	assert_same(initial.stats, BASE_STATS)
	assert_eq(initial._current_health, BASE_STATS.max_health)
	assert_eq(initial.get_signal_connection_list("defeat_visual_requested").size(), 1)


func test_initial_activation_does_not_consume_first_wave_lane() -> void:
	var initial := _spawner.spawn_initial_enemy(BASE_STATS)
	assert_not_null(initial, "La inicial debe existir para comprobar que no consume cursor")
	WaveManager.start_waves([_wave(1, [_entry(1)])])
	assert_eq(_active().size(), 1, "Antes del primer timeout solo existe el atacante inicial")
	_expire_spawn_timer()
	var wave_enemies: Array[Enemigo] = []
	for enemy in _active():
		if enemy != initial:
			wave_enemies.append(enemy)
	assert_eq(wave_enemies.size(), 1)
	if wave_enemies.size() != 1:
		return
	assert_eq(wave_enemies[0].lane_id, 0, "El primer WAVE usa fila 1 aunque INITIAL ya esté activo")
	assert_eq(wave_enemies[0].global_position, Vector2(1008, 144))
	assert_eq(wave_enemies[0].spawn_origin, Enemigo.SpawnOrigin.WAVE)


func test_wave_lane_order_wraps_and_continues_across_entries_and_waves() -> void:
	var second_stats := BASE_STATS.duplicate() as EnemyStats
	second_stats.max_health = 21
	var first := _wave(1, [_entry(2), _entry(1, 0.45, second_stats)])
	var second := _wave(2, [_entry(4)])
	WaveManager.start_waves([first, second])
	var lanes: Array[int] = []
	var positions: Array[Vector2] = []
	var stats_seen: Array[EnemyStats] = []
	for index in 7:
		_expire_spawn_timer()
		var active := _active()
		assert_eq(active.size(), 1, "Un timeout activa solo un enemigo de la cola")
		if active.size() != 1:
			return
		var enemy := active[0]
		lanes.append(enemy.lane_id)
		positions.append(enemy.global_position)
		stats_seen.append(enemy.stats)
		assert_true(enemy.take_damage(enemy.stats.max_health))
	assert_eq(lanes, [0, 1, 2, 3, 4, 0, 1], "Primera oleada 1/2/3; segunda 4/5/1/2")
	assert_eq(positions, [Vector2(1008, 144), Vector2(1008, 240), Vector2(1008, 336),
		Vector2(1008, 432), Vector2(1008, 528), Vector2(1008, 144), Vector2(1008, 240)])
	assert_eq(stats_seen, [BASE_STATS, BASE_STATS, second_stats, BASE_STATS, BASE_STATS, BASE_STATS, BASE_STATS])


func test_new_match_spawner_starts_again_at_lane_one() -> void:
	WaveManager.start_waves([_wave(1, [_entry(2)])])
	for index in 2:
		_expire_spawn_timer()
	_spawner._spawn_timer.stop()
	# Un nivel nuevo crea otro spawner; retirar la conexión del anterior evita
	# simular dos niveles vivos escuchando el mismo singleton.
	WaveManager.wave_started.disconnect(_spawner._on_wave_started)
	var fresh := _new_spawner()
	WaveManager.start_waves([_wave(1, [_entry(1)])])
	_expire_spawn_timer(fresh)
	var active := _active(fresh)
	assert_eq(active.size(), 1)
	if active.size() == 1:
		assert_eq(active[0].lane_id, 0, "La partida nueva reinicia el reparto, sin heredar cursor")
		assert_eq(active[0].global_position, Vector2(1008, 144))


func test_first_production_wave_keeps_its_initial_delay() -> void:
	WaveManager.start_waves([load(WAVE_PATH % 1) as WaveData])
	assert_eq(_active().size(), 0, "wave_started no activa enemigos síncronamente")
	assert_almost_eq(_spawner._spawn_timer.wait_time, 1.5, 0.001)
	assert_gt(_spawner._spawn_timer.time_left, 1.0)
	await wait_seconds(0.05)
	assert_eq(_active().size(), 0, "Un intervalo parcial no adelanta la aparición")
	_spawner._spawn_timer.stop()
	_expire_spawn_timer()
	assert_eq(_active().size(), 1, "El timeout real conectado activa exactamente uno")


func test_entries_preserve_existing_timer_intervals_and_stats_order() -> void:
	var other := BASE_STATS.duplicate() as EnemyStats
	other.max_health = 21
	WaveManager.start_waves([_wave(1, [_entry(2, 0.25), _entry(2, 0.45, other)])])
	var waits: Array[float] = []
	var stats_seen: Array[EnemyStats] = []
	for index in 4:
		waits.append(_spawner._spawn_timer.wait_time)
		_expire_spawn_timer()
		var active := _active()
		assert_eq(active.size(), 1)
		if active.size() != 1:
			return
		stats_seen.append(active[0].stats)
		active[0].take_damage(active[0].stats.max_health)
	assert_eq(waits, [0.25, 0.25, 0.25, 0.45], "Se conserva interval_after autorado, también al cambiar entrada")
	assert_eq(stats_seen, [BASE_STATS, BASE_STATS, other, other])


func test_production_population_is_one_initial_plus_ninety_nine_wave_activations() -> void:
	var initial := _spawner.spawn_initial_enemy(BASE_STATS)
	assert_not_null(initial, "La población total incluye el inicial independiente de las oleadas")
	var wave_activations := 0
	var counts: Array[int] = []
	var waves := _production_waves()
	WaveManager.start_waves(waves)
	for wave in waves:
		var count := 0
		for entry in wave.spawn_entries:
			count += entry.count
		counts.append(count)
		for index in count:
			_expire_spawn_timer()
			var candidates := _active().filter(func(enemy: Enemigo): return enemy != initial)
			assert_eq(candidates.size(), 1, "Sin multiplicar una entrada por el número de carriles")
			if candidates.size() != 1:
				return
			var enemy := candidates[0] as Enemigo
			wave_activations += 1
			enemy.take_damage(enemy.stats.max_health)
	assert_eq(counts, [3, 4, 5, 6, 8, 10, 12, 14, 17, 20])
	assert_eq(wave_activations, 99)
	var initial_count := 1 if initial != null else 0
	assert_eq(wave_activations + initial_count, 100, "100 activaciones: un inicial y 99 WAVE, no 500")


func test_initial_defeat_drops_three_once_and_recycles_without_wave_credit() -> void:
	WaveManager.start_waves([_wave(1, [_entry(2)])])
	_spawner._spawn_timer.stop()
	# Activación pública del actor en el pool real: este escenario alcanza las
	# aserciones aunque spawn_initial_enemy todavía sea un stub que retorna null.
	var initial := _activate(Enemigo.SpawnOrigin.INITIAL, 2)
	watch_signals(initial)
	watch_signals(WaveManager)
	watch_signals(EconomyManager)
	assert_true(initial.take_damage(BASE_STATS.max_health))
	assert_false(initial.take_damage(1), "Una baja no se vuelve a recompensar")
	assert_eq(WaveManager._defeated_in_current_wave, 0, "Una baja INITIAL no reduce los dos WAVE pendientes")
	assert_signal_not_emitted(WaveManager, "wave_completed")
	assert_signal_emit_count(initial, "enemy_defeated", 1)
	assert_signal_emit_count(EconomyManager, "ammo_pickup_spawned", 1)
	var pickups := _spawner._enemy_pool.get_children().filter(func(node: Node): return node is AmmoPickup)
	assert_eq(pickups.size(), 1)
	if pickups.size() == 1:
		assert_eq(pickups[0].amount, 3)
		assert_eq(pickups[0].global_position, Vector2(1008, 336))
	assert_eq(_spawner._enemy_pool.in_use_count(), 0)
	assert_eq(_spawner._enemy_pool.available_count(), 1)
	assert_eq(_effects.get_active_effect_count(), 1, "Una baja INITIAL produce un solo efecto")


func test_won_requires_ninety_nine_wave_deaths_even_while_initial_remains_alive() -> void:
	var initial := _activate(Enemigo.SpawnOrigin.INITIAL, 2)
	var initial_id := initial.get_instance_id()
	WaveManager.start_waves(_production_waves())
	watch_signals(GameStateManager)
	for defeated in 99:
		_expire_spawn_timer()
		var candidates := _active().filter(func(enemy: Enemigo): return enemy != initial)
		assert_eq(candidates.size(), 1)
		if candidates.size() != 1:
			return
		var wave_enemy := candidates[0] as Enemigo
		wave_enemy.take_damage(wave_enemy.stats.max_health)
		if defeated == 97:
			assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING, "98 bajas WAVE aún no ganan")
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON)
	assert_signal_emit_count(GameStateManager, "game_won", 1)
	assert_eq(initial.get_instance_id(), initial_id)
	assert_true(initial.visible)
	assert_eq(initial._current_health, BASE_STATS.max_health, "No se exige matar al inicial para WON")
	assert_eq(_active(), [initial])


func test_same_physical_enemy_resets_initial_wave_initial_origin_lane_and_generation() -> void:
	var original: Enemigo = null
	var previous_generation := -1
	var lanes: Array[int] = [2, 0, 4]
	var origins: Array[Enemigo.SpawnOrigin] = [Enemigo.SpawnOrigin.INITIAL, Enemigo.SpawnOrigin.WAVE, Enemigo.SpawnOrigin.INITIAL]
	for cycle in 3:
		var enemy := _activate(origins[cycle], lanes[cycle])
		if original == null:
			original = enemy
		assert_same(enemy, original, "INITIAL→WAVE→INITIAL reutiliza el mismo nodo físico")
		assert_eq(enemy.spawn_origin, origins[cycle], "El origen pertenece a la activación actual")
		assert_eq(enemy.lane_id, lanes[cycle], "La fila cambia sin heredar la anterior")
		assert_gt(enemy.activation_generation, previous_generation, "Cada activación invalida generaciones anteriores")
		previous_generation = enemy.activation_generation
		assert_eq(enemy.global_position, BOARD.spawn_positions[lanes[cycle]])
		assert_eq(enemy._current_health, BASE_STATS.max_health)
		assert_eq(enemy.velocity, Vector2.ZERO, "No arrastra intención de movimiento de la activación anterior")
		var visual := enemy.get_node("AnimatedSprite2D") as EnemigoVisual
		assert_eq(visual.modulate, Color.WHITE)
		assert_true(visual.visible)
		assert_eq(enemy.get_signal_connection_list("defeat_visual_requested").size(), 1)
		enemy.velocity = Vector2(-40, 0)
		visual.modulate = Color.RED
		enemy.take_damage(1)
		_spawner._enemy_pool.release(enemy)


func test_creation_growth_and_reacquire_keep_one_visual_registration_per_enemy() -> void:
	var actors: Array[Enemigo] = []
	# Superar el prewarm fuerza el camino instance_created después de setup.
	for lane in 3:
		var enemy := _activate(Enemigo.SpawnOrigin.WAVE, lane)
		actors.append(enemy)
		assert_eq(enemy.get_signal_connection_list("defeat_visual_requested").size(), 1)
	for enemy in actors:
		_spawner._enemy_pool.release(enemy)
	for cycle in 5:
		var reused := _activate(Enemigo.SpawnOrigin.WAVE, cycle)
		assert_has(actors, reused)
		assert_eq(reused.get_signal_connection_list("defeat_visual_requested").size(), 1)
		_spawner._enemy_pool.release(reused)
	assert_eq(actors.size(), 3)


func test_defeat_keeps_original_drop_context_during_synchronous_pool_reactivation() -> void:
	WaveManager.start_waves([_wave(1, [_entry(3)])])
	_spawner._spawn_timer.stop()
	var initial := _activate(Enemigo.SpawnOrigin.INITIAL, 2)
	var next_stats := BASE_STATS.duplicate() as EnemyStats
	next_stats.ammo_drop = 7
	var drops: Array = []
	var on_drop := func(_id: int, position: Vector2, amount: int): drops.append([position, amount])
	EconomyManager.ammo_pickup_spawned.connect(on_drop)
	initial.enemy_defeated.connect(func(_ammo: int, _position: Vector2):
		var reused := _activate(Enemigo.SpawnOrigin.WAVE, 4, next_stats)
		assert_same(reused, initial, "El listener síncrono reutiliza la instancia ya liberada"))
	initial.take_damage(BASE_STATS.max_health)
	EconomyManager.ammo_pickup_spawned.disconnect(on_drop)
	assert_eq(drops, [[Vector2(1008, 336), 3]], "La baja anterior conserva fila/posición/drop aunque el nodo ya sea WAVE en fila 5")
	assert_eq(WaveManager._defeated_in_current_wave, 0, "El origen de la baja se captura antes de callbacks síncronos")
	assert_eq(initial.global_position, Vector2(1008, 528))
	assert_true(initial.visible)
	assert_eq(initial._current_health, next_stats.max_health)
