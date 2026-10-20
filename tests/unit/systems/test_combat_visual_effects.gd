extends GutTest
## 004/T006: derrota observacional y pool, sin esperar ni escribir gameplay.
const Fixtures := preload("res://tests/unit/units/visual_test_fixtures.gd")
const Visual := preload("res://scenes/units/soldado_visual.gd")
const Service := preload("res://scenes/visuals/combat_visual_effects.gd")
const EffectScene := preload("res://scenes/visuals/DeathVisualEffect.tscn")
const EnemyDouble := preload("res://tests/unit/units/enemigo_double.gd")
const EnemyVisual := preload("res://scenes/enemies/enemigo_visual.gd")
var _wave_before: Dictionary
var _state_before: int
var _ammo_before: int

func before_each() -> void:
	_wave_before = {}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_wave_before[key] = WaveManager.get(key)
	_state_before = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	_ammo_before = EconomyManager.collected_ammo

func after_each() -> void:
	for key: String in _wave_before: WaveManager.set(key, _wave_before[key])
	GameStateManager._current_state = _state_before
	EconomyManager.collected_ammo = _ammo_before

func _soldier() -> Soldado:
	var soldier: Soldado = load("res://scenes/units/Soldado.tscn").instantiate()
	var visual: AnimatedSprite2D = soldier.get_node("AnimatedSprite2D")
	visual.set_script(Visual)
	visual.sprite_frames = Fixtures.frames()
	visual.scale = Vector2.ONE
	visual.offset = Vector2.ZERO
	visual.flip_h = false
	visual.flip_v = false
	soldier.position = Vector2(144, 240)
	soldier.set_grid_cell(Vector2i(1, 2))
	return add_child_autofree(soldier)

func _service(size := 2) -> CombatVisualEffects:
	var service := Service.new()
	add_child_autofree(service)
	service.setup(size)
	return service

func _effect() -> DeathVisualEffect:
	return add_child_autofree(EffectScene.instantiate())

