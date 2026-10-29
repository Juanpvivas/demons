## HUD global del nivel (`docs/ARCHITECTURE.md` §5: "instancia de HUD.tscn
## como CanvasLayer" dentro de `Nivel_MonteCalvo.tscn`). Dos
## responsabilidades en el alcance de T036 (`spec.md` User Story 2):
##
## - Contador de munición recolectada (FR-015, `contracts/signals.md` fila
##   `ammo_pool_changed`): refleja `EconomyManager.collected_ammo`,
##   inicializado al arrancar (no solo esperando el primer cambio) y
##   actualizado en cada `ammo_pool_changed`.
## - Mensaje de rechazo (FR-011, `contracts/signals.md` fila
##   `deploy_or_reload_rejected`): al recibir la señal con su `reason`, lo
##   muestra en un `Label` separado. No hay spec de UX detallada para el
##   MVP sobre cuánto debe durar un mensaje en pantalla, así que se opta
##   por el mecanismo más simple y explícito: un `Timer` `one_shot` que
##   oculta el mensaje al expirar (`RejectionMessageTimer`, `HUD.tscn`);
##   un nuevo rechazo mientras el anterior sigue visible reemplaza el texto
##   y reinicia el temporizador, dándole su propio tiempo completo de
##   lectura en vez de ocultarse a mitad de camino.
##
## T045 (`spec.md` User Story 3) agrega dos responsabilidades más, ambas
## por Principio III de `constitution.md` (prohíbe transiciones silenciosas):
##
## - Aviso de "oleada por llegar" (`contracts/signals.md` fila
##   `WaveManager.wave_started`): mismo mecanismo que el mensaje de
##   rechazo — `Label` (`WaveLabel`) + `Timer` `one_shot`
##   (`WaveMessageTimer`) independiente del de rechazo, para que ambos
##   avisos puedan solaparse sin pisarse el temporizador entre sí. Tampoco
##   hay spec de UX detallada aquí; se reutiliza el patrón ya validado en
##   T036 en vez de inventar uno nuevo.
## - Pantalla de victoria/derrota (`contracts/signals.md` filas
##   `GameStateManager.game_won`/`game_lost`): un único `Control`
##   (`GameOverScreen`) a pantalla completa, oculto por defecto, con un
##   `Label` (`GameOverLabel`) cuyo texto cambia según la señal recibida
##   ("VICTORIA"/"DERROTA") — se reutiliza el mismo nodo para ambos casos
##   porque el spec no pide presentación visual distinta entre victoria y
##   derrota para el MVP, y `GameStateManager` garantiza que el estado es
##   terminal (nunca se reciben ambas señales en la misma partida). Al
##   quedar visible, su `Control` por defecto (`mouse_filter` = `STOP`)
##   bloquea los clics de gameplay que llegan al tablero debajo (recolectar
##   munición, desplegar soldados) — supuesto de implementación: T045 pide
##   solo el feedback visual, no un flujo de game over completo (sin botón
##   de reinicio ni cambio de escena, fuera de alcance de esta tarea), pero
##   dejar el tablero clickeable detrás de un cartel de "VICTORIA"/"DERROTA"
##   sería confuso para el jugador.
##
## No declara `class_name`: igual que `nivel_monte_calvo.gd`, es una
## instancia concreta única por nivel (un solo HUD vivo por partida), no un
## tipo reutilizable instanciado múltiples veces desde otro script — a
## diferencia de `Soldado`/`AmmoPickup`, que sí lo declaran por
## instanciarse muchas veces en runtime.
extends CanvasLayer

## El nivel revalida el hogar y la identidad capturados por cada control.
signal trench_reload_requested(home_cell: Vector2i, soldier_instance_id: int)

## La UI sólo emite intenciones; no cambia escenas ni reinicia Managers.
signal retry_requested
signal menu_requested

const _RELOAD_BUTTON_SIZE := Vector2(112, 48)

var _selected_soldier: Soldado
var _closing: bool = false
var _trench_reload_bindings: Dictionary[Vector2i, Dictionary] = {}


@onready var _ammo_label: Label = $Root/Info/AmmoLabel
@onready var _rejection_label: Label = $Root/Info/RejectionLabel
@onready var _rejection_message_timer: Timer = $RejectionMessageTimer
@onready var _wave_label: Label = $Root/Info/WaveLabel
@onready var _wave_message_timer: Timer = $WaveMessageTimer
@onready var _game_over_screen: Control = $GameOverScreen
@onready var _game_over_label: Label = $GameOverScreen/CenterContainer/GameOverLabel
@onready var _selection_panel: Control = $SelectionPanel
@onready var _selection_label: Label = $SelectionPanel/Contents/Details/SelectionLabel
@onready var _individual_ammo_label: Label = $SelectionPanel/Contents/Details/IndividualAmmoLabel
@onready var _morale_label: Label = $SelectionPanel/Contents/Details/MoraleLabel
@onready var _trench_reload_controls: Control = $TrenchReloadControls
@onready var _retry_button: Button = $GameOverScreen/Actions/RetryButton
@onready var _menu_button: Button = $GameOverScreen/Actions/MenuButton


