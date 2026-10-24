extends GutTest
## 010/T003: el tiro y sus consecuencias reales preceden al efecto cosmético.
const SoldierScene := preload("res://scenes/units/Soldado.tscn")
const EnemyScene := preload("res://scenes/enemies/EnemigoBase.tscn")
const EnemyDouble := preload("res://tests/unit/units/enemigo_double.gd")
var _world: Node2D
var _state_before: int
var _ammo_before: int


func before_each() -> void:
	_state_before = GameStateManager._current_state
	_ammo_before = EconomyManager.collected_ammo
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	_world = Node2D.new()
	add_child_autofree(_world)


func after_each() -> void:
	GameStateManager._current_state = _state_before
	EconomyManager.collected_ammo = _ammo_before


func _soldier(ammo := 3, at := Vector2(144, 336)) -> Soldado:
	var soldier := SoldierScene.instantiate() as Soldado
	soldier.stats = soldier.stats.duplicate()
	soldier.stats.max_ammo = ammo
	soldier.stats.fire_rate = 2.0
	soldier.position = at
	soldier.set_grid_cell(Vector2i(1, int(at.y / 96.0)))
	_world.add_child(soldier)
	return soldier


func _enemy(soldier: Soldado, offset := Vector2(150, 0), health := 100) -> EnemyDouble:
	var enemy := EnemyDouble.new()
	enemy.health = health
	enemy.position = soldier.position + offset
	_world.add_child(enemy)
	return enemy


func _shots(soldier: Soldado) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	soldier.rifle_shot_visual_requested.connect(func(snapshot: Dictionary): result.append(snapshot.duplicate(true)))
	return result


func _await_ammo(soldier: Soldado, remaining: int) -> bool:
	for frame in 45:
		if soldier.get_reload_state().ammo == remaining:
			return true
		await wait_physics_frames(1)
	return soldier.get_reload_state().ammo == remaining


func _check_snapshot(snapshot: Dictionary) -> bool:
	assert_eq(snapshot.size(), 2, "Sólo dos posiciones, sin referencia jugable")
	var valid := snapshot.size() == 2 \
		and snapshot.get("origin_world") is Vector2 and snapshot.get("target_world") is Vector2
	assert_true(valid, "Origen y destino Vector2 antes de acceder a sus claves")
	return valid


func test_real_front_and_direct_diagonal_shots_request_once_with_immediate_damage(
		offset = use_parameters([Vector2(150, 0), Vector2(380, 0), Vector2(96, -96), Vector2(96, 96)])) -> void:
	var soldier := _soldier()
	var enemy := _enemy(soldier, offset)
	var target_at := enemy.global_position
	var shots := _shots(soldier)
	var at_request: Array = []
	soldier.rifle_shot_visual_requested.connect(func(_snapshot: Dictionary):
		at_request.append([soldier.get_reload_state().ammo, enemy.damage_received.size()]))
	assert_true(await _await_ammo(soldier, 2), "Control: la física ejecutó el disparo real")
	assert_eq(enemy.damage_received, [soldier.stats.damage_per_shot], "Daño inmediato, sin esperar al trazo")
	assert_eq(soldier.get_reload_state().morale, 0.0)
	assert_eq(shots.size(), 1, "Una petición por bala consumida")
	assert_eq(at_request, [[2, 0]], "Señal después del consumo y antes de take_damage")
	if shots.size() == 1 and _check_snapshot(shots[0]):
		assert_eq(shots[0].target_world, target_at)
		var visual := soldier.get_node("AnimatedSprite2D") as SoldadoVisual
		var expected := visual.capture_rifle_shot_snapshot(target_at)
		if _check_snapshot(expected):
			assert_eq(shots[0].origin_world, expected.origin_world, "La boquilla procede del visual autorado")
		assert_gt((shots[0].origin_world as Vector2).x, soldier.global_position.x)


func test_cadence_consumption_and_damage_stay_one_to_one_with_visual_requests() -> void:
	var soldier := _soldier()
	var enemy := _enemy(soldier)
	var shots := _shots(soldier)
	assert_true(await _await_ammo(soldier, 2))
	await wait_seconds(0.12)
	assert_eq(enemy.damage_received.size(), 1, "No adelantar el segundo daño por mostrar efectos")
	assert_eq(soldier.get_reload_state().ammo, 2)
	assert_eq(shots.size(), 1)
	assert_true(await _await_ammo(soldier, 1), "La cadencia permite un segundo tiro después")
	assert_eq(enemy.damage_received, [soldier.stats.damage_per_shot, soldier.stats.damage_per_shot])
	assert_eq(shots.size(), 2, "Ni duplicados por frame ni un haz continuo")


