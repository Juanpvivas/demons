extends GutTest
## 007/T005: entrada real y transición de inicio. Los niveles son reales;
## SubViewport evita mezclar coordenadas locales con el stretch del Window.
const ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const BOARD := preload("res://resources/levels/monte_calvo_board.tres")
const RETRY_LEVEL := preload("res://tests/unit/game/fixtures/OneWaveLevel.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/EnemigoBase.tscn")
const PICKUP_SCENE := preload("res://scenes/levels/AmmoPickup.tscn")
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


func _mount(scene: PackedScene = ROOT_SCENE, level_override: PackedScene = null) -> void:
	_app = scene.instantiate()
	if level_override != null:
		_app.set("level_scene", level_override)
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


## 007/T011: fixture reducido con nivel, actores, física y Managers reales.
## No acredita una victoria manual de los cien enemigos de producción.
func _start_retry_fixture() -> Node:
	await _mount(ROOT_SCENE, RETRY_LEVEL)
	_app.request_start()
	var level: Node = await _new_level()
	assert_not_null(level, "Control US1: la raíz monta el nivel real inyectado")
	return level


func _active_wave_enemies(level: Node) -> Array[Enemigo]:
	var result: Array[Enemigo] = []
	for enemy: Enemigo in _enemies(level):
		if enemy.is_targetable() and enemy.spawn_origin == Enemigo.SpawnOrigin.WAVE:
			result.append(enemy)
	return result


func _real_result(level: Node, outcome: String) -> bool:
	if outcome == "won":
		for frame in 60:
			if not _active_wave_enemies(level).is_empty():
				break
			await wait_physics_frames(1)
		var enemies := _active_wave_enemies(level)
		assert_eq(enemies.size(), 1, "Control: la oleada real produjo un WAVE")
		if enemies.size() != 1:
			return false
		enemies[0].take_damage(enemies[0].stats.max_health)
	else:
		var board: BoardManager = level.get("_board_manager")
		var defender := board.get_occupant(BOARD.home_cells[0]) as Soldado
		assert_not_null(defender, "Control: existe el defensor que deja libre el carril")
		if defender == null:
			return false
		defender.take_damage(defender.stats.max_health)
		var breach := ENEMY_SCENE.instantiate() as Enemigo
		breach.stats = breach.stats.duplicate()
		breach.stats.move_speed = 240.0
		breach.position = Vector2(144, 144)
		level.add_child(breach)
		breach.prepare_for_spawn(breach.stats, breach.position, 0, Enemigo.SpawnOrigin.WAVE)
	for frame in 90:
		if GameStateManager._current_state != GameStateManager.GameState.PLAYING:
			break
		await wait_physics_frames(1)
	var expected: int = GameStateManager.GameState.WON if outcome == "won" else GameStateManager.GameState.LOST
	assert_eq(GameStateManager._current_state, expected, "Control: resultado por baja WAVE o cruce físico")
	# La resolución es síncrona; Containers ordena el panel recién visible
	# al procesar frames. No tomar un centro provisional como gesto de UI.
	await wait_process_frames(2)
	return GameStateManager._current_state == expected


func _dirty_attempt(level: Node) -> void:
	EconomyManager.add_ammo(31)
	var board: BoardManager = level.get("_board_manager")
	var owner := board.get_occupant(BOARD.home_cells[1]) as Soldado
	assert_true(level.select_trench(BOARD.home_cells[1]))
	owner.take_damage(1)
	owner.set("_current_ammo", 0)
	owner.set("_current_morale", 7.0)
	owner.global_position += Vector2(192, 0)
	assert_true(level.request_selected_reload(owner.get_instance_id()), "Control: queda una orden real de regreso")
	assert_eq(owner.get_reload_state().movement_state, Soldado.MovementState.RETURNING)
	var fallen := board.get_occupant(BOARD.home_cells[4]) as Soldado
	fallen.take_damage(fallen.stats.max_health)
	var pickup := PICKUP_SCENE.instantiate() as AmmoPickup
	pickup.amount = 7
	(level.get("_wave_spawner") as Node).get("_enemy_pool").add_child(pickup)