func get_trench_reload_button(home_cell: Vector2i) -> Button:
	if _trench_reload_bindings.has(home_cell):
		return _trench_reload_bindings[home_cell].button as Button
	return null


func register_trench_reload(home_cell: Vector2i, soldier: Soldado, world_anchor: Vector2,
		parts: Array[Sprite2D] = []) -> void:
	if _closing or not is_instance_valid(soldier):
		return
	var identity := soldier.get_instance_id()
	if _trench_reload_bindings.has(home_cell):
		if _trench_reload_bindings[home_cell].instance_id == identity:
			_trench_reload_bindings[home_cell].world_anchor = world_anchor
			if not parts.is_empty():
				(_trench_reload_bindings[home_cell].button as TrenchReloadControl).bind_trench_parts(parts)
			_refresh_trench_reload(home_cell, identity)
			return
		unregister_trench_reload(home_cell)
	if _trench_reload_bindings.size() >= 5:
		return
	var button := TrenchReloadControl.new()
	button.name = "ReloadHome%d_%d" % [home_cell.x, home_cell.y]
	button.pressed.connect(_on_trench_reload_pressed.bind(home_cell, identity))
	var changed := _refresh_trench_reload.bind(home_cell, identity)
	var exiting := _on_trench_owner_exiting.bind(home_cell, identity)
	_trench_reload_bindings[home_cell] = {
		"soldier": soldier, "instance_id": identity, "world_anchor": world_anchor,
		"button": button, "changed": changed, "exiting": exiting,
	}
	_trench_reload_controls.add_child(button)
	button.bind_trench_parts(parts)
	soldier.reload_state_changed.connect(changed)
	soldier.tree_exiting.connect(exiting)
	_refresh_trench_reload(home_cell, identity)


func unregister_trench_reload(home_cell: Vector2i) -> void:
	if not _trench_reload_bindings.has(home_cell):
		return
	var binding: Dictionary = _trench_reload_bindings[home_cell]
	_trench_reload_bindings.erase(home_cell)
	var soldier := binding.soldier as Soldado
	if is_instance_valid(soldier):
		_disconnect_signal(soldier.reload_state_changed, binding.changed)
		_disconnect_signal(soldier.tree_exiting, binding.exiting)
	var button := binding.button as TrenchReloadControl
	button.set_reload_state(false, false)
	# Retirar el control cancela el foco del gesto del dueño anterior.
	_trench_reload_controls.remove_child(button)
	button.queue_free()
	update_trench_reload_layout()


func _on_trench_owner_exiting(home_cell: Vector2i, identity: int) -> void:
	if _trench_reload_bindings.has(home_cell) \
			and _trench_reload_bindings[home_cell].instance_id == identity:
		unregister_trench_reload(home_cell)


func _refresh_trench_reload(home_cell: Vector2i, identity: int) -> void:
	if not _trench_reload_bindings.has(home_cell) \
			or _trench_reload_bindings[home_cell].instance_id != identity:
		return
	var binding: Dictionary = _trench_reload_bindings[home_cell]
	var soldier := binding.soldier as Soldado
	var button := binding.button as TrenchReloadControl
	var show_action := false
	if not _closing and is_instance_valid(soldier):
		var state := soldier.get_reload_state()
		show_action = state.alive and state.ammo == 0 and state.home_cell == home_cell
	button.set_reload_state(show_action, show_action and soldier.can_reload())
	update_trench_reload_layout()


func _refresh_trench_reloads() -> void:
	for home: Vector2i in _trench_reload_bindings.keys():
		_refresh_trench_reload(home, _trench_reload_bindings[home].instance_id)


func _on_trench_reload_pressed(home_cell: Vector2i, identity: int) -> void:
	if _closing or not _trench_reload_bindings.has(home_cell):
		return
	var binding: Dictionary = _trench_reload_bindings[home_cell]
	var soldier := binding.soldier as Soldado
	var button := binding.button as Button
	if binding.instance_id != identity or not is_instance_valid(soldier) \
			or not button.is_visible_in_tree() or not soldier.can_reload():
		return
	get_viewport().set_input_as_handled()
	trench_reload_requested.emit(home_cell, identity)


