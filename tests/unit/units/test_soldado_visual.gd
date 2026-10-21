extends GutTest
## 004/T005: hechos reales del soldado y ciclo visual independiente del arte.
const Fixtures := preload("res://tests/unit/units/visual_test_fixtures.gd")
const Visual := preload("res://scenes/units/soldado_visual.gd")
const EnemyDouble := preload("res://tests/unit/units/enemigo_double.gd")
var _ammo_before: int
var _shared_frames: SpriteFrames
var _game_state_before: int
var _world: Node2D

func before_each() -> void:
	_ammo_before = EconomyManager.collected_ammo
	_game_state_before = GameStateManager.get("_current_state")
	GameStateManager.set("_current_state", GameStateManager.GameState.PLAYING)
	_world = Node2D.new()
	add_child_autofree(_world)
	_shared_frames = Fixtures.frames()

func after_each() -> void:
	EconomyManager.collected_ammo = _ammo_before
	GameStateManager.set("_current_state", _game_state_before)

func _soldier(ammo := 3, position := Vector2(144, 336)) -> Soldado:
	var soldier: Soldado = load("res://scenes/units/Soldado.tscn").instantiate()
	soldier.stats = load("res://resources/units/soldado_base_stats.tres").duplicate()
	soldier.stats.max_ammo = ammo
	soldier.stats.fire_rate = 1.0
	var sprite: AnimatedSprite2D = soldier.get_node("AnimatedSprite2D")
	# Solo interfaz y datos; el fixture NO cablea eventos del actor al presentador.
	sprite.set_script(Visual)
	sprite.sprite_frames = _shared_frames
	sprite.scale = Vector2.ONE
	sprite.offset = Vector2.ZERO
	sprite.flip_h = false
	sprite.flip_v = false
	soldier.position = position
	soldier.set_grid_cell(Vector2i(floori(position.x / 96), floori(position.y / 96)))
	_world.add_child(soldier)
	return soldier

func _enemy(soldier: Soldado, health := 100, offset := Vector2(150, 0)) -> EnemyDouble:
	var enemy := EnemyDouble.new()
	enemy.health = health
	enemy.position = soldier.position + offset
	_world.add_child(enemy)
	return enemy

func _presenter() -> SoldadoVisual:
	var visual := Visual.new()
	visual.sprite_frames = Fixtures.frames()
	return add_child_autofree(visual)

func test_initial_real_rifle_mode_is_an_idle_weapon_pose() -> void:
	var soldier := _soldier()
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"rifle_idle")

func test_without_target_no_fictitious_shots_or_ammo_are_created() -> void:
	var soldier := _soldier()
	await wait_seconds(0.20)
	assert_eq(soldier._current_ammo, 3)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"rifle_idle")

func test_real_rifle_shot_has_one_reaction_without_extra_damage_or_ammo() -> void:
	var soldier := _soldier()
	var enemy := _enemy(soldier)
	await wait_until(func(): return soldier._current_ammo == 2, 0.50)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"rifle_shot")
	await wait_seconds(0.20)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"rifle_idle")
	assert_eq(enemy.damage_received, [5], "El clip no repite el daño ni acelera la cadencia")
	assert_eq(soldier._current_ammo, 2)

func test_last_bullet_kill_immediately_shows_machete_and_preserves_real_morale() -> void:
	var soldier := _soldier(1)
	_enemy(soldier, 5)
	await wait_until(func(): return soldier._current_ammo == 0, 0.50)
	assert_eq(soldier._mode, Soldado.SoldierMode.MELEE)
	assert_eq(soldier._current_morale, 1.0)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"melee_idle")
	await wait_seconds(0.20)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"melee_idle", "Callback del último disparo no restaura fusil")

func test_real_melee_hit_has_its_own_reaction_without_extra_damage() -> void:
	var soldier := _soldier(1)
	_enemy(soldier, 5)
	await wait_until(func(): return soldier._mode == Soldado.SoldierMode.MELEE, 0.50)
	var enemy := _enemy(soldier, 100, Vector2(40, 0))
	await wait_until(func(): return not enemy.damage_received.is_empty(), 0.50)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"melee_attack")
	await wait_seconds(0.28)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"melee_idle")
	assert_eq(enemy.damage_received, [4], "Daño de machete real: base3+moral1; el clip no golpea otra vez")