func test_last_bullet_preserves_request_while_switching_weapon(
		lethal = use_parameters([false, true])) -> void:
	var soldier := _soldier(1)
	var health := soldier.stats.damage_per_shot if lethal else 100
	var enemy := _enemy(soldier, Vector2(150, 0), health)
	var shots := _shots(soldier)
	assert_true(await _await_ammo(soldier, 0))
	assert_eq(enemy.damage_received, [soldier.stats.damage_per_shot])
	assert_eq(soldier.get_reload_state().mode, Soldado.SoldierMode.MELEE)
	assert_eq(soldier.get_reload_state().morale, soldier.stats.moral_per_kill if lethal else 0.0)
	assert_eq(shots.size(), 1, "Cambiar a machete no borra el hecho del último tiro")
	await wait_seconds(0.08)
	assert_eq(shots.size(), 1, "Machete no inventa otro efecto de fusil")


func test_no_fictitious_rifle_request_when_rules_do_not_accept_a_shot(
		scenario = use_parameters(["no_target", "invalid_diagonal", "distant_diagonal", "no_ammo", "paused", "terminal"])) -> void:
	var soldier := _soldier(0 if scenario == "no_ammo" else 3)
	var shots := _shots(soldier)
	var enemy: EnemyDouble
	if scenario != "no_target":
		var offset := Vector2(150, 0)
		if scenario == "invalid_diagonal":
			offset = Vector2(192, -96)
		elif scenario == "distant_diagonal":
			offset = Vector2(380, -96)
		enemy = _enemy(soldier, offset)
	if scenario == "paused":
		GameStateManager._current_state = GameStateManager.GameState.PAUSED
	elif scenario == "terminal":
		GameStateManager.report_reached_defended_position()
	await wait_physics_frames(6)
	assert_true(shots.is_empty())
	assert_eq(soldier.get_reload_state().ammo, 0 if scenario == "no_ammo" else 3)
	if enemy != null:
		assert_true(enemy.damage_received.is_empty())


func test_returning_with_refilled_rifle_does_not_emit_an_extra_shot() -> void:
	var soldier := _soldier(1)
	var enemy := _enemy(soldier)
	var shots := _shots(soldier)
	assert_true(await _await_ammo(soldier, 0), "Control: agotó la carga mediante un tiro real")
	# Fixture fuera del hogar; la transición y el gasto usan la API real.
	soldier.global_position += Vector2(192, 0)
	enemy.global_position = soldier.global_position + Vector2(150, 0)
	EconomyManager.collected_ammo = soldier.stats.deploy_ammo_cost
	assert_true(soldier.request_reload())
	assert_eq(soldier.get_reload_state().movement_state, Soldado.MovementState.RETURNING)
	await wait_physics_frames(4)
	assert_eq(soldier.get_reload_state().ammo, 1)
	assert_eq(enemy.damage_received, [soldier.stats.damage_per_shot])
	assert_eq(shots.size(), 1, "El fusil recargado no dispara mientras regresa")


func test_no_visual_listener_is_needed_for_damage_ammo_or_morale() -> void:
	var soldier := _soldier(1)
	var enemy := _enemy(soldier, Vector2(150, 0), soldier.stats.damage_per_shot)
	assert_true(soldier.get_signal_connection_list("rifle_shot_visual_requested").is_empty())
	assert_true(await _await_ammo(soldier, 0))
	assert_eq(enemy.damage_received, [soldier.stats.damage_per_shot])
	assert_eq(soldier.get_reload_state().morale, soldier.stats.moral_per_kill)
	assert_eq(soldier.get_reload_state().mode, Soldado.SoldierMode.MELEE)