## La cámara notifica después de aplicar su canvas; el ancla nunca sigue al actor.
func update_trench_reload_layout() -> void:
	if _closing or not is_instance_valid(_trench_reload_controls):
		return
	var safe := _safe_view_rect()
	var to_controls := _trench_reload_controls.get_global_transform_with_canvas().affine_inverse()
	var bounds: Rect2 = to_controls * safe
	var world_to_controls := to_controls * get_viewport().canvas_transform
	for binding: Dictionary in _trench_reload_bindings.values():
		var button := binding.button as TrenchReloadControl
		var rect: Rect2 = world_to_controls * button.get_trench_world_rect(binding.world_anchor)
		button.size = Vector2(maxf(_RELOAD_BUTTON_SIZE.x, rect.size.x),
			maxf(_RELOAD_BUTTON_SIZE.y, rect.size.y))
		var origin := rect.get_center() - button.size * 0.5
		button.position = Vector2(
			clampf(origin.x, bounds.position.x, bounds.end.x - button.size.x),
			clampf(origin.y, bounds.position.y, bounds.end.y - button.size.y))
	_layout_info_around_trenches(safe)


func _layout_info_around_trenches(safe: Rect2) -> void:
	var info_size := Vector2.ZERO
	var visible_count := 0
	for label: Label in [_ammo_label, _rejection_label, _wave_label]:
		if label.visible:
			var minimum := label.get_combined_minimum_size()
			info_size.x = maxf(info_size.x, minimum.x)
			info_size.y += minimum.y
			visible_count += 1
	info_size.y += maxi(0, visible_count - 1) * $Root/Info.get_theme_constant("separation")
	var base_rect := Rect2(safe.position, info_size)
	var left := safe.position.x
	for binding: Dictionary in _trench_reload_bindings.values():
		var button := binding.button as Button
		if button.visible and base_rect.intersects(button.get_global_rect()):
			left = maxf(left, button.get_global_rect().end.x + 12.0)
	left = minf(left, maxf(safe.position.x, safe.end.x - info_size.x))
	$Root.add_theme_constant_override("margin_left", ceili(left))


func set_selected_soldier(soldier: Soldado) -> void:
	if is_instance_valid(_selected_soldier):
		_selected_soldier.reload_state_changed.disconnect(_refresh_selection)
	_selected_soldier = soldier
	if is_instance_valid(_selected_soldier):
		_selected_soldier.reload_state_changed.connect(_refresh_selection)
	_refresh_selection()


func get_selected_soldier() -> Soldado:
	if is_instance_valid(_selected_soldier) and _selected_soldier.get_reload_state().alive:
		return _selected_soldier
	return null


func _refresh_selection() -> void:
	var soldier := get_selected_soldier()
	_selection_panel.visible = soldier != null
	if soldier == null:
		return
	var state := soldier.get_reload_state()
	var returning: bool = state.movement_state == Soldado.MovementState.RETURNING
	_selection_label.text = "Fila %d%s" % [state.lane_id + 1, " · Regresando" if returning else ""]
	_individual_ammo_label.text = "Carga: %d/%d" % [state.ammo, state.max_ammo]
	_morale_label.text = "Moral: %s" % str(state.morale)


func _on_game_state_changed(_state: int) -> void:
	if not _closing:
		_refresh_selection()
		_refresh_trench_reloads()


func _can_request_result_action() -> bool:
	return not _closing and _game_over_screen.visible \
		and GameStateManager._current_state in [
			GameStateManager.GameState.WON, GameStateManager.GameState.LOST]


func _on_retry_pressed() -> void:
	if _can_request_result_action():
		get_viewport().set_input_as_handled()
		retry_requested.emit()


func _on_menu_pressed() -> void:
	if _can_request_result_action():
		get_viewport().set_input_as_handled()
		menu_requested.emit()


## Conserva el overlay bloqueando el gesto hasta que la raíz retire el árbol.
func close_match() -> void:
	if _closing:
		return
	_closing = true
	set_selected_soldier(null)
	for home: Vector2i in _trench_reload_bindings.keys():
		unregister_trench_reload(home)
	_retry_button.disabled = true
	_menu_button.disabled = true
	_rejection_message_timer.stop()
	_wave_message_timer.stop()
	_disconnect_signal(EconomyManager.ammo_pool_changed, _on_ammo_pool_changed)
	_disconnect_signal(EconomyManager.deploy_or_reload_rejected, _on_deploy_or_reload_rejected)
	_disconnect_signal(WaveManager.wave_started, _on_wave_started)
	_disconnect_signal(GameStateManager.game_won, _on_game_won)
	_disconnect_signal(GameStateManager.game_lost, _on_game_lost)
	_disconnect_signal(GameStateManager.game_state_changed, _on_game_state_changed)
	_disconnect_signal(get_viewport().size_changed, _apply_safe_area)


