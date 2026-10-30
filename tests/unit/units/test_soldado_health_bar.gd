extends GutTest
## 011/T003: la barra observa salud, combate y ciclo de partida reales.
const SOLDIER_SCENE := preload("res://scenes/units/Soldado.tscn")
const ENEMY_DOUBLE := preload("res://tests/unit/units/enemigo_double.gd")
const ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const RETRY_LEVEL := preload("res://tests/unit/game/fixtures/OneWaveLevel.tscn")
var _world: Node2D
var _saved_state: int
var _saved_ammo: int
var _saved_waves: Dictionary


class SeenIntro:
	extends RefCounted
	func has_seen(_version: String) -> bool:
		return true
	func mark_seen(_version: String) -> Error:
		return OK


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


func after_each() -> void:
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _soldier(maximum := 30, at := Vector2(144, 336), ammo := 10) -> Soldado:
	var soldier := SOLDIER_SCENE.instantiate() as Soldado
	soldier.stats = soldier.stats.duplicate()
	soldier.stats.max_health = maximum
	soldier.stats.max_ammo = ammo
	soldier.position = at
	soldier.set_grid_cell(Vector2i(1, int(at.y / 96.0)))
	_world.add_child(soldier)
	soldier.set_physics_process(false)
	return soldier


func _bar(actor: Node) -> WorldHealthBar:
	return actor.get_node("HealthBar") as WorldHealthBar


func test_initial_bar_uses_this_soldiers_stats_including_the_production_maximum(
		maximum = use_parameters([30, 47])) -> void:
	var soldier := _soldier(maximum)
	var bar := _bar(soldier)
	assert_eq(soldier.get_reload_state().health, maximum)
	assert_eq(bar.value, float(maximum))
	assert_eq(bar.max_value, float(maximum), "No asumir un máximo fijo en la presentación")
	assert_true(bar.is_visible_in_tree())


func test_damage_updates_only_the_wounded_soldier_without_changing_ammo_or_morale() -> void:
	var wounded := _soldier()
	var other := _soldier(30, Vector2(144, 432))
	var before := wounded.get_reload_state()
	assert_false(wounded.take_damage(7))
	assert_eq(wounded.get_reload_state().health, 23)
	assert_eq(wounded.get_reload_state().ammo, before.ammo)
	assert_eq(wounded.get_reload_state().morale, before.morale)
	assert_eq(_bar(wounded).value, 23.0, "El daño se refleja en la misma llamada")
	assert_eq(_bar(wounded).max_value, 30.0)
	assert_true(_bar(wounded).visible)
	assert_eq(_bar(other).value, 30.0, "El compañero conserva su vida completa")
	assert_true(_bar(other).visible)


func test_real_last_shot_and_reload_preserve_wounds_and_morale_while_returning() -> void:
	var soldier := _soldier(30, Vector2(144, 336), 1)
	var target := ENEMY_DOUBLE.new()
	target.health = soldier.stats.damage_per_shot
	target.position = soldier.position + Vector2(150, 0)
	_world.add_child(target)
	soldier.take_damage(7)
	soldier.set_physics_process(true)
	for frame in 45:
		if soldier.get_reload_state().ammo == 0:
			break
		await wait_physics_frames(1)
	soldier.set_physics_process(false)
	var before := soldier.get_reload_state()
	assert_eq(before.ammo, 0, "Control: se agotó mediante un disparo real")
	assert_eq(before.morale, soldier.stats.moral_per_kill, "Control: el disparo confirmó una baja")
	soldier.position.x += 120.0
	EconomyManager.collected_ammo = soldier.stats.deploy_ammo_cost
	assert_true(soldier.request_reload())
	var after := soldier.get_reload_state()
	assert_eq(after.ammo, 1)
	assert_eq(after.health, 23, "Recargar no cura")
	assert_eq(after.morale, before.morale)
	assert_eq(after.movement_state, Soldado.MovementState.RETURNING)
	assert_eq(_bar(soldier).value, 23.0)
	assert_eq(_bar(soldier).max_value, 30.0)
	assert_true(_bar(soldier).visible)


