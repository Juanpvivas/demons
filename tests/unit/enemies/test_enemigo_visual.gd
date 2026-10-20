extends GutTest
## 004/T015: presentación observacional sobre física y combate reales.
const EnemyScene := preload("res://scenes/enemies/EnemigoBase.tscn")
const Visual := preload("res://scenes/enemies/enemigo_visual.gd")
var _saved_state: int

func before_each() -> void:
	_saved_state = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING

func after_each() -> void:
	GameStateManager._current_state = _saved_state

func _frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var texture := GradientTexture2D.new()
	for pose: StringName in [&"advance", &"contact", &"defeat"]:
		frames.add_animation(pose)
		frames.set_animation_speed(pose, 10.0 if pose == &"defeat" else 4.0 / 0.60)
		frames.set_animation_loop(pose, pose != &"defeat")
		for index in 4: frames.add_frame(pose, texture)
	return frames

func _configured_enemy() -> Enemigo:
	var enemy := EnemyScene.instantiate() as Enemigo
	enemy.stats = enemy.stats.duplicate()
	enemy.stats.max_health = 500
	enemy.stats.move_speed = 120.0
	var visual := enemy.get_node("AnimatedSprite2D") as AnimatedSprite2D
	# Fixture de arte e interfaz T003; no conecta hechos ni implementa el actor.
	visual.set_script(Visual)
	visual.sprite_frames = _frames()
	visual.scale = Vector2(0.75, 0.80)
	visual.offset = Vector2(0, -3)
	return enemy

func _enemy(position := Vector2(336, 336)) -> Enemigo:
	var enemy := _configured_enemy()
	enemy.position = position
	return add_child_autofree(enemy)

func _soldier() -> Soldado:
	var soldier: Soldado = load("res://scenes/units/Soldado.tscn").instantiate()
	soldier.position = Vector2(144, 336)
	soldier.set_grid_cell(Vector2i(1, 3))
	add_child_autofree(soldier)
	soldier.set_physics_process(false)
	return soldier

func _pool() -> ObjectPool:
	var source := _configured_enemy()
	var packed := PackedScene.new()
	assert_eq(packed.pack(source), OK)
	autofree(source)
	var pool := ObjectPool.new()
	add_child_autofree(pool)
	pool.instance_created.connect(func(node: Node):
		var enemy := node as Enemigo
		enemy.set_pool(pool)
		enemy.enemy_defeated.connect(func(_ammo: int, _position: Vector2): pool.release(enemy)))
	pool.setup(packed, 1)
	return pool

func test_real_post_physics_displacement_drives_advance() -> void:
	var enemy := _enemy()
	var before := enemy.global_position
	await wait_physics_frames(3)
	assert_gt(enemy.global_position.distance_to(before), 0.01, "Precondición: movimiento real, no velocidad deseada")
	assert_eq(enemy.get_node("AnimatedSprite2D").animation, &"advance")
	assert_eq(enemy.stats.move_speed, 120.0)

func test_real_soldier_blocks_enemy_and_stops_advance_despite_desired_velocity() -> void:
	_soldier()
	var enemy := _enemy(Vector2(194, 336))
	await wait_physics_frames(12)
	var blocked_at := enemy.global_position
	await wait_physics_frames(3)
	assert_lte(enemy.global_position.distance_to(blocked_at), 0.01, "Soldado real bloquea el CharacterBody2D")
	assert_gt(enemy.get_slide_collision_count(), 0)
	assert_eq(enemy.get_node("AnimatedSprite2D").animation, &"contact", "−X deseada no acredita avance si la física lo detuvo")

func test_movement_threshold_uses_actual_world_displacement() -> void:
	var visual := Visual.new()
	visual.sprite_frames = _frames()
	add_child_autofree(visual)
	visual.reset_visual()
	visual.observe_displacement(Vector2(0, 0.01))
	assert_eq(visual.animation, &"contact", "El umbral incluye 0.01 en contacto")
	visual.observe_displacement(Vector2(0, 0.0101))
	assert_eq(visual.animation, &"advance")
	visual.observe_displacement(Vector2.ZERO)
	assert_eq(visual.animation, &"contact")

func test_contact_pose_never_attacks_and_real_contact_damage_keeps_existing_rule() -> void:
	var soldier := _soldier()
	var enemy := _enemy(Vector2(194, 336))
	var visual: EnemigoVisual = enemy.get_node("AnimatedSprite2D")
	await wait_physics_frames(12)
	var health := soldier._current_health
	for repeat in 20: visual.observe_displacement(Vector2.ZERO)
	await wait_seconds(0.20)
	assert_eq(soldier._current_health, health, "Repetir contacto sin tick jugable no crea ataques")
	assert_eq(enemy._current_health, 500)
	soldier.set_physics_process(true)
	await wait_until(func(): return soldier._current_health < health, 0.30)
	assert_eq(soldier._current_health, health - enemy.stats.melee_damage, "Daño sigue viniendo del combate del Soldado real")

