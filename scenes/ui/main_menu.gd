## Menú pictórico sin autoridad sobre Managers o creación de la partida.
extends Control

signal play_requested
signal intro_requested

@onready var _play_button: Button = %PlayButton
@onready var _intro_button: Button = %IntroButton
@onready var _safe_area: MarginContainer = $SafeArea
@onready var _panel: PanelContainer = $SafeArea/CenterContainer/Panel
@onready var _title: Label = %TitleLabel


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_intro_button.pressed.connect(_on_intro_pressed)
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()
	_play_button.grab_focus()


func set_start_enabled(enabled: bool) -> void:
	_play_button.disabled = not enabled
	_intro_button.disabled = not enabled


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