func _effects_below(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is DeathVisualEffect: result.append(child)
		result.append_array(_effects_below(child))
	return result

func test_snapshot_is_neutral_by_value_and_has_no_gameplay_references() -> void:
	var visual := Visual.new()
	visual.sprite_frames = Fixtures.frames()
	visual.offset = Vector2(0, -2)
	visual.flip_h = true
	visual.z_index = 2
	add_child_autofree(visual)
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	visual.play_confirmed_hit()
	visual.play_confirmed_morale()
	await wait_seconds(0.04)
	var snapshot: Dictionary = visual.capture_defeat_snapshot(Vector2(320, 240))
	var expected := Fixtures.snapshot()
	assert_eq(snapshot.size(), expected.size(), "Snapshot completo y sin estado de gameplay")
	for key: String in expected:
		assert_has(snapshot, key)
	if snapshot.size() != expected.size(): return
	assert_eq(snapshot["world_position"], Vector2(320, 240))
	assert_eq(snapshot["visual_scale"], Vector2.ONE, "No congela el pulso de moral")
	assert_eq(snapshot["visual_offset"], Vector2(0, -2))
	assert_eq(snapshot["sprite_frames"], visual.sprite_frames, "Frames compartidos solo lectura")
	assert_eq(snapshot["defeat_animation"], &"defeat")
	assert_true(snapshot["flip_h"])
	assert_false(snapshot["flip_v"])
	assert_eq(snapshot["visual_z"], 2)
	for value in snapshot.values():
		assert_false(value is Node or value is Callable, "Sin actor/callback jugable en snapshot")
	var second: Dictionary = visual.capture_defeat_snapshot(Vector2(640, 480))
	snapshot["world_position"] = Vector2.ZERO
	assert_eq(second["world_position"], Vector2(640, 480), "No se comparte diccionario mutable entre activaciones")

func test_real_defeat_requests_one_snapshot_before_immediate_gameplay_retirement() -> void:
	var soldier := _soldier()
	var events: Array = []
	var snapshots: Array = []
	soldier.defeat_visual_requested.connect(func(snapshot: Dictionary):
		events.append("visual")
		snapshots.append(snapshot))
	soldier.soldier_defeated.connect(func(_cell: Vector2i): events.append("gameplay"))
	soldier.take_damage(soldier.stats.max_health)
	soldier.take_damage(1)
	assert_eq(events, ["visual", "gameplay"], "Una petición por muerte, antes del retiro")
	assert_true(soldier.is_queued_for_deletion(), "La muerte no espera0.40s de animación")
	if snapshots.is_empty(): return
	assert_eq(snapshots[0]["world_position"], Vector2(144, 240))
	assert_eq(snapshots[0]["visual_scale"], Vector2.ONE)

func test_death_without_any_visual_listener_still_retires_soldier_and_clears_morale() -> void:
	var soldier := _soldier()
	var cells: Array = []
	soldier.set_grid_cell(Vector2i(1, 2))
	var enemy := EnemyDouble.new()
	enemy.health = soldier.stats.damage_per_shot
	enemy.position = soldier.position + Vector2(150, 0)
	add_child_autofree(enemy)
	await wait_until(func(): return soldier._current_morale > 0.0, 0.50)
	assert_eq(soldier._current_morale, 1.0)
	soldier.soldier_defeated.connect(func(cell: Vector2i): cells.append(cell))
	assert_true(soldier.take_damage(soldier.stats.max_health))
	assert_eq(cells, [Vector2i(1, 2)])
	assert_eq(soldier._current_morale, 0.0)
	assert_true(soldier.is_queued_for_deletion())

func test_level_frees_real_cell_immediately_without_waiting_for_visual_effect() -> void:
	var level: Node = load("res://scenes/levels/Nivel_MonteCalvo.tscn").instantiate()
	add_child_autofree(level)
	var soldier: Soldado = level.get_node("Soldado")
	var cell: Vector2i = level._world_to_cell(soldier.global_position)
	soldier.take_damage(soldier.stats.max_health)
	assert_true(level._board_manager.is_cell_free(cell))
	assert_true(soldier.is_queued_for_deletion())
	var services := level.get_children().filter(func(node): return node is CombatVisualEffects)
	assert_eq(services.size(), 1, "El nivel posee el servicio para iniciales y nuevos")
	if services.is_empty(): return
	assert_eq(services[0].get_active_effect_count(), 1)

func test_registering_actor_twice_still_produces_only_one_pooled_effect() -> void:
	var service := _service()
	var soldier := _soldier()
	service.register_actor(soldier)
	service.register_actor(soldier)
	soldier.take_damage(soldier.stats.max_health)
	assert_eq(service.get_active_effect_count(), 1)
	assert_eq(service.get_available_effect_count(), 1)
	assert_true(soldier.is_queued_for_deletion())

func test_service_recycles_effect_after_four_tenths_without_new_instance_per_death() -> void:
	var service := _service(1)
	assert_eq(service.get_available_effect_count(), 1)
	var nodes_before := _effects_below(service)
	service.request_defeat(Fixtures.snapshot())
	assert_eq(service.get_active_effect_count(), 1)
	await wait_seconds(0.30)
	assert_eq(service.get_active_effect_count(), 1, "Derrota no termina antesde0.40s")
	await wait_seconds(0.15)
	assert_eq(service.get_active_effect_count(), 0)
	assert_eq(service.get_available_effect_count(), 1)
	var nodes_after := _effects_below(service)
	assert_eq(nodes_before.size(), 1)
	assert_eq(nodes_after, nodes_before, "Misma instancia después del reciclado")

func test_effect_uses_fixed_snapshot_and_is_independent_of_source_changes() -> void:
	var effect := _effect()
	var snapshot := Fixtures.snapshot()
	effect.on_pool_acquired()
	effect.play_snapshot(snapshot)
	snapshot["world_position"] = Vector2(999, 999)
	assert_eq(effect.global_position, Vector2(320, 240))
	assert_eq(effect.get_node("AnimatedSprite2D").animation, &"defeat")
	assert_false(effect.is_in_group("enemies"))
	assert_true(effect.find_children("*", "CollisionObject2D", true, false).is_empty())
	assert_false(effect.is_processing_input())
	assert_false(effect.is_processing_unhandled_input())

func test_effect_completion_is_once_and_only_after_four_tenths() -> void:
	var effect := _effect()
	watch_signals(effect)
	effect.on_pool_acquired()
	effect.play_snapshot(Fixtures.snapshot())
	await wait_seconds(0.30)
	assert_signal_not_emitted(effect, "finished")
	await wait_seconds(0.15)
	assert_signal_emit_count(effect, "finished", 1)

func test_ten_reacquires_reset_every_visual_property_and_ignore_previous_callback() -> void:
	var pool := ObjectPool.new(EffectScene, 1)
	add_child_autofree(pool)
	var original: Node = null
	for cycle in 10:
		var effect := pool.acquire() as DeathVisualEffect
		if original == null: original = effect
		assert_same(effect, original, "Diez ciclos reutilizan la misma instancia")
		effect.play_snapshot(Fixtures.snapshot(Vector2(cycle * 10, 20)))
		var activation := effect.get_activation_id()
		var sprite: AnimatedSprite2D = effect.get_node("AnimatedSprite2D")
		assert_eq(sprite.frame, 0)
		assert_eq(sprite.frame_progress, 0.0)
		assert_true(sprite.is_playing())
		assert_true(sprite.visible)
		assert_true(effect.visible)
		assert_eq(sprite.modulate, Color.WHITE)
		assert_eq(sprite.scale, Vector2.ONE)
		assert_eq(sprite.offset, Vector2(0, -2))
		assert_false(sprite.flip_h)
		assert_false(sprite.flip_v)
		sprite.modulate = Color.RED
		sprite.scale = Vector2(2, 2)
		sprite.offset = Vector2(9, 9)
		sprite.flip_h = true
		sprite.flip_v = true
		sprite.visible = false
		if sprite.sprite_frames != null: sprite.set_frame_and_progress(2, 0.75)
		pool.release(effect)
		var reused := pool.acquire() as DeathVisualEffect
		reused.play_snapshot(Fixtures.snapshot(Vector2(100, 200)))
		watch_signals(reused)
		reused.complete_activation(activation)
		assert_gt(reused.get_activation_id(), activation)
		assert_signal_not_emitted(reused, "finished", "Callback previo no finaliza la nueva aparición")
		assert_eq(reused.global_position, Vector2(100, 200))
		assert_eq(reused.get_node("AnimatedSprite2D").modulate, Color.WHITE)
		pool.release(reused)

func test_two_effects_keep_position_progress_and_completion_independent() -> void:
	var first := _effect()
	var second := _effect()
	first.on_pool_acquired()
	first.play_snapshot(Fixtures.snapshot(Vector2(10, 20)))
	await wait_seconds(0.22)
	second.on_pool_acquired()
	second.play_snapshot(Fixtures.snapshot(Vector2(30, 40)))
	watch_signals(first)
	watch_signals(second)
	await wait_seconds(0.23)
	assert_signal_emitted(first, "finished")
	assert_signal_not_emitted(second, "finished")
	assert_eq(first.global_position, Vector2(10, 20))
	assert_eq(second.global_position, Vector2(30, 40))

func test_newly_deployed_soldier_is_registered_for_one_effect_and_immediate_cell_release() -> void:
	var level: Node = load("res://scenes/levels/Nivel_MonteCalvo.tscn").instantiate()
	add_child_autofree(level)
	EconomyManager.add_ammo(20)
	var cell := Vector2i(1, 5)
	var previous := level._board_manager.get_occupant(cell) as Soldado
	# Aislar el efecto de la unidad nueva sin eliminar reglas de ocupación.
	for connection: Dictionary in previous.get_signal_connection_list("defeat_visual_requested"):
		previous.disconnect("defeat_visual_requested", connection["callable"])
	previous.take_damage(previous.stats.max_health)
	level._try_deploy_soldado(cell)
	var soldier := level._board_manager.get_occupant(cell) as Soldado
	assert_not_null(soldier, "Ruta de despliegue real produce un soldado nuevo")
	if soldier == null: return
	soldier.take_damage(soldier.stats.max_health)
	assert_true(level._board_manager.is_cell_free(cell))
	assert_true(soldier.is_queued_for_deletion())
	var services := level.get_children().filter(func(node): return node is CombatVisualEffects)
	assert_eq(services.size(), 1)
	if services.is_empty(): return
	assert_eq(services[0].get_active_effect_count(), 1, "Registro único del soldado desplegado, sin registro manual en fixture")

func _enemy_pool() -> ObjectPool:
	var source: Enemigo = load("res://scenes/enemies/EnemigoBase.tscn").instantiate()
	var visual: AnimatedSprite2D = source.get_node("AnimatedSprite2D")
	visual.set_script(EnemyVisual)
	visual.sprite_frames = Fixtures.frames()
	for pose: StringName in [&"advance", &"contact"]:
		visual.sprite_frames.add_animation(pose)
		visual.sprite_frames.add_frame(pose, visual.sprite_frames.get_frame_texture(&"defeat", 0))
	visual.scale = Vector2(0.8, 0.75)
	visual.offset = Vector2(0, -3)
	var packed := PackedScene.new()
	assert_eq(packed.pack(source), OK)
	autofree(source)
	var pool := ObjectPool.new()
	add_child_autofree(pool)
	pool.instance_created.connect(func(node: Node): (node as Enemigo).set_pool(pool))
	pool.setup(packed, 1)
	return pool

func test_enemy_snapshot_precedes_synchronous_release_and_preserves_drop_and_kill_order() -> void:
	var pool := _enemy_pool()
	var enemy := pool.acquire() as Enemigo
	var death_at := Vector2(320, 240)
	enemy.prepare_for_spawn(enemy.stats, death_at)
	var events: Array = []
	var snapshots: Array = []
	var drop_listener := func(_id: int, position: Vector2, amount: int):
		events.append("drop")
		assert_eq(position, death_at)
		assert_eq(amount, enemy.stats.ammo_drop)
	EconomyManager.ammo_pickup_spawned.connect(drop_listener)
	enemy.defeat_visual_requested.connect(func(snapshot: Dictionary):
		events.append("visual")
		snapshots.append(snapshot)
		assert_eq(pool.in_use_count(), 1, "Snapshot ocurre antes del release síncrono"))
	enemy.enemy_defeated.connect(func(_ammo: int, _position: Vector2):
		events.append("gameplay")
		pool.release(enemy)
		events.append("released"))
	assert_true(enemy.take_damage(enemy.stats.max_health))
	assert_false(enemy.take_damage(1))
	EconomyManager.ammo_pickup_spawned.disconnect(drop_listener)
	assert_eq(events, ["visual", "gameplay", "released", "drop"])
	assert_eq(pool.in_use_count(), 0, "Muerte jugable no espera la caída")
	assert_eq(pool.available_count(), 1)
	assert_eq(snapshots.size(), 1)
	if snapshots.is_empty(): return
	var snapshot: Dictionary = snapshots[0]
	assert_eq(snapshot.size(), Fixtures.snapshot().size())
	assert_eq(snapshot.get("world_position"), death_at)
	assert_eq(snapshot.get("visual_scale"), Vector2(0.8, 0.75))
	assert_eq(snapshot.get("visual_offset"), Vector2(0, -3))
	for value in snapshot.values(): assert_false(value is Node or value is Callable)

func test_enemy_without_visual_listener_still_drops_credits_wave_and_releases_once() -> void:
	var level: Node = load("res://scenes/levels/Nivel_MonteCalvo.tscn").instantiate()
	add_child_autofree(level)
	var pool: ObjectPool = level._wave_spawner._enemy_pool
	var active_before := pool.in_use_count()
	var enemy := pool.acquire() as Enemigo
	enemy.prepare_for_spawn(enemy.stats, Vector2(600, 200))
	for connection: Dictionary in enemy.get_signal_connection_list("defeat_visual_requested"):
		enemy.disconnect("defeat_visual_requested", connection["callable"])
	var before: int = WaveManager._defeated_in_current_wave
	watch_signals(enemy)
	watch_signals(EconomyManager)
	assert_true(enemy.take_damage(enemy.stats.max_health))
	assert_false(enemy.take_damage(1))
	assert_eq(WaveManager._defeated_in_current_wave, before + 1)
	assert_eq(pool.in_use_count(), active_before, "El inicial independiente sigue en uso")
	assert_signal_emit_count(enemy, "enemy_defeated", 1)
	assert_signal_emit_count(EconomyManager, "ammo_pickup_spawned", 1)
	assert_false(enemy.visible)

func test_level_registers_initial_enemy_and_each_new_physical_pool_instance_once() -> void:
	var level: Node = load("res://scenes/levels/Nivel_MonteCalvo.tscn").instantiate()
	add_child_autofree(level)
	var initials: Array = level._wave_spawner._enemy_pool._in_use.filter(func(node: Node): return node is Enemigo and node.spawn_origin == Enemigo.SpawnOrigin.INITIAL)
	assert_eq(initials.size(), 1)
	if initials.size() != 1: return
	var initial := initials[0] as Enemigo
	var service: CombatVisualEffects = level._combat_visual_effects
	assert_eq(initial.get_signal_connection_list("defeat_visual_requested").size(), 1, "Registro del enemigo inicial")
	initial.take_damage(initial.stats.max_health)
	assert_eq(service.get_active_effect_count(), 1)
	var pool: ObjectPool = level._wave_spawner._enemy_pool
	var enemies: Array[Enemigo] = []
	# Una instancia extra fuerza creación física después del precalentamiento.
	for index in pool.available_count() + 1:
		var enemy := pool.acquire() as Enemigo
		enemy.prepare_for_spawn(enemy.stats, Vector2(600 + index * 100, 100))
		enemies.append(enemy)
		assert_eq(enemy.get_signal_connection_list("defeat_visual_requested").size(), 1)
	var reused := enemies[0]
	pool.release(reused)
	assert_same(pool.acquire(), reused)
	reused.prepare_for_spawn(reused.stats, Vector2(600, 100))
	assert_eq(reused.get_signal_connection_list("defeat_visual_requested").size(), 1, "Acquire no duplica registro")
	await wait_physics_frames(3)
	assert_eq(reused.get_signal_connection_list("defeat_visual_requested").size(), 1, "Física no duplica registro")
	reused.take_damage(reused.stats.max_health)
	assert_eq(service.get_active_effect_count(), 2, "Una derrota produce exactamente un efecto")

func test_reused_enemy_cannot_move_old_effect_or_complete_new_effect_with_stale_callback() -> void:
	var service := _service(1)
	var pool := _enemy_pool()
	var enemy := pool.acquire() as Enemigo
	enemy.prepare_for_spawn(enemy.stats, Vector2(100, 200))
	service.register_actor(enemy)
	enemy.enemy_defeated.connect(func(_ammo: int, _position: Vector2): pool.release(enemy))
	enemy.take_damage(enemy.stats.max_health)
	assert_eq(service.get_active_effect_count(), 1)
	if service.get_active_effect_count() != 1: return
	var effect := _effects_below(service)[0] as DeathVisualEffect
	var old_activation := effect.get_activation_id()
	var reused := pool.acquire() as Enemigo
	reused.prepare_for_spawn(reused.stats, Vector2(900, 100))
	assert_eq(effect.global_position, Vector2(100, 200), "Caída permanece en su snapshot")
	assert_true(reused.visible)
	effect.complete_activation(old_activation)
	reused.take_damage(reused.stats.max_health)
	assert_eq(service.get_active_effect_count(), 1)
	assert_same(_effects_below(service)[0], effect, "Recicla efecto sin crear otro")
	effect.complete_activation(old_activation)
	assert_eq(service.get_active_effect_count(), 1, "Callback viejo no libera nueva caída")
	assert_eq(effect.global_position, Vector2(900, 100))