func test_nonlethal_hit_is_brief_overlay_without_changing_movement_or_health_rules() -> void:
	var enemy := _enemy()
	var visual: AnimatedSprite2D = enemy.get_node("AnimatedSprite2D")
	await wait_physics_frames(3)
	assert_false(enemy.take_damage(1))
	await wait_seconds(0.03)
	assert_ne(visual.modulate, Color.WHITE)
	assert_eq(visual.animation, &"advance", "Impacto no reemplaza movimiento")
	assert_eq(enemy._current_health, 499)
	var before := enemy.global_position
	await wait_seconds(0.13)
	assert_eq(visual.modulate, Color.WHITE, "Impacto termina a los 0.12s")
	assert_gt(enemy.global_position.distance_to(before), 0.01)
	assert_eq(enemy.stats.move_speed, 120.0)

func test_two_real_enemies_keep_pose_tint_and_progress_independent() -> void:
	_soldier()
	var blocked := _enemy(Vector2(194, 336))
	var moving := _enemy(Vector2(600, 144))
	await wait_physics_frames(12)
	blocked.take_damage(1)
	await wait_seconds(0.03)
	var first: AnimatedSprite2D = blocked.get_node("AnimatedSprite2D")
	var second: AnimatedSprite2D = moving.get_node("AnimatedSprite2D")
	assert_eq(first.animation, &"contact")
	assert_eq(second.animation, &"advance")
	assert_ne(first.modulate, second.modulate)
	var progress := [second.frame, second.frame_progress]
	first.set_frame_and_progress(3, 0.75)
	assert_eq([second.frame, second.frame_progress], progress)
	assert_eq(moving._current_health, 500)

func test_ten_real_pool_reuses_reset_authored_presentation_before_first_frame() -> void:
	var pool := _pool()
	var stats: EnemyStats = load("res://resources/enemies/enemigo_infanteria_base.tres")
	var original: Enemigo
	for cycle in 10:
		var enemy := pool.acquire() as Enemigo
		if original == null: original = enemy
		assert_same(enemy, original)
		enemy.prepare_for_spawn(stats, Vector2(600, 100 + cycle))
		var visual: EnemigoVisual = enemy.get_node("AnimatedSprite2D")
		assert_true(enemy.visible)
		assert_true(visual.visible)
		assert_eq(visual.modulate, Color.WHITE)
		assert_eq(visual.scale, Vector2(0.75, 0.80))
		assert_eq(visual.offset, Vector2(0, -3))
		assert_false(visual.flip_h)
		assert_false(visual.flip_v)
		assert_eq(visual.frame, 0)
		assert_eq(visual.frame_progress, 0.0)
		assert_eq(visual.speed_scale, 1.0)
		assert_eq(visual.rotation, 0.0)
		assert_null(visual.material)
		assert_eq(enemy._current_health, stats.max_health)
		enemy.take_damage(1)
		visual.scale = Vector2(3, 2)
		visual.offset = Vector2(9, 9)
		visual.flip_h = true
		visual.flip_v = true
		visual.speed_scale = 2.0
		visual.rotation = 0.2
		visual.material = CanvasItemMaterial.new()
		visual.visible = false
		visual.set_frame_and_progress(3, 0.75)
		if cycle % 2 == 0: enemy.take_damage(stats.max_health)
		else: pool.release(enemy)
		assert_eq(pool.in_use_count(), 0)

func test_reacquire_before_old_hit_finishes_does_not_restore_old_feedback_or_dead_pose() -> void:
	var pool := _pool()
	var enemy := pool.acquire() as Enemigo
	var stats: EnemyStats = load("res://resources/enemies/enemigo_infanteria_base.tres")
	enemy.prepare_for_spawn(stats, Vector2(600, 100))
	enemy.take_damage(1)
	await wait_seconds(0.04)
	enemy.take_damage(stats.max_health)
	assert_eq(pool.in_use_count(), 0)
	var reused := pool.acquire() as Enemigo
	reused.prepare_for_spawn(stats, Vector2(900, 100))
	var visual: EnemigoVisual = reused.get_node("AnimatedSprite2D")
	assert_true(visual.visible)
	assert_eq(visual.modulate, Color.WHITE)
	await wait_seconds(0.03)
	reused.take_damage(1)
	await wait_seconds(0.06)
	assert_ne(visual.modulate, Color.WHITE, "Callback del golpe anterior no borra el golpe de la nueva activación")
	await wait_seconds(0.10)
	assert_eq(visual.modulate, Color.WHITE)
	assert_true(visual.visible)
	assert_eq(visual.animation, &"advance")
	assert_eq(reused._current_health, stats.max_health - 1)