func test_existing_reload_restores_rifle_without_losing_morale_or_changing_cost() -> void:
	var soldier := _soldier(1)
	_enemy(soldier, 5)
	await wait_until(func(): return soldier._mode == Soldado.SoldierMode.MELEE, 0.50)
	EconomyManager.add_ammo(20)
	var reserve := EconomyManager.collected_ammo
	soldier.reload()
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"rifle_idle")
	assert_eq(soldier._current_morale, 1.0)
	assert_eq(EconomyManager.collected_ammo, reserve - soldier.stats.deploy_ammo_cost)
	await wait_seconds(0.30)
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"rifle_idle")

func test_nonlethal_real_damage_overlays_current_weapon_and_expires() -> void:
	var soldier := _soldier()
	var visual: AnimatedSprite2D = soldier.get_node("AnimatedSprite2D")
	soldier.take_damage(1)
	await wait_seconds(0.04)
	assert_ne(visual.modulate, Color.WHITE, "El daño real debe tener feedback breve")
	assert_eq(visual.animation, &"rifle_idle")
	assert_eq(soldier._current_health, 29)
	await wait_seconds(0.12)
	assert_eq(visual.modulate, Color.WHITE)

func test_damage_and_real_kill_morale_overlap_and_both_return_to_neutral() -> void:
	var soldier := _soldier()
	var visual: AnimatedSprite2D = soldier.get_node("AnimatedSprite2D")
	_enemy(soldier, 5)
	await wait_until(func(): return soldier._current_morale > 0.0, 0.50)
	soldier.take_damage(1)
	await wait_seconds(0.04)
	assert_ne(visual.modulate, Color.WHITE)
	assert_gt(visual.scale.x, 1.0)
	assert_lte(visual.scale.x, 1.10)
	await wait_seconds(0.20)
	assert_eq(visual.modulate, Color.WHITE)
	assert_eq(visual.scale, Vector2.ONE)
	assert_eq(soldier._current_morale, 1.0)

func test_mode_change_interrupts_shot_and_stale_completion_uses_current_mode() -> void:
	var visual := _presenter()
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	visual.play_confirmed_attack(Soldado.SoldierMode.RIFLE)
	visual.observe_mode(Soldado.SoldierMode.MELEE)
	assert_eq(visual.animation, &"melee_idle")
	await wait_seconds(0.22)
	assert_eq(visual.animation, &"melee_idle")


## 005/T048: nuevas transiciones observadoras, sin assertions de píxeles.
func test_i4_last_bullet_survivor_drives_march_from_real_physical_movement() -> void:
	var soldier := _soldier(1)
	var enemy := _enemy(soldier, 100, Vector2(200, 0))
	var home := soldier.global_position
	await wait_physics_frames(8)
	assert_eq(soldier._current_ammo, 0)
	assert_gt(soldier.global_position.x, home.x, "El actor realmente avanza")
	assert_eq(soldier.get_node("AnimatedSprite2D").animation, &"melee_march",
		"Última bala no deja fusil ni machete inmóvil mientras sale")
	assert_eq(enemy.damage_received, [5], "La marcha no añade golpes ni disparos")


func test_i4_motion_observer_distinguishes_real_march_from_waiting() -> void:
	var visual := _presenter()
	visual.reset_visual(Soldado.SoldierMode.MELEE)
	visual.observe_motion(Soldado.MovementState.ADVANCING, Vector2(0.7, 0))
	assert_eq(visual.animation, &"melee_march")
	visual.observe_motion(Soldado.MovementState.WAITING, Vector2.ZERO)
	assert_eq(visual.animation, &"melee_idle", "Espera no inventa pasos ni un golpe")
	visual.observe_motion(Soldado.MovementState.ADVANCING, Vector2.ZERO)
	assert_eq(visual.animation, &"melee_idle", "Intención sin desplazamiento no acredita marcha")


