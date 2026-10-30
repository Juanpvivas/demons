extends GutTest
## 007/T005: controles reales y dispatch de Viewport. No acredita toque SO,
## estilo pictórico ni los 60 s de menú que se comprobarán en T024.
const MENU_SCENE := preload("res://scenes/ui/MainMenu.tscn")
var _viewport: SubViewport
var _menu: Control
var _play: Button
var _intents := 0
var _button_activations := 0


func before_each() -> void:
	_intents = 0
	_button_activations = 0
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.handle_input_locally = true
	add_child_autofree(_viewport)
	_menu = MENU_SCENE.instantiate() as Control
	_viewport.add_child(_menu)
	_menu.play_requested.connect(func(): _intents += 1)
	for node: Node in _menu.find_children("*", "Button", true, false):
		if (node as Button).text == "Jugar":
			_play = node as Button
	if _play != null:
		_play.pressed.connect(func(): _button_activations += 1)
	await wait_process_frames(2)


func _click(position: Vector2) -> void:
	_viewport.notify_mouse_entered()
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


func test_opening_menu_focuses_the_visible_play_action() -> void:
	assert_not_null(_play)
	if _play == null:
		return
	assert_true(_play.is_visible_in_tree())
	assert_false(_play.disabled)
	assert_same(_viewport.gui_get_focus_owner(), _play, "Jugar recibe el foco al abrir el menú")


func test_mouse_activation_emits_one_intent_without_starting_a_match_itself() -> void:
	assert_not_null(_play)
	if _play == null:
		return
	var state: int = GameStateManager._current_state
	var ammo: int = EconomyManager.collected_ammo
	var wave: int = WaveManager.current_wave_index
	_click(_play.get_global_rect().get_center())
	await wait_process_frames(1)
	assert_eq(_button_activations, 1, "Precondición: el dispatch alcanzó Button.pressed")
	assert_eq(_intents, 1, "El clic real del Button emite play_requested una vez")
	assert_eq(GameStateManager._current_state, state, "UI expresa intención, no inicia Managers")
	assert_eq(EconomyManager.collected_ammo, ammo)
	assert_eq(WaveManager.current_wave_index, wave)


func test_keyboard_activation_emits_the_same_play_intent() -> void:
	assert_not_null(_play)
	if _play == null:
		return
	# Aislar la conexión de activación del oráculo separado de foco inicial.
	_play.grab_focus()
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = down
		_viewport.push_input(event, true)
	await wait_process_frames(1)
	assert_eq(_button_activations, 1, "Precondición: Enter activó el Button real")
	assert_eq(_intents, 1, "Enter sobre Jugar conserva la intención del ratón")


func test_background_click_does_not_request_play() -> void:
	_click(Vector2(8, 8))
	await wait_process_frames(2)
	assert_eq(_intents, 0, "Pulsar decoración no equivale a Jugar")


func _replay_button() -> Button:
	for node: Node in _menu.find_children("*", "Button", true, false):
		if (node as Button).text == "Ver introducción":
			return node as Button
	return null


func test_replay_button_requests_only_intro_and_disables_during_transition() -> void:
	var replay := _replay_button()
	assert_not_null(replay, "El menú permite volver a ver la carta")
	if replay == null:
		return
	watch_signals(_menu)
	_click(replay.get_global_rect().get_center())
	await wait_process_frames(1)
	assert_signal_emit_count(_menu, "intro_requested", 1)
	assert_eq(_intents, 0, "Ver introducción no equivale a Jugar")
	_menu.set_start_enabled(false)
	assert_true(replay.disabled, "Una transición bloquea ambas rutas")
	_menu.show_menu()
	assert_false(replay.disabled)
	assert_same(_viewport.gui_get_focus_owner(), _play)


func test_keyboard_can_request_replay_without_requesting_play() -> void:
	var replay := _replay_button()
	assert_not_null(replay)
	if replay == null:
		return
	watch_signals(_menu)
	replay.grab_focus()
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = down
		_viewport.push_input(event, true)
	await wait_process_frames(1)
	assert_signal_emit_count(_menu, "intro_requested", 1)
	assert_eq(_intents, 0)
