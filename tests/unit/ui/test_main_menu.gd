extends GutTest
## 007/T005: controles reales y dispatch de Viewport. No acredita toque SO,
## estilo pictórico ni los 60 s de menú que se comprobarán en T024.
const MENU_SCENE := preload("res://scenes/ui/MainMenu.tscn")
var _viewport: SubViewport
var _menu: Control
var _play: Button
var _intents := 0
var _button_activations := 0
## 017/I2 T043 (corrección de test T040): evita que una segunda llamada de
## `_click()` dentro del mismo test (confirmación con doble gesto, o
## clic->cancelar) vuelva a notificar "mouse entered" sin que el ratón haya
## salido realmente del viewport; el motor lo marca como advertencia y GUT
## lo cuenta como error inesperado, aunque la simulación sea válida.
var _mouse_entered_notified := false


func before_each() -> void:
	_intents = 0
	_button_activations = 0
	_mouse_entered_notified = false
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.handle_input_locally = true
	# 017/I2 T043 (corrección de test T040): el `ConfirmationDialog` del
	# borrado de memoria es un `Window`; sin embeberlo en este `SubViewport`
	# de prueba, `popup_centered()` no tiene dónde entregar los eventos de
	# `push_input()` simulados más abajo (confirmado por reproducción
	# aislada: con este flag en `false`, por defecto en un `SubViewport`
	# nuevo, el diálogo queda en el árbol pero nunca recibe el clic).
	_viewport.gui_embed_subwindows = true
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
	if not _mouse_entered_notified:
		_viewport.notify_mouse_entered()
		_mouse_entered_notified = true
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


