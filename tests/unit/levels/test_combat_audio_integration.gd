extends GutTest
## 014/T004–T005: composición real; una oleada corta declarada, no producción99.
const ROOT := preload("res://scenes/game/GameRoot.tscn")
const LEVEL := preload("res://tests/unit/game/fixtures/OneWaveLevel.tscn")
var _viewport: SubViewport
var _app: Node
var _saved: Dictionary
var _events: Array[StringName] = []

class SeenIntro:
	extends RefCounted
	func has_seen(_version: String) -> bool: return true
	func mark_seen(_version: String) -> Error: return OK


func before_each() -> void:
	_saved = {"state": GameStateManager._current_state, "ammo": EconomyManager.collected_ammo, "waves": {}}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved.waves[key] = WaveManager.get(key)
	WaveManager.cancel_waves()
	GameStateManager.enter_menu()
	_events.clear()
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.world_2d = World2D.new()
	_viewport.handle_input_locally = true
	add_child_autofree(_viewport)
	_app = ROOT.instantiate()
	_app.set("intro_progress", SeenIntro.new())
	_app.set("level_scene", LEVEL)
	_viewport.add_child(_app)


func after_each() -> void:
	var level: Node = _app.get_current_level()
	if level != null: level.close_match()
	GameStateManager._current_state = _saved.state
	EconomyManager.collected_ammo = _saved.ammo
	for key: String in _saved.waves: WaveManager.set(key, _saved.waves[key])


func _start() -> Node:
	_app.request_start()
	for frame in 30:
		var level: Node = _app.get_current_level()
		if level != null: return level
		await wait_process_frames(1)
	return null


func _audio(level: Node) -> CombatAudio:
	var found: Array[CombatAudio] = []
	for child: Node in level.get_children():
		if child is CombatAudio: found.append(child as CombatAudio)
	assert_eq(found.size(), 1, "El nivel monta exactamente un servicio local antes de usar actores")
	if found.size() != 1: return null
	found[0].cue_started.connect(func(cue: StringName): _events.append(cue))
	return found[0]


func _enemies(node: Node) -> Array[Enemigo]:
	var result: Array[Enemigo] = []
	for child: Node in node.get_children():
		if child is Enemigo and child.is_targetable(): result.append(child as Enemigo)
		result.append_array(_enemies(child))
	return result


func _soldier(level: Node, home: Vector2i) -> Soldado:
	for child: Node in level.get_children():
		if child is Soldado and not child.is_queued_for_deletion() and child.get_reload_state().home_cell == home:
			return child as Soldado
	return null


func _click_world(world: Vector2) -> void:
	_viewport.notify_mouse_entered()
	var screen := _viewport.canvas_transform * world
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	_viewport.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = screen
		event.global_position = screen
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		_viewport.push_input(event, true)


func test_level_registers_initial_recycled_wave_and_replacement_actors() -> void:
	var level: Node = await _start()
	assert_not_null(level)
	if level == null: return
	var audio := _audio(level)
	if audio == null: return
	for frame in 30:
		if _enemies(level).size() >= 2: break
		await wait_physics_frames(1)
	var initial: Enemigo
	var wave: Enemigo
	for enemy: Enemigo in _enemies(level):
		if enemy.spawn_origin == Enemigo.SpawnOrigin.INITIAL: initial = enemy
		else: wave = enemy
	assert_not_null(initial, "Control: enemigo inicial real")
	assert_not_null(wave, "Control: enemigo de la oleada real")
	if initial == null or wave == null: return
	assert_true(initial.take_damage(9999))
	assert_eq(_events, [&"enemy_death"])
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING, "Inicial no completa la oleada")
	var spawner: WaveSpawner
	for child: Node in level.get_children():
		if child is WaveSpawner: spawner = child as WaveSpawner
	assert_not_null(spawner)
	if spawner == null: return
	var reused := spawner.spawn_initial_enemy(level.initial_enemy_stats)
	assert_same(reused, initial, "Control: spawner vuelve a usar un cuerpo liberado")
	assert_true(reused.take_damage(9999))
	assert_eq(_events, [&"enemy_death", &"enemy_death"], "Registro por nodo permite otra activación")
	var home := Vector2i(1, 1)
	var soldier := _soldier(level, home)
	assert_not_null(soldier)
	if soldier == null: return
	assert_true(soldier.take_damage(9999))
	assert_eq(_events.slice(-1), [&"soldier_death"])
	await wait_process_frames(2)
	EconomyManager.collected_ammo = 100
	var cell: Vector2 = Vector2(level.board_config.cell_size)
	_click_world(Vector2(home) * cell + cell * 0.5)
	await wait_physics_frames(3)
	var replacement := _soldier(level, home)
	assert_not_null(replacement, "Control: despliegue por entrada real tras liberar la plaza")
	if replacement == null: return
	assert_true(replacement.take_damage(9999))
	assert_eq(_events.count(&"soldier_death"), 2, "El reemplazo también queda observado")
	assert_true(wave.take_damage(9999))
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON)
	assert_eq(_events.slice(-2), [&"enemy_death", &"victory"], "Baja de WAVE precede al resultado")