func test_i4_returning_with_and_without_displacement_has_nonoffensive_left_pose() -> void:
	var visual := _presenter()
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	visual.observe_motion(Soldado.MovementState.RETURNING, Vector2(-0.7, 0))
	assert_eq(visual.animation, &"returning", "Carga llena durante retorno no muestra fusil listo")
	assert_true(visual.flip_h, "Mira hacia su hogar izquierdo")
	visual.observe_motion(Soldado.MovementState.RETURNING, Vector2.ZERO)
	assert_eq(visual.animation, &"returning_idle", "Bloqueo no inventa pasos ni ofensiva")
	assert_true(visual.flip_h)
	visual.observe_motion(Soldado.MovementState.HOME, Vector2.ZERO)
	assert_eq(visual.animation, &"rifle_idle")
	assert_false(visual.flip_h, "En hogar vuelve al frente derecho")


func test_i4_real_reload_outside_keeps_return_pose_after_previous_action_expires() -> void:
	var soldier := _soldier(1)
	_enemy(soldier, 5)
	await wait_until(func(): return soldier._current_ammo == 0, 0.50)
	soldier.position.x += 96.0 # Fixture exterior; el viaje siguiente es físico real.
	EconomyManager.add_ammo(soldier.stats.deploy_ammo_cost)
	assert_true(soldier.request_reload())
	var before := soldier.global_position
	await wait_seconds(0.30)
	assert_lt(soldier.global_position.x, before.x)
	assert_eq(soldier.get_movement_state(), Soldado.MovementState.RETURNING)
	var visual: SoldadoVisual = soldier.get_node("AnimatedSprite2D")
	assert_eq(visual.animation, &"returning", "Callback antiguo no restaura rifle_idle")
	assert_true(visual.flip_h)
	assert_eq(soldier._current_ammo, soldier.stats.max_ammo)


func test_i4_return_interrupts_attack_callback_and_ignores_offensive_pose() -> void:
	var visual := _presenter()
	visual.reset_visual(Soldado.SoldierMode.MELEE)
	visual.play_confirmed_attack(Soldado.SoldierMode.MELEE)
	visual.observe_mode(Soldado.SoldierMode.RIFLE)
	visual.observe_motion(Soldado.MovementState.RETURNING, Vector2(-1, 0))
	visual.play_confirmed_attack(Soldado.SoldierMode.RIFLE)
	await wait_seconds(0.30)
	assert_eq(visual.animation, &"returning", "Ni señal tardía ni callback rearman durante regreso")
	assert_true(visual.flip_h)


func test_i4_defeat_snapshot_preserves_return_orientation_without_hit_or_morale_tint() -> void:
	var visual := _presenter()
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	visual.observe_motion(Soldado.MovementState.RETURNING, Vector2(-1, 0))
	visual.play_confirmed_hit()
	visual.play_confirmed_morale()
	var snapshot := visual.capture_defeat_snapshot(Vector2(432, 144))
	assert_eq(snapshot.world_position, Vector2(432, 144))
	assert_true(snapshot.flip_h, "Caída conserva la orientación actual hacia hogar")
	assert_eq(snapshot.visual_scale, Vector2.ONE, "No captura pulso de moral transitorio")
	assert_false(snapshot.has("modulate"), "No filtra impacto a la caída neutra")


func test_i4_reset_clears_return_facing_frame_rotation_speed_and_old_callbacks() -> void:
	var visual := _presenter()
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	visual.observe_motion(Soldado.MovementState.RETURNING, Vector2(-1, 0))
	visual.play_confirmed_hit()
	visual.rotation = 0.3
	visual.speed_scale = 2.0
	visual.set_frame_and_progress(3, 0.8)
	visual.reset_visual(Soldado.SoldierMode.MELEE)
	assert_false(visual.flip_h)
	assert_eq(visual.rotation, 0.0)
	assert_eq(visual.speed_scale, 1.0)
	assert_eq([visual.frame, visual.frame_progress], [0, 0.0])
	await wait_seconds(0.20)
	assert_eq(visual.animation, &"melee_idle")
	assert_eq(visual.modulate, Color.WHITE)


