## Menú pictórico sin autoridad sobre Managers o creación de la partida.
extends Control

signal play_requested
signal intro_requested
## 017/I2 T042: intención de borrado de memoria del comandante (contrato §6).
## Sólo la emite la confirmación local del botón "Borrar memoria del
## comandante", una vez por confirmación aceptada.
signal commander_reset_requested

@onready var _play_button: Button = %PlayButton
@onready var _intro_button: Button = %IntroButton
@onready var _delete_button: Button = %DeleteMemoryButton
@onready var _delete_confirm_dialog: ConfirmationDialog = %DeleteMemoryConfirmDialog
@onready var _safe_area: MarginContainer = $SafeArea
@onready var _panel: PanelContainer = $SafeArea/CenterContainer/Panel
@onready var _title: Label = %TitleLabel

## Bloquea reentrada de la confirmación: ignora una segunda emisión de
## `confirmed` mientras la primera todavía no cerró el modal (contrato §6,
## "confirmar sólo se acepta una vez").
var _confirm_resolved: bool = false

## 017/I2 T042 (corrección post-T043): `%DeleteMemoryConfirmDialog` se centra
## sobre la misma región de pantalla que la VBox del menú. Un doble gesto real
## (dos clics/toques completos y rápidos) sobre "Borrar" cierra el modal de
## forma síncrona en el primer gesto y deja expuesto, en la misma coordenada,
## el control que quede debajo (confirmado por reproducción aislada fuera de
## GUT: el segundo gesto llegaba a disparar `pressed` de `%PlayButton`).
## Mientras este flag está activo, `_input()` consume cualquier evento de
## puntero (ratón/toque) antes de que la rutina de GUI de los botones del menú
## lo reciba, para que el resto de la ráfaga del gesto anterior no dispare
## ningún botón expuesto por el cierre del modal. Se activa justo al cerrar
## la confirmación (confirmar o cancelar) y se libera de forma acotada en el
## siguiente `process_frame` (patrón de ráfaga ya usado en
## `scenes/game/game_root.gd::request_start()`), sin depender de recibir un
## evento de "soltar" que podría no llegar nunca (p. ej. confirmación por
## teclado).
var _ignoring_pointer_burst_after_dialog: bool = false


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_intro_button.pressed.connect(_on_intro_pressed)
	_delete_button.pressed.connect(_on_delete_memory_pressed)
	_delete_confirm_dialog.confirmed.connect(_on_delete_memory_confirmed)
	_delete_confirm_dialog.canceled.connect(_on_delete_memory_canceled)
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()
	_play_button.grab_focus()


func set_start_enabled(enabled: bool) -> void:
	_play_button.disabled = not enabled
	_intro_button.disabled = not enabled
	_delete_button.disabled = not enabled
	# Contrato §6: "`set_start_enabled(false)` también bloquea el borrado y
	# la confirmación" — cierra el modal abierto sin confirmar ni emitir nada.
	if not enabled and _delete_confirm_dialog.visible:
		_delete_confirm_dialog.hide()


func show_menu() -> void:
	show()
	set_start_enabled(true)
	_apply_layout()
	_play_button.grab_focus()


func _on_play_pressed() -> void:
	get_viewport().set_input_as_handled()
	play_requested.emit()


func _on_intro_pressed() -> void:
	get_viewport().set_input_as_handled()
	intro_requested.emit()


## Abre la confirmación local; nunca emite `commander_reset_requested` por sí
## solo (contrato §6, "un solo clic abre la confirmación local; no borra sin
## confirmar").
func _on_delete_memory_pressed() -> void:
	get_viewport().set_input_as_handled()
	if _delete_button.disabled:
		return
	_confirm_resolved = false
	_delete_confirm_dialog.popup_centered()


func _on_delete_memory_confirmed() -> void:
	if _confirm_resolved:
		return
	_confirm_resolved = true
	commander_reset_requested.emit()
	_delete_button.grab_focus()
	_start_pointer_burst_guard()


func _on_delete_memory_canceled() -> void:
	_confirm_resolved = true
	_delete_button.grab_focus()
	_start_pointer_burst_guard()


## 017/I2 T042 (corrección post-T043): ver `_ignoring_pointer_burst_after_dialog`.
func _start_pointer_burst_guard() -> void:
	_ignoring_pointer_burst_after_dialog = true
	_clear_pointer_burst_guard.call_deferred()


func _clear_pointer_burst_guard() -> void:
	_ignoring_pointer_burst_after_dialog = false


func _input(event: InputEvent) -> void:
	if not _ignoring_pointer_burst_after_dialog:
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion \
			or event is InputEventScreenTouch or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()


func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var insets := Vector4i(24, 24, 24, 24)
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if safe.size.x > 0 and safe.size.y > 0 and screen.x > 0 and screen.y > 0:
			var ratio := viewport_size / Vector2(screen)
			insets.x = maxi(insets.x, ceili(safe.position.x * ratio.x))
			insets.y = maxi(insets.y, ceili(safe.position.y * ratio.y))
			insets.z = maxi(insets.z, ceili((screen.x - safe.end.x) * ratio.x))
			insets.w = maxi(insets.w, ceili((screen.y - safe.end.y) * ratio.y))
	_safe_area.add_theme_constant_override("margin_left", insets.x)
	_safe_area.add_theme_constant_override("margin_top", insets.y)
	_safe_area.add_theme_constant_override("margin_right", insets.z)
	_safe_area.add_theme_constant_override("margin_bottom", insets.w)
	var usable_width := maxf(0.0, viewport_size.x - insets.x - insets.z)
	_panel.custom_minimum_size.x = minf(480.0, usable_width)
	_title.add_theme_font_size_override("font_size", clampi(int(usable_width * 0.075), 28, 42))
