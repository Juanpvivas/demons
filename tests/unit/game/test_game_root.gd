extends GutTest
## 007/T005: entrada real y transición de inicio. Los niveles son reales;
## SubViewport evita mezclar coordenadas locales con el stretch del Window.
const ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const BOARD := preload("res://resources/levels/monte_calvo_board.tres")
var _viewport: SubViewport
var _app: Node
var _saved_state: int
var _saved_ammo: int
var _saved_waves: Dictionary
var _wave_events: Array[int] = []


class GestureObserver:
	extends Node
	var presses := 0
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			presses += 1


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	_saved_ammo = EconomyManager.collected_ammo
	_saved_waves = {}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_waves[key] = WaveManager.get(key)
	var empty: Array[WaveData] = []
	WaveManager.waves = empty
	WaveManager.current_wave_index = -1
	WaveManager._total_enemies_in_current_wave = 0
	WaveManager._defeated_in_current_wave = 0
	GameStateManager.start_new_match()
	EconomyManager.collected_ammo = 0
	_wave_events.clear()
	WaveManager.wave_started.connect(_on_wave_started)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.world_2d = World2D.new()
	_viewport.handle_input_locally = true
	add_child_autofree(_viewport)
	_viewport.notify_mouse_entered()


func after_each() -> void:
	WaveManager.wave_started.disconnect(_on_wave_started)
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _on_wave_started(number: int) -> void:
	_wave_events.append(number)


func _mount(scene: PackedScene = ROOT_SCENE) -> void:
	_app = scene.instantiate()
	_viewport.add_child(_app)
	await wait_process_frames(2)


func _button(text: String) -> Button:
	for node: Node in _app.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node as Button
	return null


func _soldiers(node: Node) -> Array[Soldado]:
	var result: Array[Soldado] = []
	for child: Node in node.get_children():
		if child is Soldado and not child.is_queued_for_deletion():
			result.append(child as Soldado)
		result.append_array(_soldiers(child))
	return result


func _enemies(node: Node) -> Array[Enemigo]:
	var result: Array[Enemigo] = []
	for child: Node in node.get_children():
		if child is Enemigo and not child.is_queued_for_deletion():
			result.append(child as Enemigo)
		result.append_array(_enemies(child))
	return result


func _click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	_viewport.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.global_position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		_viewport.push_input(event, true)


func _new_level() -> Node:
	for frame in 20:
		var level: Node = _app.get_current_level()
		if level != null:
			return level
		await wait_process_frames(1)
	return null


func test_actual_project_entry_waits_for_play_without_starting_combat() -> void:
	# Cargar la entrada configurada, sin sustituirla por la raíz deseada.
	var entry := load(ProjectSettings.get_setting("application/run/main_scene")) as PackedScene
	await _mount(entry)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.MENU, "La apertura real espera en MENU")
	assert_eq(_soldiers(_app).size(), 0, "No existe una partida escondida detrás de la apertura")
	assert_true(_enemies(_app).is_empty(), "No se monta un pool de enemigos detrás del menú")
	assert_true(_wave_events.is_empty(), "La entrada real no inicia oleadas antes de Jugar")
	var play := _button("Jugar")
	assert_not_null(play, "La apertura ofrece la acción explícita Jugar")
	if play != null:
		assert_true(play.is_visible_in_tree())


func test_menu_background_and_wait_do_not_start_waves_or_change_reserve() -> void:
	EconomyManager.collected_ammo = 23
	await _mount()
	_click(Vector2(12, 12))
	await wait_process_frames(4)
	assert_null(_app.get_current_level())
	assert_eq(_soldiers(_app).size(), 0)
	assert_true(_enemies(_app).is_empty())
	assert_true(_wave_events.is_empty())
	assert_eq(EconomyManager.collected_ammo, 23, "Esperar o pulsar fondo no mueve economía")
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.MENU)


func test_repeated_start_requests_create_one_real_match_with_initial_conditions() -> void:
	await _mount()
	EconomyManager.collected_ammo = 41
	for repeat in 4:
		_app.request_start()
	var level: Node = await _new_level()
	assert_not_null(level, "Una intención de inicio monta una partida")
	if level == null:
		return
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING)
	assert_eq(EconomyManager.collected_ammo, 0)
	assert_eq(_soldiers(level).size(), 5)
	var initial: Array[Enemigo] = []
	for enemy: Enemigo in _enemies(level):
		if enemy.is_targetable() and enemy.spawn_origin == Enemigo.SpawnOrigin.INITIAL:
			initial.append(enemy)
	assert_eq(initial.size(), 1, "Un único atacante inicial, separado de las bajas WAVE")
	if initial.size() == 1:
		assert_eq(initial[0].lane_id, 2, "El atacante inicial conserva la fila central")
	var wave_population := 0
	for wave: WaveData in WaveManager.waves:
		for entry: WaveSpawnEntry in wave.spawn_entries:
			wave_population += entry.count
	assert_eq(wave_population, 99, "El inicio usa las oleadas vigentes de producción")
	var board: BoardManager = level.get("_board_manager")
	for home: Vector2i in BOARD.home_cells:
		var owner := board.get_occupant(home) as Soldado
		assert_not_null(owner, "La plaza inicial tiene un dueño real")
		if owner != null:
			assert_eq(owner._current_health, owner.stats.max_health)
			assert_eq(owner._current_ammo, owner.stats.max_ammo)
			assert_eq(owner._current_morale, 0.0)
	assert_eq(_wave_events, [1], "Las activaciones repetidas no duplican el inicio de oleadas")
	_app.request_start()
	await wait_process_frames(2)
	assert_same(_app.get_current_level(), level, "Jugar durante PLAYING no reemplaza ni duplica el intento")
	assert_eq(_wave_events, [1])


func test_real_play_click_burst_starts_once_and_does_not_reach_gameplay_input() -> void:
	var observer := GestureObserver.new()
	_viewport.add_child(observer)
	_click(Vector2(12, 12))
	assert_eq(observer.presses, 1, "Precondición: el observador detecta un gesto sin UI")
	observer.presses = 0
	await _mount()
	var play := _button("Jugar")
	assert_not_null(play)
	if play == null:
		return
	# Va después de la app: observa input no consumido antes del nivel.
	_viewport.move_child(observer, _viewport.get_child_count() - 1)
	var button_activations: Array[bool] = []
	play.pressed.connect(func(): button_activations.append(true))
	var position := play.get_global_rect().get_center()
	for repeat in 3:
		_click(position)
	var level: Node = await _new_level()
	assert_gt(button_activations.size(), 0, "Precondición: el dispatch alcanzó Jugar")
	assert_not_null(level, "El Button real, a través del Viewport, inicia el intento")
	assert_eq(observer.presses, 0, "El gesto de Jugar no llega a entrada de gameplay")
	assert_eq(_wave_events, [1], "Una ráfaga de activaciones acepta un solo inicio")
	if level != null:
		assert_eq(EconomyManager.collected_ammo, 0)
		assert_null(level.get("_hud").get_selected_soldier(), "El gesto no selecciona además una trinchera")
