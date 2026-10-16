extends GutTest
## 004/T005: hechos reales del soldado y ciclo visual independiente del arte.
const Fixtures := preload("res://tests/unit/units/visual_test_fixtures.gd")
const Visual := preload("res://scenes/units/soldado_visual.gd")
const EnemyDouble := preload("res://tests/unit/units/enemigo_double.gd")
var _ammo_before: int
var _shared_frames: SpriteFrames

func before_each() -> void:
	_ammo_before = EconomyManager.collected_ammo
	_shared_frames = Fixtures.frames()

func after_each() -> void:
	EconomyManager.collected_ammo = _ammo_before

func _soldier(ammo := 3, position := Vector2.ZERO) -> Soldado:
	var soldier: Soldado = load("res://scenes/units/Soldado.tscn").instantiate()
	soldier.stats = load("res://resources/units/soldado_base_stats.tres").duplicate()
	soldier.stats.max_ammo = ammo
	soldier.stats.fire_rate = 1.0
	var sprite: AnimatedSprite2D = soldier.get_node("AnimatedSprite2D")
	# Solo interfaz y datos; el fixture NO cablea eventos del actor al presentador.
	sprite.set_script(Visual)
	sprite.sprite_frames = _shared_frames
	soldier.position = position
	return add_child_autofree(soldier)

func _enemy(soldier: Soldado, health := 100, offset := Vector2(0, -150)) -> EnemyDouble:
	var enemy := EnemyDouble.new()
	enemy.health = health
	enemy.position = soldier.position + offset
	return add_child_autofree(enemy)

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
	var enemy := _enemy(soldier, 100, Vector2(0, -40))
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
	var second := _soldier(3, Vector2(1000, 0))
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