## 017/I2 T043 (corrección de test T040): `get_global_rect()` de un control
## dentro del `ConfirmationDialog` es relativo al `Viewport` propio de ese
## `Window` embebido, no al `SubViewport` exterior donde `_click()` empuja
## los eventos; hace falta sumar la posición del `Window` embebido para
## apuntar al mismo punto de pantalla que vería un clic real. Confirmado por
## reproducción aislada: sin esta corrección, los botones "Cancelar"/"Borrar"
## del diálogo nunca reciben el evento simulado aunque existan y sean
## visibles.
func _click_control(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	var window := control.get_window()
	if window != null and window != _menu.get_window():
		position += Vector2(window.position)
	_click(position)


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


## 017/I2 T040: RED de la UI de borrado de memoria del comandante (contrato
## §6, US3). Hoy `MainMenu.tscn`/`main_menu.gd` no tienen ningún botón
## "Borrar memoria del comandante": la señal `commander_reset_requested`
## está declarada desde T027 pero nada la emite todavía (T042 pendiente).
## Las aserciones buscan los nodos por texto/identidad, nunca por posición o
## tamaño de píxel exacto (layout visual = T043/QA visual), según pide la
## tarea.
func _delete_button() -> Button:
	for node: Node in _menu.find_children("*", "Button", true, false):
		if (node as Button).text == "Borrar memoria del comandante":
			return node as Button
	return null


func _named_button(text: String) -> Button:
	for node: Node in _menu.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node as Button
	return null


## Búsqueda genérica de texto visible: cubre un Label/RichTextLabel hijo o el
## `dialog_text` de un AcceptDialog/Window, sin asumir qué estructura exacta
## tendrá el futuro diálogo de confirmación.
func _visible_texts() -> Array[String]:
	var texts: Array[String] = []
	for node: Node in _menu.find_children("*", "", true, false):
		if node is Label and (node as Label).is_visible_in_tree():
			texts.append((node as Label).text)
		elif node is RichTextLabel and (node as RichTextLabel).is_visible_in_tree():
			texts.append((node as RichTextLabel).get_parsed_text())
		elif node is AcceptDialog and (node as AcceptDialog).visible:
			texts.append((node as AcceptDialog).dialog_text)
	return texts


func _focus_neighbor(button: Button, down: bool) -> Node:
	var path: NodePath = button.focus_neighbor_bottom if down else button.focus_neighbor_top
	if path.is_empty():
		return null
	return button.get_node_or_null(path)


func test_delete_memory_button_exists_in_the_menu_vbox_with_minimum_touch_height() -> void:
	var delete_button := _delete_button()
	assert_not_null(delete_button,
		"Contrato §6: la VBox del menú debe ofrecer un botón real «Borrar memoria del comandante»; " +
		"hoy no existe ningún nodo con ese texto en MainMenu.tscn")
	if delete_button == null:
		return
	assert_true(delete_button.is_visible_in_tree())
	assert_false(delete_button.disabled)
	assert_gte(delete_button.custom_minimum_size.y, 64.0, "Altura táctil mínima de 64px (contrato §6)")
	assert_not_null(_play)
	if _play != null:
		assert_same(delete_button.get_parent(), _play.get_parent(),
			"El botón de borrado vive en la misma VBox que Jugar/Ver introducción")


func test_delete_memory_button_click_opens_confirmation_without_emitting_reset_yet() -> void:
	var delete_button := _delete_button()
	assert_not_null(delete_button, "Precondición del flujo: el botón de borrado debe existir")
	if delete_button == null:
		return
	watch_signals(_menu)
	_click(delete_button.get_global_rect().get_center())
	await wait_process_frames(2)
	assert_signal_emit_count(_menu, "commander_reset_requested", 0,
		"Un solo clic abre la confirmación local; no borra sin confirmar (contrato §6)")
	var texts := _visible_texts()
	assert_true(texts.has(
			"¿Borrar lo aprendido por el comandante? La próxima partida empezará sin memoria. Tu progreso no cambia"),
		"Debe aparecer el texto exacto de confirmación local del contrato §6; hoy no existe ningún " +
		"diálogo de confirmación")
	assert_not_null(_named_button("Cancelar"), "La confirmación ofrece la acción Cancelar")
	assert_not_null(_named_button("Borrar"), "La confirmación ofrece la acción Borrar")


func test_confirmation_cancel_does_not_emit_reset_and_returns_focus_to_delete_button() -> void:
	var delete_button := _delete_button()
	assert_not_null(delete_button, "Precondición del flujo: el botón de borrado debe existir")
	if delete_button == null:
		return
	watch_signals(_menu)
	_click(delete_button.get_global_rect().get_center())
	await wait_process_frames(2)
	var cancel := _named_button("Cancelar")
	assert_not_null(cancel, "Precondición del flujo: la confirmación debe ofrecer Cancelar")
	if cancel == null:
		return
	_click_control(cancel)
	await wait_process_frames(2)
	assert_signal_emit_count(_menu, "commander_reset_requested", 0, "Cancelar no escribe ni emite el borrado")
	assert_false(_visible_texts().has(
			"¿Borrar lo aprendido por el comandante? La próxima partida empezará sin memoria. Tu progreso no cambia"),
		"Cancelar debe cerrar el modal de confirmación")
	assert_same(_viewport.gui_get_focus_owner(), delete_button,
		"Cancelar devuelve el foco al botón de borrado (contrato §6)")


func test_confirmation_confirm_double_gesture_emits_reset_exactly_once_and_returns_focus() -> void:
	var delete_button := _delete_button()
	assert_not_null(delete_button, "Precondición del flujo: el botón de borrado debe existir")
	if delete_button == null:
		return
	watch_signals(_menu)
	_click(delete_button.get_global_rect().get_center())
	await wait_process_frames(2)
	var confirm := _named_button("Borrar")
	assert_not_null(confirm, "Precondición del flujo: la confirmación debe ofrecer Borrar")
	if confirm == null:
		return
	_click_control(confirm)
	_click_control(confirm) # Doble gesto real sobre el mismo botón de confirmación.
	await wait_process_frames(2)
	assert_signal_emit_count(_menu, "commander_reset_requested", 1,
		"Confirmar sólo se acepta una vez, también ante un doble gesto (contrato §6)")
	assert_same(_viewport.gui_get_focus_owner(), delete_button,
		"Confirmar también devuelve el foco al botón de borrado (contrato §6)")


func test_set_start_enabled_false_also_disables_delete_button_and_blocks_confirmation() -> void:
	var delete_button := _delete_button()
	assert_not_null(delete_button, "Precondición del flujo: el botón de borrado debe existir")
	if delete_button == null:
		return
	_menu.set_start_enabled(false)
	assert_true(delete_button.disabled,
		"`set_start_enabled(false)` también debe bloquear el borrado y la confirmación (contrato §6)")
	watch_signals(_menu)
	_click(delete_button.get_global_rect().get_center())
	await wait_process_frames(2)
	assert_false(_visible_texts().has(
			"¿Borrar lo aprendido por el comandante? La próxima partida empezará sin memoria. Tu progreso no cambia"),
		"Un botón deshabilitado no debe abrir la confirmación")
	assert_signal_emit_count(_menu, "commander_reset_requested", 0)


## RED por nodo ausente, no por lógica de foco: sin el tercer botón el ciclo
## circular hoy sigue siendo Jugar<->Ver introducción (2 nodos, T027); el
## contrato pide Jugar->Introducción->Borrar->Jugar (3 nodos).
func test_focus_circular_order_is_play_intro_delete_and_back_to_play() -> void:
	var delete_button := _delete_button()
	assert_not_null(delete_button,
		"El ciclo de foco de 3 nodos (Jugar->Introducción->Borrar->Jugar) exige que exista el botón " +
		"de borrado; hoy el ciclo real sigue siendo de 2 nodos")
	if delete_button == null:
		return
	var intro := _replay_button()
	assert_not_null(intro)
	if intro == null or _play == null:
		return
	assert_same(_focus_neighbor(_play, true), intro, "Jugar->Introducción hacia abajo")
	assert_same(_focus_neighbor(intro, true), delete_button, "Introducción->Borrar hacia abajo")
	assert_same(_focus_neighbor(delete_button, true), _play, "Borrar->Jugar hacia abajo cierra el ciclo")
	assert_same(_focus_neighbor(_play, false), delete_button, "Jugar->Borrar hacia arriba cierra el ciclo")
	assert_same(_focus_neighbor(intro, false), _play, "Introducción->Jugar hacia arriba")
	assert_same(_focus_neighbor(delete_button, false), intro, "Borrar->Introducción hacia arriba")