func test_bar_follows_the_actor_without_inheriting_the_sprites_flip_or_hit_tint() -> void:
	var soldier := _soldier()
	var bar := _bar(soldier)
	var sprite := soldier.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert_same(bar.get_parent(), soldier, "La barra está fuera del visual animado")
	assert_false(bar.show_percentage)
	assert_eq(bar.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(bar.focus_mode, Control.FOCUS_NONE)
	var original_transform := bar.get_global_transform()
	var original_color := bar.modulate
	soldier.take_damage(1)
	sprite.flip_h = true
	sprite.modulate = Color(1.4, 1.2, 1.0)
	assert_eq(bar.get_global_transform(), original_transform)
	assert_eq(bar.modulate, original_color)
	var displacement := Vector2(80, 0)
	soldier.position += displacement
	assert_eq(bar.global_position, original_transform.origin + displacement)
	assert_eq(bar.value, 29.0)
	assert_true(bar.visible)


func test_lethal_damage_removes_the_bar_before_visual_and_gameplay_callbacks() -> void:
	var soldier := _soldier()
	var bar := _bar(soldier)
	var observed: Array = []
	assert_eq(bar.value, 30.0, "Precondición: la baja parte de un indicador completo")
	soldier.defeat_visual_requested.connect(func(_snapshot: Dictionary):
		observed.append(["visual", bar.visible, bar.value]))
	soldier.soldier_defeated.connect(func(_cell: Vector2i):
		observed.append(["defeat", bar.visible, bar.value]))
	assert_true(soldier.take_damage(99))
	assert_eq(observed, [["visual", false, 0.0], ["defeat", false, 0.0]])
	assert_false(bar.visible)
	assert_eq(bar.value, 0.0)


func _combatants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in node.get_children():
		if child is Soldado or child is Enemigo:
			result.append(child)
		result.append_array(_combatants(child))
	return result


func test_retry_releases_old_indicators_and_starts_both_sides_with_fresh_bars() -> void:
	var empty: Array[WaveData] = []
	WaveManager.waves = empty
	WaveManager.current_wave_index = -1
	WaveManager._total_enemies_in_current_wave = 0
	WaveManager._defeated_in_current_wave = 0
	var app := ROOT_SCENE.instantiate()
	app.set("level_scene", RETRY_LEVEL)
	# Las barras y Retry se verifican con la carta ya vista, sin perfil real.
	app.set("intro_progress", SeenIntro.new())
	_world.add_child(app)
	app.request_start()
	var level: Node
	for frame in 30:
		level = app.get_current_level()
		if level != null:
			break
		await wait_process_frames(1)
	assert_not_null(level, "Control: la entrada real inició la partida")
	if level == null:
		return
	var old_bars: Array[WeakRef] = []
	for actor: Node in _combatants(level):
		actor.set_physics_process(false)
		old_bars.append(weakref(_bar(actor)))
		if actor is Soldado or (actor as Enemigo).is_targetable():
			actor.take_damage(1)
	var old_id := level.get_instance_id()
	GameStateManager.report_reached_defended_position()
	app.request_retry()
	var replacement: Node
	for frame in 30:
		var candidate: Node = app.get_current_level()
		if candidate != null and candidate.get_instance_id() != old_id:
			replacement = candidate
			break
		await wait_process_frames(1)
	assert_not_null(replacement, "Control: Retry reemplazó el nivel anterior")
	if replacement == null:
		return
	for reference: WeakRef in old_bars:
		assert_null(reference.get_ref(), "No sobrevive ninguna barra del intento anterior")
	var living_soldiers := 0
	var living_enemies := 0
	for actor: Node in _combatants(replacement):
		actor.set_physics_process(false)
		var bar := _bar(actor)
		if actor is Enemigo and not (actor as Enemigo).is_targetable():
			assert_false(bar.visible, "El pool inactivo no muestra indicadores")
			continue
		if actor is Soldado:
			living_soldiers += 1
		else:
			living_enemies += 1
		assert_eq(bar.value, float(actor.stats.max_health))
		assert_eq(bar.max_value, float(actor.stats.max_health))
		assert_true(bar.is_visible_in_tree())
	assert_eq(living_soldiers, 5)
	assert_gt(living_enemies, 0, "También se verificó un enemigo de la nueva partida")