func _disconnect_signal(source: Signal, callback: Callable) -> void:
	if source.is_connected(callback):
		source.disconnect(callback)


func _exit_tree() -> void:
	close_match()


func _safe_view_rect() -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	var insets := Vector4(16, 16, 16, 16)
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if safe.size.x > 0 and safe.size.y > 0 and screen.x > 0 and screen.y > 0:
			var ratio := viewport_size / Vector2(screen)
			insets = Vector4(maxf(16, safe.position.x * ratio.x),
				maxf(16, safe.position.y * ratio.y),
				maxf(16, (screen.x - safe.end.x) * ratio.x),
				maxf(16, (screen.y - safe.end.y) * ratio.y))
	return Rect2(Vector2(insets.x, insets.y), viewport_size - Vector2(insets.x + insets.z, insets.y + insets.w))


func _apply_safe_area() -> void:
	var safe := _safe_view_rect()
	var right := ceili(get_viewport().get_visible_rect().size.x - safe.end.x)
	var top := ceili(safe.position.y)
	$Root.add_theme_constant_override("margin_top", top)
	_selection_panel.offset_right = -right
	_selection_panel.offset_left = -right - 324
	_selection_panel.offset_top = top
	_selection_panel.offset_bottom = top + 70
	update_trench_reload_layout()


func _ready() -> void:
	# Conexión de señales de autoload solo en `_ready()`
	# (`docs/ARCHITECTURE.md` §4.2), mismo patrón que `soldado.gd`.
	EconomyManager.ammo_pool_changed.connect(_on_ammo_pool_changed)
	EconomyManager.deploy_or_reload_rejected.connect(_on_deploy_or_reload_rejected)
	_rejection_message_timer.timeout.connect(_on_rejection_message_timer_timeout)

	WaveManager.wave_started.connect(_on_wave_started)
	_wave_message_timer.timeout.connect(_on_wave_message_timer_timeout)

	GameStateManager.game_won.connect(_on_game_won)
	GameStateManager.game_lost.connect(_on_game_lost)
	GameStateManager.game_state_changed.connect(_on_game_state_changed)
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_refresh_selection()

	# Estado inicial mostrado sin esperar el primer cambio: el pool global
	# ya puede tener un valor != 0 si este HUD se instancia después de que
	# el jugador recolectó munición (`ammo_pool_changed` solo se emite ante
	# cambios posteriores, nunca al conectar).
	_update_ammo_label(EconomyManager.collected_ammo)
	_rejection_label.visible = false
	_wave_label.visible = false
	_game_over_screen.visible = false


func _on_ammo_pool_changed(new_amount: int) -> void:
	if _closing:
		return
	_update_ammo_label(new_amount)
	_refresh_selection()
	_refresh_trench_reloads()


func _update_ammo_label(amount: int) -> void:
	_ammo_label.text = "Munición: %d" % amount


## FR-011: muestra el motivo del rechazo y (re)inicia el temporizador de
## ocultamiento.
func _on_deploy_or_reload_rejected(reason: String) -> void:
	if _closing:
		return
	_rejection_label.text = reason
	_rejection_label.visible = true
	_rejection_message_timer.start()
	update_trench_reload_layout()


func _on_rejection_message_timer_timeout() -> void:
	_rejection_label.visible = false
	update_trench_reload_layout()


## `contracts/signals.md` fila `WaveManager.wave_started` — Principio III
## de `constitution.md`: toda oleada nueva se anuncia explícitamente, nunca
## como transición silenciosa. Mismo mecanismo que
## `_on_deploy_or_reload_rejected()`: un nuevo `wave_started` mientras el
## aviso anterior sigue visible reemplaza el texto y reinicia el
## temporizador, dándole su propio tiempo completo de lectura.
func _on_wave_started(wave_number: int) -> void:
	if _closing:
		return
	_wave_label.text = "Oleada %d por llegar" % wave_number
	_wave_label.visible = true
	_wave_message_timer.start()
	update_trench_reload_layout()


func _on_wave_message_timer_timeout() -> void:
	_wave_label.visible = false
	update_trench_reload_layout()


## `contracts/signals.md` fila `GameStateManager.game_won`. Ver cabecera
## del archivo para el supuesto de implementación (pantalla compartida con
## `game_lost`, sin botón de reinicio ni cambio de escena — fuera de
## alcance de T045).
func _on_game_won() -> void:
	_show_game_over_screen("VICTORIA")


## `contracts/signals.md` fila `GameStateManager.game_lost`. Mismo
## mecanismo que `_on_game_won()`.
func _on_game_lost() -> void:
	_show_game_over_screen("DERROTA")


func _show_game_over_screen(message: String) -> void:
	if _closing:
		return
	_game_over_label.text = message
	_game_over_screen.visible = true
	_retry_button.grab_focus()
