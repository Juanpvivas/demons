extends GutTest
## 007/T005: entrada real y transición de inicio. Los niveles son reales;
## SubViewport evita mezclar coordenadas locales con el stretch del Window.
const ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const BOARD := preload("res://resources/levels/monte_calvo_board.tres")
const RETRY_LEVEL := preload("res://tests/unit/game/fixtures/OneWaveLevel.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/EnemigoBase.tscn")
const PICKUP_SCENE := preload("res://scenes/levels/AmmoPickup.tscn")
const INTRO_SCENE := preload("res://scenes/ui/IntroPlayer.tscn")
var _viewport: SubViewport
var _app: Node
var _saved_state: int
var _saved_ammo: int
var _saved_waves: Dictionary
var _wave_events: Array[int] = []
var _intro_path: String


class MemoryIntroProgress:
	extends RefCounted
	var seen := true
	var writes := 0
	var fail_save := false
	func has_seen(_version: String) -> bool:
		return seen
	func mark_seen(_version: String) -> Error:
		writes += 1
		if fail_save:
			return ERR_CANT_CREATE
		seen = true
		return OK


class GestureObserver:
	extends Node
	var presses := 0
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			presses += 1


func before_each() -> void:
	_intro_path = OS.get_temp_dir().path_join("demons_intro_root_%s.cfg" % str(Time.get_ticks_usec()))
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
	if FileAccess.file_exists(_intro_path):
		DirAccess.remove_absolute(_intro_path)
	WaveManager.wave_started.disconnect(_on_wave_started)
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _on_wave_started(number: int) -> void:
	_wave_events.append(number)


func _mount(scene: PackedScene = ROOT_SCENE, level_override: PackedScene = null,
		progress: RefCounted = null) -> void:
	_app = scene.instantiate()
	# Las pruebas históricas007 parten del recuerdo ya visto; la nueva US2
	# inyecta explícitamente un perfil nuevo sin usar preferencias reales.
	_app.set("intro_progress", progress if progress != null else MemoryIntroProgress.new())
	_app.set("intro_scene", INTRO_SCENE)
	_app.set("intro_sequence", _intro_sequence())
	if level_override != null:
		_app.set("level_scene", level_override)
	_viewport.add_child(_app)
	await wait_process_frames(2)


func _intro_sequence() -> IntroSequence:
	var sequence := IntroSequence.new()
	sequence.version = "la_carta_test_v1"
	sequence.transition_duration = 0.0
	for text: String in ["Primera escena", "Última escena"]:
		var slide := IntroSlide.new()
		slide.subtitle = text
		slide.minimum_duration = 0.2
		sequence.slides.append(slide)
	return sequence


func _button(text: String) -> Button:
	var fallback: Button
	for node: Node in _app.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			if (node as Button).is_visible_in_tree():
				return node as Button
			if fallback == null:
				fallback = node as Button
	return fallback


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
	# Capturar el constructor antes de la nueva bala enemiga del primer tick.
	var births: Dictionary = {}
	var capture := func(node: Node):
		if node is Soldado and _app.is_ancestor_of(node):
			node.ready.connect(func(): births[node.get_instance_id()] = node.get_reload_state(), CONNECT_ONE_SHOT)
	get_tree().node_added.connect(capture)
	EconomyManager.collected_ammo = 41
	for repeat in 4:
		_app.request_start()
	var level: Node = await _new_level()
	get_tree().node_added.disconnect(capture)
	assert_eq(births.size(), 5, "Cinco estados iniciales capturados antes de combate")
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
			assert_eq(births[owner.get_instance_id()].health, owner.stats.max_health)
			assert_eq(births[owner.get_instance_id()].ammo, owner.stats.max_ammo)
			assert_eq(births[owner.get_instance_id()].morale, 0.0)
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


func test_r2_menu_request_from_playing_or_paused_closes_the_attempt(
		paused = use_parameters([false, true])) -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	if paused:
		GameStateManager._current_state = GameStateManager.GameState.PAUSED
		GameStateManager.game_state_changed.emit(GameStateManager.GameState.PAUSED)
	var previous: WeakRef = weakref(level)
	var old_objects := _weak_tree(level)
	var callbacks := _navigation_callbacks(level)
	_app.request_menu()
	_app.request_menu()
	if not await _assert_returned_menu(previous, old_objects, 1):
		return
	_app.request_start()
	var next: Node = await _new_level()
	assert_not_null(next, "Jugar después del retorno crea una partida limpia")
	if next == null:
		return
	await _assert_clean_retry(next, old_objects)
	for callback: Callable in callbacks:
		callback.call()
	await wait_process_frames(2)
	assert_same(_app.get_current_level(), next, "Ninguna intención vieja cierra el intento nuevo")


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


## 013/T004–T005: navegación narrativa con secuencia breve y perfiles aislados.
func _fresh_intro(progress: RefCounted) -> Node:
	await _mount(ROOT_SCENE, RETRY_LEVEL, progress)
	_app.request_start()
	await wait_process_frames(2)
	var intro: Node = _app.get_current_intro()
	assert_not_null(intro, "El primer Jugar abre la carta antes de montar combate")
	if intro != null:
		intro.set_process(false)
	return intro