func test_level_soldier_consumes_a_real_bullet_and_is_already_observed() -> void:
	var level: Node = await _start()
	assert_not_null(level)
	if level == null: return
	var audio := _audio(level)
	if audio == null: return
	var soldier := _soldier(level, Vector2i(1, 3))
	assert_not_null(soldier)
	var enemies := _enemies(level)
	assert_false(enemies.is_empty())
	if soldier == null or enemies.is_empty(): return
	var enemy := enemies[0]
	enemy.stats = enemy.stats.duplicate()
	enemy.stats.move_speed = 0.0
	enemy.set("_current_health", 999)
	enemy.global_position = soldier.global_position + Vector2(150, 0)
	var before: int = soldier.get_reload_state().ammo
	for frame in 45:
		if soldier.get_reload_state().ammo < before: break
		await wait_physics_frames(1)
	assert_eq(soldier.get_reload_state().ammo, before - 1, "Control: combate real del nivel")
	assert_eq(_events, [&"rifle"])


func test_root_menu_and_retry_retire_audio_without_false_results_or_old_callbacks() -> void:
	var first: Node = await _start()
	assert_not_null(first)
	if first == null: return
	var audio := _audio(first)
	if audio == null: return
	var enemies := _enemies(first)
	assert_false(enemies.is_empty(), "Control: existe un actor real para capturar la conexión")
	if enemies.is_empty(): return
	var enemy := enemies[0]
	var snapshot: Dictionary = enemy.get_node("AnimatedSprite2D").capture_defeat_snapshot(enemy.global_position)
	var old: Array[Callable] = []
	for entry: Dictionary in enemy.get_signal_connection_list("defeat_visual_requested"):
		if entry.callable.get_object() == audio: old.append(entry.callable)
	assert_false(old.is_empty())
	var previous: WeakRef = weakref(audio)
	_app.request_menu()
	for frame in 30:
		var ready := false
		for button: Node in _app.find_children("*", "Button", true, false):
			if button.text == "Jugar" and button.is_visible_in_tree() and not button.disabled: ready = true
		if _app.get_current_level() == null and previous.get_ref() == null and ready: break
		await wait_process_frames(1)
	assert_null(_app.get_current_level())
	assert_null(previous.get_ref(), "Retiro libera el audio del intento")
	assert_true(_events.is_empty(), "Menú no es una derrota")
	var second: Node = await _start()
	assert_not_null(second)
	if second == null: return
	var second_audio := _audio(second)
	if second_audio == null: return
	for callback: Callable in old:
		if callback.is_valid(): callback.call(snapshot)
	assert_true(_events.is_empty(), "Callbacks viejos no contaminan el intento siguiente")
	assert_eq(second_audio.get_active_voice_count(), 0)
	GameStateManager.report_reached_defended_position()
	assert_eq(_events, [&"defeat"])
	var retired: WeakRef = weakref(second_audio)
	_app.request_retry()
	var third: Node
	for frame in 30:
		third = _app.get_current_level()
		if third != null and (not is_instance_valid(second) or third != second): break
		await wait_process_frames(1)
	assert_not_null(third)
	assert_null(retired.get_ref())
	assert_eq(_events, [&"defeat"], "Retry no crea resultado ni sonidos atrasados")
	if third != null:
		var third_audio := _audio(third)
		if third_audio != null: assert_eq(third_audio.get_active_voice_count(), 0)