func _weak_tree(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children():
		result.append_array(_weak_tree(child))
	return result


func _replacement(previous: Node) -> Node:
	for frame in 30:
		var level: Node = _app.get_current_level()
		if level != null and level != previous:
			return level
		await wait_process_frames(1)
	return null


func _assert_clean_retry(level: Node, old_objects: Array[WeakRef]) -> void:
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING)
	assert_eq(EconomyManager.collected_ammo, 0)
	assert_null(level.get_selected_soldier())
	assert_eq(_soldiers(level).size(), 5)
	var board: BoardManager = level.get("_board_manager")
	for home: Vector2i in BOARD.home_cells:
		var owner := board.get_occupant(home) as Soldado
		assert_not_null(owner)
		if owner != null:
			assert_eq(owner._current_health, owner.stats.max_health)
			assert_eq(owner._current_ammo, owner.stats.max_ammo)
			assert_eq(owner._current_morale, 0.0)
			assert_eq(owner.global_position, Vector2(home) * 96.0 + Vector2(48, 48))
			assert_eq(owner.get_reload_state().movement_state, Soldado.MovementState.HOME)
	var initials := _enemies(level).filter(func(enemy: Enemigo):
		return enemy.is_targetable() and enemy.spawn_origin == Enemigo.SpawnOrigin.INITIAL)
	assert_eq(initials.size(), 1, "Retry conserva un único atacante inicial")
	if initials.size() == 1:
		assert_eq(initials[0].lane_id, 2)
	var old_alive := 0
	for reference: WeakRef in old_objects:
		if reference.get_ref() != null:
			old_alive += 1
	assert_eq(old_alive, 0, "No quedan actores, cajas, efectos, timers o HUD del intento anterior")
	for node: Node in level.find_children("*", "Area2D", true, false):
		assert_false(node is AmmoPickup, "No se heredan cajas")
	for frame in 60:
		if not _active_wave_enemies(level).is_empty():
			break
		await wait_physics_frames(1)
	var enemies := _active_wave_enemies(level)
	assert_eq(enemies.size(), 1)
	if enemies.size() == 1:
		assert_eq(enemies[0].lane_id, 0, "El cursor de WAVE vuelve a fila1")


func test_three_retries_from_real_results_release_before_new_waves_and_reset_every_attempt(
		outcome = use_parameters(["won", "lost"])) -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	for cycle in 3:
		_dirty_attempt(level)
		if not await _real_result(level, outcome):
			return
		var previous := level
		var old_objects := _weak_tree(previous)
		var previous_ref: WeakRef = weakref(previous)
		var old_live_at_new_wave: Array[bool] = []
		var on_new_wave := func(_number: int): old_live_at_new_wave.append(previous_ref.get_ref() != null)
		WaveManager.wave_started.connect(on_new_wave)
		for repeat in 4:
			_app.request_retry()
		level = await _replacement(previous)
		WaveManager.wave_started.disconnect(on_new_wave)
		assert_false(is_instance_valid(previous), "El intento retirado se libera efectivamente")
		assert_eq(old_live_at_new_wave, [false], "La liberación efectiva precede al nuevo wave_started")
		assert_not_null(level, "Retry desde " + outcome + " crea otro intento sin reabrir")
		if level == null:
			return
		await _assert_clean_retry(level, old_objects)
		assert_eq(_wave_events.size(), cycle + 2, "Una sola nueva secuencia por retry aceptado")


func test_retry_during_playing_does_not_replace_a_live_attempt() -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	_app.request_retry()
	await wait_process_frames(2)
	assert_same(_app.get_current_level(), level)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING)
	assert_eq(_wave_events, [1])