func test_i4_motion_observations_do_not_move_reload_damage_or_change_gameplay() -> void:
	var soldier := _soldier()
	soldier.set_physics_process(false)
	var visual: SoldadoVisual = soldier.get_node("AnimatedSprite2D")
	var before := [soldier.global_position, soldier.get_reload_state(), EconomyManager.collected_ammo]
	for state: int in [Soldado.MovementState.ADVANCING, Soldado.MovementState.RETURNING, Soldado.MovementState.HOME]:
		visual.observe_motion(state, Vector2(-1, 0))
		visual.capture_defeat_snapshot(soldier.global_position)
	await wait_seconds(0.20)
	assert_eq([soldier.global_position, soldier.get_reload_state(), EconomyManager.collected_ammo], before,
		"Observaciones, snapshots y callbacks no ordenan el cuerpo ni cambian combate/recursos")

func test_deactivation_wins_over_hit_morale_and_pending_attack_callbacks() -> void:
	var visual := _presenter()
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	visual.play_confirmed_attack(Soldado.SoldierMode.RIFLE)
	visual.play_confirmed_hit()
	visual.play_confirmed_morale()
	visual.deactivate_visual()
	assert_false(visual.visible)
	await wait_seconds(0.30)
	assert_false(visual.visible, "Los callbacks vivos no reviven al actor retirado")
	assert_eq(visual.modulate, Color.WHITE)
	assert_eq(visual.scale, Vector2.ONE)

func test_two_real_soldiers_keep_independent_mode_animation_and_progress() -> void:
	var first := _soldier(1)
	var second := _soldier(3, Vector2(144, 528))
	_enemy(first, 5)
	await wait_until(func(): return first._mode == Soldado.SoldierMode.MELEE, 0.50)
	assert_eq(first.get_node("AnimatedSprite2D").animation, &"melee_idle")
	assert_eq(second.get_node("AnimatedSprite2D").animation, &"rifle_idle")
	assert_eq(second._current_ammo, 3)
	assert_eq(second._current_morale, 0.0)

func test_presentation_callbacks_do_not_mutate_gameplay_or_resources() -> void:
	var soldier := _soldier()
	var visual: SoldadoVisual = soldier.get_node("AnimatedSprite2D")
	var before := [soldier._current_health, soldier._current_ammo, soldier._current_morale, soldier._mode, EconomyManager.collected_ammo]
	visual.play_confirmed_attack(Soldado.SoldierMode.RIFLE)
	visual.play_confirmed_hit()
	visual.play_confirmed_morale()
	await wait_seconds(0.30)
	assert_eq([soldier._current_health, soldier._current_ammo, soldier._current_morale, soldier._mode, EconomyManager.collected_ammo], before)

func test_authored_nonunit_scale_survives_morale_snapshot_and_reset_callbacks() -> void:
	var visual := Visual.new()
	visual.sprite_frames = Fixtures.frames()
	var authored := Vector2(0.4, 0.5)
	visual.scale = authored
	visual.offset = Vector2(0, -3)
	visual.flip_h = true
	add_child_autofree(visual)
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	visual.play_confirmed_morale()
	visual.play_confirmed_hit()
	await wait_seconds(0.04)
	assert_gt(visual.scale.x, authored.x)
	assert_lte(visual.scale.x, authored.x * 1.10 + 0.001)
	var snapshot: Dictionary = visual.capture_defeat_snapshot(Vector2(10, 20))
	assert_has(snapshot, "visual_scale")
	if snapshot.has("visual_scale"): assert_eq(snapshot["visual_scale"], authored)
	visual.deactivate_visual()
	visual.reset_visual(Soldado.SoldierMode.MELEE)
	await wait_seconds(0.25)
	assert_true(visual.visible)
	assert_eq(visual.scale, authored, "Reset conserva escala propia, sin hardcodear ONE")
	assert_eq(visual.offset, Vector2(0, -3))
	assert_true(visual.flip_h)
	assert_eq(visual.modulate, Color.WHITE)
	assert_eq(visual.animation, &"melee_idle")
