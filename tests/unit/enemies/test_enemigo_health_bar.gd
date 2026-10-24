extends GutTest
## 011/T003: cada activación conserva únicamente su propio indicador de vida.
const ENEMY_SCENE := preload("res://scenes/enemies/EnemigoBase.tscn")
var _world: Node2D
var _saved_state: int


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	_world = Node2D.new()
	add_child_autofree(_world)


func after_each() -> void:
	GameStateManager._current_state = _saved_state


func _stats(maximum := 15) -> EnemyStats:
	var stats := load("res://resources/enemies/enemigo_infanteria_base.tres").duplicate() as EnemyStats
	stats.max_health = maximum
	stats.move_speed = 0.0
	stats.ammo_drop = 0
	return stats


func _enemy(maximum := 15) -> Enemigo:
	var enemy := ENEMY_SCENE.instantiate() as Enemigo
	enemy.stats = _stats(maximum)
	_world.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy


func _bar(enemy: Enemigo) -> WorldHealthBar:
	return enemy.get_node("HealthBar") as WorldHealthBar


func _pool() -> ObjectPool:
	var pool := ObjectPool.new()
	_world.add_child(pool)
	pool.instance_created.connect(func(node: Node): (node as Enemigo).set_pool(pool))
	pool.setup(ENEMY_SCENE, 1)
	return pool


func test_initial_bar_uses_this_enemys_stats_including_the_production_maximum(
		maximum = use_parameters([15, 41])) -> void:
	var enemy := _enemy(maximum)
	var bar := _bar(enemy)
	assert_true(enemy.is_targetable())
	assert_eq(bar.value, float(maximum))
	assert_eq(bar.max_value, float(maximum))
	assert_true(bar.is_visible_in_tree())
	assert_same(bar.get_parent(), enemy)
	assert_false(bar.show_percentage)
	assert_eq(bar.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(bar.focus_mode, Control.FOCUS_NONE)


func test_damage_updates_the_wounded_enemy_immediately_and_keeps_its_neighbor_full() -> void:
	var wounded := _enemy()
	var other := _enemy()
	assert_false(wounded.take_damage(5))
	assert_eq(_bar(wounded).value, 10.0)
	assert_eq(_bar(wounded).max_value, 15.0)
	assert_true(_bar(wounded).visible)
	assert_false(wounded.take_damage(7))
	assert_eq(_bar(wounded).value, 3.0)
	assert_eq(_bar(other).value, 15.0)
	assert_true(_bar(other).visible)


func test_prewarm_release_before_ready_stays_hidden_until_a_real_spawn_after_ready() -> void:
	var enemy := ENEMY_SCENE.instantiate() as Enemigo
	var bar := _bar(enemy)
	bar.set_health(3, 15)
	enemy.on_pool_released()
	assert_false(bar.visible, "Release limpia incluso antes de @onready")
	assert_eq(bar.value, 0.0)
	_world.add_child(enemy)
	enemy.set_physics_process(false)
	assert_false(enemy.is_targetable(), "Entrar al árbol no activa un enemigo precalentado")
	assert_false(bar.visible, "Ready no vuelve a mostrar un enemigo inactivo")
	enemy.prepare_for_spawn(_stats(27), Vector2(600, 100))
	assert_true(enemy.is_targetable())
	assert_eq(bar.value, 27.0)
	assert_eq(bar.max_value, 27.0)
	assert_true(bar.is_visible_in_tree())


func test_pool_release_then_different_maximum_restores_the_same_body_to_full_health() -> void:
	var pool := _pool()
	var enemy := pool.acquire() as Enemigo
	var first_stats := _stats()
	enemy.prepare_for_spawn(first_stats, Vector2(600, 100))
	var bar := _bar(enemy)
	var full_fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	assert_not_null(full_fill)
	var full_color := full_fill.bg_color if full_fill != null else Color.TRANSPARENT
	enemy.take_damage(12)
	assert_eq(bar.value, 3.0)
	pool.release(enemy)
	assert_false(bar.visible)
	assert_eq(bar.value, 0.0)
	var reused := pool.acquire() as Enemigo
	assert_same(reused, enemy, "Control: es reutilización, no otra instancia")
	reused.prepare_for_spawn(_stats(40), Vector2(900, 100))
	assert_eq(bar.value, 40.0)
	assert_eq(bar.max_value, 40.0)
	assert_true(bar.is_visible_in_tree())
	var restored_fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	assert_not_null(restored_fill)
	if restored_fill != null:
		assert_eq(restored_fill.bg_color, full_color, "La aparición recupera el color de vida completa")
	assert_eq(first_stats.max_health, 15, "La presentación no muta los stats de otra activación")


func test_lethal_damage_hides_before_visual_and_defeat_callbacks() -> void:
	var enemy := _enemy()
	var bar := _bar(enemy)
	var observed: Array = []
	assert_eq(bar.value, 15.0, "Precondición: la baja parte de un indicador completo")
	enemy.defeat_visual_requested.connect(func(_snapshot: Dictionary):
		observed.append(["visual", bar.visible, bar.value]))
	enemy.enemy_defeated.connect(func(_amount: int, _position: Vector2):
		observed.append(["defeat", bar.visible, bar.value]))
	assert_true(enemy.take_damage(99))
	assert_eq(observed, [["visual", false, 0.0], ["defeat", false, 0.0]])
	assert_false(bar.visible)
	assert_eq(bar.value, 0.0)


func test_synchronous_death_reuse_keeps_the_new_activations_full_bar_after_old_call_returns() -> void:
	var pool := _pool()
	var enemy := pool.acquire() as Enemigo
	enemy.prepare_for_spawn(_stats(), Vector2(600, 100))
	var bar := _bar(enemy)
	enemy.take_damage(10)
	assert_eq(bar.value, 5.0)
	var generation := enemy.activation_generation
	var at_defeat: Array = []
	enemy.defeat_visual_requested.connect(func(_snapshot: Dictionary):
		at_defeat.append([bar.visible, bar.value]))
	enemy.enemy_defeated.connect(func(_amount: int, _position: Vector2):
		at_defeat.append([bar.visible, bar.value])
		pool.release(enemy)
		var reused := pool.acquire() as Enemigo
		assert_same(reused, enemy)
		reused.prepare_for_spawn(_stats(40), Vector2(900, 100)))
	assert_true(enemy.take_damage(5))
	assert_eq(at_defeat, [[false, 0.0], [false, 0.0]])
	assert_eq(enemy.activation_generation, generation + 1)
	assert_true(enemy.is_targetable())
	assert_eq(bar.value, 40.0, "La baja anterior no limpia la nueva activación")
	assert_eq(bar.max_value, 40.0)
	assert_true(bar.visible)
	assert_false(enemy.take_damage(3))
	assert_eq(bar.value, 37.0, "El daño posterior pertenece al combatiente nuevo")