func test_retired_level_callback_cannot_retry_the_next_terminal_attempt() -> void:
	var first: Node = await _start_retry_fixture()
	if first == null or not await _real_result(first, "won"):
		return
	var old_callbacks: Array[Callable] = []
	for connection: Dictionary in first.get_signal_connection_list("retry_requested"):
		if connection.callable.get_object() == _app:
			old_callbacks.append(connection.callable)
	assert_false(old_callbacks.is_empty(), "La intención del nivel actual tiene un receptor de navegación")
	_app.request_retry()
	var current: Node = await _replacement(first)
	assert_not_null(current)
	if current == null:
		return
	if not await _real_result(current, "won"):
		return
	var waves_before := _wave_events.size()
	for callback: Callable in old_callbacks:
		callback.call() # Reproduce una entrega diferida capturada antes de retirar el origen.
	await wait_process_frames(3)
	assert_same(_app.get_current_level(), current, "Un origen retirado no acepta otra transición")
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON)
	assert_eq(_wave_events.size(), waves_before)


func test_real_retry_button_burst_accepts_once_and_consumes_the_gesture(
		outcome = use_parameters(["won", "lost"])) -> void:
	var previous: Node = await _start_retry_fixture()
	if previous == null or not await _real_result(previous, outcome):
		return
	var retry := _button("Volver a jugar")
	assert_not_null(retry)
	if retry == null:
		return
	var native: Array[bool] = []
	retry.pressed.connect(func(): native.append(true))
	var observer := GestureObserver.new()
	_viewport.add_child(observer)
	var position := retry.get_global_rect().get_center()
	for repeat in 3:
		_click(position)
	var current: Node = await _replacement(previous)
	assert_gt(native.size(), 0, "Control: el gesto activó el Button terminal real")
	assert_not_null(current, "La intención del HUD llega a la raíz")
	assert_eq(observer.presses, 0, "El gesto terminal no alcanza el tablero nuevo")
	if current != null:
		assert_eq(_wave_events, [1, 1])
		assert_null(current.get_selected_soldier())
		assert_eq(EconomyManager.collected_ammo, 0)


## 007/T017: mismo fixture reducido; el destino menú no instancia combate.
func _wait_menu() -> bool:
	for frame in 30:
		var play := _button("Jugar")
		if _app.get_current_level() == null \
				and GameStateManager._current_state == GameStateManager.GameState.MENU \
				and play != null and play.is_visible_in_tree() and not play.disabled:
			return true
		await wait_process_frames(1)
	return false


func _assert_returned_menu(previous: WeakRef, old_objects: Array[WeakRef], waves_before: int) -> bool:
	var arrived := await _wait_menu()
	assert_true(arrived, "Menú principal vuelve a la apertura sin iniciar otro intento")
	assert_null(_app.get_current_level(), "El menú no conserva un nivel terminado detrás")
	assert_null(previous.get_ref(), "El destino espera la liberación efectiva del intento")
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.MENU)
	assert_eq(_wave_events.size(), waves_before, "Volver al menú no emite un nuevo wave_started")
	if not arrived:
		return false
	var alive := 0
	for reference: WeakRef in old_objects:
		if reference.get_ref() != null:
			alive += 1
	assert_eq(alive, 0, "El menú no retiene actores, cajas, efectos, HUD o timers anteriores")
	assert_true(_soldiers(_app).is_empty())
	assert_true(_enemies(_app).is_empty())
	assert_same(_viewport.gui_get_focus_owner(), _button("Jugar"), "El regreso recupera el foco inicial")
	assert_true(WaveManager.waves.is_empty())
	assert_eq(WaveManager.current_wave_index, -1)
	return true


func _navigation_callbacks(level: Node) -> Array[Callable]:
	var callbacks: Array[Callable] = []
	for signal_name: String in ["retry_requested", "menu_requested"]:
		for connection: Dictionary in level.get_signal_connection_list(signal_name):
			if connection.callable.get_object() == _app:
				callbacks.append(connection.callable)
	return callbacks