func _finish_intro(intro: Node, skipped: bool) -> void:
	if skipped:
		intro.skip_intro()
	else:
		for step in 30:
			intro.advance_intro(0.1)
	await wait_process_frames(2)


func test_first_start_waits_in_intro_without_any_level_or_wave() -> void:
	var progress := MemoryIntroProgress.new()
	progress.seen = false
	var intro: Node = await _fresh_intro(progress)
	if intro == null:
		return
	for repeat in 3:
		_app.request_start()
		_app.request_intro()
		_app.request_intro_start() # No existe un Comenzar válido durante la carta.
	await wait_process_frames(2)
	assert_same(_app.get_current_intro(), intro, "Reentrada no sustituye la carta actual")
	assert_eq(intro.get_slide_index(), 0)
	assert_null(_app.get_current_level())
	assert_true(_soldiers(_app).is_empty())
	assert_true(_enemies(_app).is_empty())
	assert_true(_wave_events.is_empty())
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.MENU)
	assert_eq(progress.writes, 0, "Abrir no cuenta como completar")


func test_intro_finish_or_skip_waits_for_a_fresh_start_click(
		skipped = use_parameters([false, true])) -> void:
	var progress := MemoryIntroProgress.new()
	progress.seen = false
	var intro: Node = await _fresh_intro(progress)
	if intro == null:
		return
	if skipped:
		var omit := _button("Omitir")
		assert_not_null(omit, "Control positivo: omisión por un gesto real")
		if omit == null:
			return
		_click(omit.get_global_rect().get_center())
		await wait_process_frames(2)
	else:
		await _finish_intro(intro, false)
	_assert_r3_prompt_is_the_only_visible_action(intro)
	assert_null(_app.get_current_level(), "Finalizar u omitir no inicia combate")
	assert_eq(progress.writes, 1, "Final/omisión se registra una vez")
	assert_true(progress.seen)
	var start := _button("Comenzar")
	assert_not_null(start)
	if start == null:
		return
	assert_true(start.is_visible_in_tree())
	var observer := GestureObserver.new()
	_viewport.add_child(observer)
	for repeat in 3:
		_click(start.get_global_rect().get_center())
	var level: Node = await _new_level()
	assert_not_null(level, "Comenzar acepta un gesto nuevo")
	assert_eq(_wave_events, [1], "Ráfaga de Comenzar crea una partida")
	assert_eq(observer.presses, 0, "El gesto no atraviesa al tablero")


func test_persisted_finish_skips_intro_after_a_new_root_instance() -> void:
	var progress := IntroProgress.new()
	progress.storage_path = _intro_path
	var intro: Node = await _fresh_intro(progress)
	if intro == null:
		return
	await _finish_intro(intro, true)
	_app.queue_free()
	await wait_process_frames(2)
	var reopened := IntroProgress.new()
	reopened.storage_path = _intro_path
	await _mount(ROOT_SCENE, RETRY_LEVEL, reopened)
	_app.request_start()
	var level: Node = await _new_level()
	assert_not_null(level, "Recuerdo real persiste entre raíces nuevas")
	assert_null(_app.get_current_intro())


func test_save_failure_still_offers_start_without_false_seen_record() -> void:
	var progress := MemoryIntroProgress.new()
	progress.seen = false
	progress.fail_save = true
	var intro: Node = await _fresh_intro(progress)
	if intro == null:
		return
	await _finish_intro(intro, true)
	assert_eq(progress.writes, 1)
	assert_false(progress.seen)
	assert_null(_app.get_current_level())
	assert_not_null(_button("Comenzar"), "Fallo de escritura no bloquea jugar")
	_app.request_intro_start()
	assert_not_null(await _new_level())


func test_closing_an_unfinished_intro_does_not_mark_it_seen() -> void:
	var progress := MemoryIntroProgress.new()
	progress.seen = false
	var intro: Node = await _fresh_intro(progress)
	if intro == null:
		return
	intro.close_intro()
	intro.advance_intro(50.0)
	assert_eq(progress.writes, 0)
	assert_false(progress.seen)
	assert_null(_app.get_current_level())