func test_snapshot_precedes_real_enemy_pool_release_and_synchronous_reuse() -> void:
	var soldier := _soldier(1)
	var pool := ObjectPool.new()
	_world.add_child(pool)
	pool.instance_created.connect(func(node: Node): (node as Enemigo).set_pool(pool))
	pool.setup(EnemyScene, 1)
	var enemy := pool.acquire() as Enemigo
	var first_stats := enemy.stats.duplicate() as EnemyStats
	first_stats.max_health = soldier.stats.damage_per_shot
	first_stats.move_speed = 0.0
	first_stats.ammo_drop = 0
	var target_at := soldier.global_position + Vector2(150, 0)
	enemy.prepare_for_spawn(first_stats, target_at, 2, Enemigo.SpawnOrigin.INITIAL)
	var events: Array[String] = []
	var shots: Array[Dictionary] = []
	soldier.rifle_shot_visual_requested.connect(func(snapshot: Dictionary):
		events.append("shot")
		shots.append(snapshot.duplicate(true))
		assert_true(enemy.is_targetable(), "La captura precede incluso al retiro jugable"))
	var generation := enemy.activation_generation
	enemy.enemy_defeated.connect(func(_amount: int, _position: Vector2):
		events.append("defeat")
		pool.release(enemy)
		var reused := pool.acquire() as Enemigo
		assert_same(reused, enemy, "Control: se reutilizó el mismo cuerpo")
		var next_stats := first_stats.duplicate() as EnemyStats
		next_stats.max_health = 100
		reused.prepare_for_spawn(next_stats, Vector2(900, 336), 2, Enemigo.SpawnOrigin.INITIAL))
	assert_true(await _await_ammo(soldier, 0))
	assert_eq(soldier.get_reload_state().morale, soldier.stats.moral_per_kill)
	assert_gt(enemy.activation_generation, generation, "Control: el cuerpo corresponde a otra entidad")
	assert_eq(enemy.global_position, Vector2(900, 336))
	assert_eq(events, ["shot", "defeat"], "La solicitud usa el contexto anterior al callback síncrono")
	assert_eq(shots.size(), 1)
	if shots.size() == 1 and _check_snapshot(shots[0]):
		assert_eq(shots[0].target_world, target_at)


func test_visual_snapshot_follows_authored_transform_without_mutating_pose_or_sharing_dictionary() -> void:
	var soldier := _soldier()
	var visual := soldier.get_node("AnimatedSprite2D") as SoldadoVisual
	var target_at := Vector2(350, 240)
	var before := [visual.animation, visual.frame, visual.offset, visual.scale, visual.modulate]
	var first := visual.capture_rifle_shot_snapshot(target_at)
	assert_eq([visual.animation, visual.frame, visual.offset, visual.scale, visual.modulate], before)
	if not _check_snapshot(first):
		return
	var local_anchor := visual.to_local(first.origin_world)
	visual.position += Vector2(37, -21)
	visual.rotation = 0.2
	visual.scale *= Vector2(1.4, 0.8)
	var second := visual.capture_rifle_shot_snapshot(target_at)
	if not _check_snapshot(second):
		return
	assert_almost_eq(second.origin_world, visual.to_global(local_anchor), Vector2(0.01, 0.01))
	assert_eq(second.target_world, target_at, "El destino no hereda el transform del arma")
	first.target_world = Vector2.ZERO
	assert_eq(second.target_world, target_at, "Cada snapshot es independiente por valor")


func test_visual_snapshot_reflection_preserves_the_frame_rect_center(
		is_centered = use_parameters([true, false])) -> void:
	var soldier := _soldier()
	var visual := soldier.get_node("AnimatedSprite2D") as SoldadoVisual
	visual.animation = &"rifle_shot"
	visual.frame = 0
	visual.centered = is_centered
	visual.offset = Vector2(13, -29)
	visual.position = Vector2(21, -15)
	visual.rotation = 0.27
	visual.scale = Vector2(0.6, 0.45)
	visual.flip_h = false
	visual.flip_v = false
	var target_at := Vector2(360, 240)
	var normal := visual.capture_rifle_shot_snapshot(target_at)
	if not _check_snapshot(normal):
		return
	var normal_local := visual.to_local(normal.origin_world)
	var rect_center := visual.offset
	if not visual.centered:
		var texture := visual.sprite_frames.get_frame_texture(visual.animation, visual.frame)
		rect_center += texture.get_size() * 0.5
	for axes: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		visual.flip_h = axes.x == 1
		visual.flip_v = axes.y == 1
		var reflected := visual.capture_rifle_shot_snapshot(target_at)
		if not _check_snapshot(reflected):
			continue
		var local_point := visual.to_local(reflected.origin_world)
		if visual.flip_h:
			assert_almost_eq((normal_local.x + local_point.x) * 0.5, rect_center.x, 0.001,
				"Reflejar la textura conserva el centro horizontal del rect, incluido offset")
		else:
			assert_almost_eq(local_point.x, normal_local.x, 0.001, "El eje horizontal intacto no se desplaza")
		if visual.flip_v:
			assert_almost_eq((normal_local.y + local_point.y) * 0.5, rect_center.y, 0.001,
				"Reflejar la textura conserva el centro vertical del rect, incluido offset")
		else:
			assert_almost_eq(local_point.y, normal_local.y, 0.001, "El eje vertical intacto no se desplaza")
		assert_eq(reflected.target_world, target_at)