func test_return_from_each_real_result_waits_in_menu_and_starts_clean_three_times(
		outcome = use_parameters(["won", "lost"])) -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	watch_signals(GameStateManager)
	for cycle in 3:
		_dirty_attempt(level)
		if not await _real_result(level, outcome):
			return
		var previous: WeakRef = weakref(level)
		var old_objects := _weak_tree(level)
		var callbacks := _navigation_callbacks(level)
		assert_eq(callbacks.size(), 2, "Control: ambas intenciones actuales llegan a la raíz")
		var waves_before := _wave_events.size()
		for repeat in 4:
			_app.request_menu()
		if not await _assert_returned_menu(previous, old_objects, waves_before):
			return
		var reserve_in_menu: int = EconomyManager.collected_ammo
		# El historial incluye los resultados legítimos anteriores; sólo esta
		# ventana inerte debe añadir cero resultados nuevos.
		var wins_before: int = get_signal_emit_count(GameStateManager, "game_won")
		var losses_before: int = get_signal_emit_count(GameStateManager, "game_lost")
		_click(Vector2(12, 12))
		for callback: Callable in callbacks:
			callback.call() # Entrega tardía que se capturó cuando el origen era vigente.
		WaveManager.notify_enemy_defeated()
		GameStateManager.report_reached_defended_position()
		await wait_process_frames(4)
		assert_null(_app.get_current_level(), "Ni fondo ni avisos tardíos abren una partida")
		assert_eq(GameStateManager._current_state, GameStateManager.GameState.MENU)
		assert_eq(EconomyManager.collected_ammo, reserve_in_menu, "Esperar en menú no mueve recursos")
		assert_eq(_wave_events.size(), waves_before)
		assert_eq(get_signal_emit_count(GameStateManager, "game_won"), wins_before, "El menú no añade victorias tardías")
		assert_eq(get_signal_emit_count(GameStateManager, "game_lost"), losses_before, "El menú no añade derrotas tardías")
		var play := _button("Jugar")
		var native: Array[bool] = []
		play.pressed.connect(func(): native.append(true), CONNECT_ONE_SHOT)
		var position := play.get_global_rect().get_center()
		for repeat in 3:
			_click(position)
		level = await _new_level()
		assert_eq(native.size(), 1, "Control: el Button Jugar real recibió la activación")
		assert_not_null(level, "Jugar desde el menú retornado monta un único intento")
		if level == null:
			return
		await _assert_clean_retry(level, old_objects)
		assert_eq(_wave_events.size(), waves_before + 1)


func test_menu_request_during_playing_keeps_the_live_attempt() -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	_app.request_menu()
	await wait_process_frames(3)
	assert_same(_app.get_current_level(), level, "No se añade salida durante combate")
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING)
	assert_false(_button("Jugar").is_visible_in_tree())
	assert_eq(_wave_events, [1])


func test_alternating_result_buttons_keep_the_first_accepted_destination(
		scenario = use_parameters(["won/menu", "lost/menu", "won/retry", "lost/retry"])) -> void:
	var parts: PackedStringArray = scenario.split("/")
	var previous: Node = await _start_retry_fixture()
	if previous == null or not await _real_result(previous, parts[0]):
		return
	var menu := _button("Menú principal")
	var retry := _button("Volver a jugar")
	assert_true(menu.is_visible_in_tree() and not menu.disabled)
	assert_true(retry.is_visible_in_tree() and not retry.disabled)
	var first := menu if parts[1] == "menu" else retry
	var second := retry if parts[1] == "menu" else menu
	var native: Array[bool] = []
	first.pressed.connect(func(): native.append(true))
	var observer := GestureObserver.new()
	_viewport.add_child(observer)
	var first_position := first.get_global_rect().get_center()
	var second_position := second.get_global_rect().get_center()
	var previous_ref: WeakRef = weakref(previous)
	var old_objects := _weak_tree(previous)
	_click(first_position)
	_click(second_position)
	_click(first_position)
	assert_gt(native.size(), 0, "Control: se activó el primer Button real antes de alternar")
	if parts[1] == "menu":
		await _assert_returned_menu(previous_ref, old_objects, 1)
	else:
		var current: Node = await _replacement(previous)
		assert_not_null(current, "La primera acción Retry prevalece frente a Menú")
		if current != null:
			await _assert_clean_retry(current, old_objects)
			assert_eq(_wave_events, [1, 1], "La alternancia acepta una sola partida")
	assert_eq(observer.presses, 0, "Ningún gesto terminal atraviesa al tablero")