func test_r2_replay_always_opens_at_first_scene_and_waits_for_start(
		skipped = use_parameters([false, true])) -> void:
	await _mount(ROOT_SCENE, RETRY_LEVEL)
	var replay := _button("Ver introducción")
	assert_not_null(replay, "La historia sigue disponible en el menú")
	if replay == null:
		return
	_click(replay.get_global_rect().get_center())
	await wait_process_frames(2)
	var intro: Node = _app.get_current_intro()
	assert_not_null(intro)
	if intro == null:
		return
	intro.set_process(false)
	assert_eq(intro.get_slide_index(), 0)
	assert_null(_app.get_current_level())
	if skipped:
		var omit := _button("Omitir")
		assert_not_null(omit, "Control positivo: omisión por un gesto real")
		if omit == null:
			return
		_click(omit.get_global_rect().get_center())
		await wait_process_frames(2)
	else:
		await _finish_intro(intro, false)
	_assert_r3_prompt_is_the_only_visible_action(intro)
	assert_true(is_instance_valid(intro) and _app.get_current_intro() == intro,
		"Replay espera Comenzar en su propia pantalla")
	assert_null(_app.get_current_level())
	assert_true(_wave_events.is_empty())
	assert_false(_button("Jugar").is_visible_in_tree(), "No se vuelve automáticamente al menú")
	var start := _button("Comenzar")
	assert_not_null(start)
	if start == null:
		return
	assert_true(start.is_visible_in_tree())
	var observer := GestureObserver.new()
	_viewport.add_child(observer)
	for repeat in 3:
		_click(start.get_global_rect().get_center())
	assert_not_null(await _new_level())
	assert_eq(_wave_events, [1], "Sólo un gesto nuevo inicia la partida desde replay")
	assert_eq(observer.presses, 0, "Comenzar no atraviesa al tablero")


func test_retired_intro_callbacks_cannot_end_or_start_a_new_replay() -> void:
	await _mount(ROOT_SCENE, RETRY_LEVEL)
	_app.request_intro()
	await wait_process_frames(2)
	var first: Node = _app.get_current_intro()
	assert_not_null(first)
	if first == null:
		return
	var old_callbacks: Array[Callable] = []
	for connection: Dictionary in first.get_signal_connection_list("finished"):
		if connection.callable.get_object() == _app:
			old_callbacks.append(connection.callable)
	assert_false(old_callbacks.is_empty(), "Control: salida vigente conectada a la raíz")
	await _finish_intro(first, true)
	# R2: la repetición terminada espera Comenzar; volver luego desde partida.
	_app.request_intro_start()
	var level: Node = await _new_level()
	assert_not_null(level)
	if level == null:
		return
	if not await _real_result(level, "won"):
		return
	_app.request_menu()
	assert_true(await _wait_menu())
	_app.request_intro()
	await wait_process_frames(2)
	var second: Node = _app.get_current_intro()
	assert_not_null(second)
	if second == null:
		return
	for callback: Callable in old_callbacks:
		callback.call(true)
	_app.request_intro_start()
	await wait_process_frames(2)
	assert_same(_app.get_current_intro(), second, "Aviso retirado no cierra la reproducción nueva")
	assert_null(_app.get_current_level(), "Comenzar antes del final de la carta se rechaza")


func test_r2_real_active_menu_button_closes_every_level_object_and_consumes_input(
		paused = use_parameters([false, true])) -> void:
	var level: Node = await _start_retry_fixture()
	if level == null:
		return
	if paused:
		GameStateManager._current_state = GameStateManager.GameState.PAUSED
		GameStateManager.game_state_changed.emit(GameStateManager.GameState.PAUSED)
	await wait_process_frames(2)
	var menu := _button("Menú principal")
	assert_true(menu != null and menu.is_visible_in_tree(), "El nivel ofrece Menú principal durante la partida")
	if menu == null or not menu.is_visible_in_tree():
		return
	# Audio real de fixture, además de actores/pools/timers: no debe sobrevivir.
	var sound := AudioStreamPlayer.new()
	sound.stream = load("res://assets/audio/narrative/la_carta/narracion_01.wav")
	level.add_child(sound)
	sound.play()
	assert_true(sound.playing, "Control: existe audio del intento por cerrar")
	var old_objects := _weak_tree(level)
	var previous: WeakRef = weakref(level)
	var observer := GestureObserver.new()
	_viewport.add_child(observer)
	var position := menu.get_global_rect().get_center()
	for repeat in 3:
		_click(position)
	if not await _assert_returned_menu(previous, old_objects, 1):
		return
	assert_eq(observer.presses, 0, "El gesto de salir no alcanza input del tablero")
	_app.request_start()
	var next: Node = await _new_level()
	assert_not_null(next)
	if next != null:
		assert_eq(_soldiers(next).size(), 5)
		assert_eq(_wave_events, [1, 1], "Una única partida nueva después de cerrar")


func _assert_r3_prompt_is_the_only_visible_action(intro: Node) -> void:
	var texts: Array[String] = []
	var actions: Array[String] = []
	for node: Node in intro.find_children("*", "Label", true, false):
		if (node as Label).is_visible_in_tree() and not (node as Label).text.is_empty():
			texts.append((node as Label).text)
	for node: Node in intro.find_children("*", "Button", true, false):
		if (node as Button).is_visible_in_tree():
			actions.append((node as Button).text)
	assert_eq(texts, [], "Ambas rutas cierran sin título, ficción ni subtítulo")
	assert_eq(actions, ["Comenzar"], "Sólo queda la acción explícita de inicio")
	for node: Node in intro.find_children("*", "AudioStreamPlayer", true, false):
		assert_false((node as AudioStreamPlayer).playing, "La espera no mantiene sonido residual")
	assert_null(_app.get_current_level(), "Sin nivel antes del gesto nuevo")
	assert_true(_wave_events.is_empty(), "Sin oleadas antes del gesto nuevo")