func test_callbacks_retired_via_menu_cannot_navigate_a_new_terminal_attempt() -> void:
	var first: Node = await _start_retry_fixture()
	if first == null or not await _real_result(first, "won"):
		return
	var callbacks := _navigation_callbacks(first)
	assert_eq(callbacks.size(), 2, "Control: se capturan ambos receptores de la generación vigente")
	var old_objects := _weak_tree(first)
	var previous_ref: WeakRef = weakref(first)
	_app.request_menu()
	if not await _assert_returned_menu(previous_ref, old_objects, 1):
		return
	_click(_button("Jugar").get_global_rect().get_center())
	var current: Node = await _new_level()
	assert_not_null(current)
	if current == null or not await _real_result(current, "lost"):
		return
	var waves_before := _wave_events.size()
	for callback: Callable in callbacks:
		callback.call()
	await wait_process_frames(4)
	assert_same(_app.get_current_level(), current, "El resultado actual ignora las dos intenciones de un origen retirado")
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.LOST)
	assert_eq(_wave_events.size(), waves_before)
	assert_false(_button("Jugar").is_visible_in_tree())


## 010/T003: fixture reducido real; no acredita una victoria manual de producción.
func _rifle_effect_nodes_010(node: Node) -> Array[RifleShotVisualEffect]:
	var result: Array[RifleShotVisualEffect] = []
	for child: Node in node.get_children():
		if child is RifleShotVisualEffect:
			result.append(child as RifleShotVisualEffect)
		result.append_array(_rifle_effect_nodes_010(child))
	return result


func test_rifle_effects_winning_real_shot_is_requested_before_won_and_finishes_its_fade() -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	for frame in 60:
		if not _active_wave_enemies(level).is_empty():
			break
		await wait_physics_frames(1)
	var enemies := _active_wave_enemies(level)
	assert_eq(enemies.size(), 1, "Control: el spawner real produjo su único WAVE")
	if enemies.size() != 1:
		return
	var board: BoardManager = level.get("_board_manager")
	var soldier := board.get_occupant(BOARD.home_cells[0]) as Soldado
	var enemy := enemies[0]
	var stats := enemy.stats.duplicate() as EnemyStats
	stats.max_health = soldier.stats.damage_per_shot
	stats.move_speed = 0.0
	var target_at := soldier.global_position + Vector2(150, 0)
	# Reubicar el WAVE existente sólo acorta el fixture; muerte/resultado son reales.
	enemy.prepare_for_spawn(stats, target_at, 0, Enemigo.SpawnOrigin.WAVE)
	var ammo_before: int = soldier.get_reload_state().ammo
	var shots: Array[Dictionary] = []
	var states_at_request: Array[int] = []
	soldier.rifle_shot_visual_requested.connect(func(snapshot: Dictionary):
		shots.append(snapshot.duplicate(true))
		states_at_request.append(GameStateManager._current_state))
	for frame in 45:
		if GameStateManager._current_state == GameStateManager.GameState.WON:
			break
		await wait_physics_frames(1)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON)
	assert_eq(WaveManager._defeated_in_current_wave, 1)
	assert_eq(soldier.get_reload_state().ammo, ammo_before - 1)
	assert_eq(soldier.get_reload_state().morale, soldier.stats.moral_per_kill)
	assert_eq(shots.size(), 1, "El tiro ganador conserva una solicitud única")
	assert_eq(states_at_request, [GameStateManager.GameState.PLAYING], "La solicitud precede al daño que causa WON")
	if shots.size() == 1:
		assert_eq(shots[0].get("target_world"), target_at)
	var service: CombatVisualEffects = level.get("_combat_visual_effects")
	assert_eq(service.get_active_rifle_effect_count(), 1, "El terminal deja completar la ráfaga confirmada")
	service.request_rifle_shot({"origin_world": Vector2(200, 100), "target_world": Vector2(300, 100)})
	assert_eq(service.get_active_rifle_effect_count(), 1, "No acepta una segunda ráfaga después de WON")
	await get_tree().create_timer(0.40, true).timeout
	assert_eq(service.get_active_rifle_effect_count(), 0)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON)


func test_rifle_effects_retry_and_menu_clear_before_retiring_attempt(
		destination = use_parameters(["retry", "menu"])) -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	var service: CombatVisualEffects = level.get("_combat_visual_effects")
	service.request_rifle_shot({"origin_world": Vector2(194, 301), "target_world": Vector2(294, 336)})
	assert_eq(service.get_active_rifle_effect_count(), 1, "Control: el intento tiene un tiro activo")
	var effects := _rifle_effect_nodes_010(service)
	assert_gt(effects.size(), 0)
	var old_refs: Array[WeakRef] = [weakref(service)]
	for effect: RifleShotVisualEffect in effects:
		old_refs.append(weakref(effect))
	# Reporte público terminal; los recorridos de resultado por física se conservan arriba.
	GameStateManager.report_reached_defended_position()
	if destination == "retry":
		_app.request_retry()
	else:
		_app.request_menu()
	assert_eq(service.get_active_rifle_effect_count(), 0, "Limpia antes de retirar/deshabilitar el nivel")
	for effect: RifleShotVisualEffect in effects:
		assert_false(effect.visible)
		assert_true(effect.get_shot_snapshot().is_empty())
	service.request_rifle_shot({"origin_world": Vector2.ZERO, "target_world": Vector2.ONE})
	assert_eq(service.get_active_rifle_effect_count(), 0, "La solicitud tardía del intento anterior se rechaza")
	if destination == "retry":
		var replacement: Node = await _replacement(level)
		assert_not_null(replacement)
		if replacement != null:
			var current: CombatVisualEffects = replacement.get("_combat_visual_effects")
			assert_eq(current.get_active_rifle_effect_count(), 0)
			assert_eq(EconomyManager.collected_ammo, 0)
	else:
		assert_true(await _wait_menu())
	for reference: WeakRef in old_refs:
		assert_null(reference.get_ref(), "No se conservan pool, efectos ni callbacks del intento anterior")


func test_rifle_effects_level_close_cleans_even_without_menu_state_change() -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	var service: CombatVisualEffects = level.get("_combat_visual_effects")
	service.request_rifle_shot({"origin_world": Vector2(194, 301), "target_world": Vector2(294, 336)})
	assert_eq(service.get_active_rifle_effect_count(), 1)
	var effects := _rifle_effect_nodes_010(service)
	level.close_match()
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.PLAYING, "No depende del aviso MENU para limpiar")
	assert_eq(service.get_active_rifle_effect_count(), 0)
	for effect: RifleShotVisualEffect in effects:
		assert_false(effect.visible, "No se deshabilita un flash todavía visible")
	service.request_rifle_shot({"origin_world": Vector2.ZERO, "target_world": Vector2.ONE})
	assert_eq(service.get_active_rifle_effect_count(), 0)


func test_rifle_effects_new_deployment_uses_existing_level_registration_for_real_shot() -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	var board: BoardManager = level.get("_board_manager")
	var home: Vector2i = BOARD.home_cells[4]
	var previous := board.get_occupant(home) as Soldado
	previous.take_damage(previous.stats.max_health)
	assert_true(board.is_cell_free(home))
	EconomyManager.collected_ammo = previous.stats.deploy_ammo_cost
	# Misma entrada de despliegue que los fixtures headless existentes.
	level._try_deploy_soldado(home)
	var soldier := board.get_occupant(home) as Soldado
	assert_not_null(soldier)
	if soldier == null:
		return
	var enemy: Node2D = load("res://tests/unit/units/enemigo_double.gd").new()
	enemy.position = level.to_local(soldier.global_position + Vector2(150, 0))
	level.add_child(enemy)
	for frame in 30:
		if soldier.get_reload_state().ammo < soldier.stats.max_ammo:
			break
		await wait_physics_frames(1)
	assert_eq(soldier.get_reload_state().ammo, soldier.stats.max_ammo - 1)
	assert_eq(enemy.get("damage_received"), [soldier.stats.damage_per_shot], "Control: el nuevo defensor disparó realmente")
	var service: CombatVisualEffects = level.get("_combat_visual_effects")
	assert_eq(service.get_active_rifle_effect_count(), 1, "La ruta de despliegue conecta también la petición de fusil")
