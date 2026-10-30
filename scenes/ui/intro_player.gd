## Presentación narrativa aislada: informa intención, nunca crea la partida.
extends Control

signal finished(skipped: bool)
signal start_requested

const VOICE_GAP: float = 0.15
const VOICE_TAIL: float = 0.25

var _sequence: Resource
var _slide_index: int = -1
var _elapsed: float = 0.0
var _paused: bool = false
var _closed: bool = true
var _application_active: bool = true
var _companion_started: bool = false
var _prompting: bool = false
var _playing_panel_style: StyleBox
var _prompt_panel_style: StyleBoxEmpty

@onready var _image: TextureRect = $Stage/Image
@onready var _previous_image: TextureRect = $Stage/PreviousImage
@onready var _safe_area: MarginContainer = $SafeArea
@onready var _subtitle: Label = %Subtitle
@onready var _footer: PanelContainer = %Footer
@onready var _pause_button: Button = %PauseButton
@onready var _skip_button: Button = %SkipButton
@onready var _start_button: Button = %StartButton
@onready var _voice: AudioStreamPlayer = $Voice
@onready var _ambience: AudioStreamPlayer = $Ambience


func _ready() -> void:
	_playing_panel_style = _footer.get_theme_stylebox("panel")
	_prompt_panel_style = StyleBoxEmpty.new()
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_prompt_panel_style.set_content_margin(side, _playing_panel_style.get_content_margin(side))
	_pause_button.pressed.connect(_on_pause_pressed)
	_skip_button.pressed.connect(skip_intro)
	_start_button.pressed.connect(_on_start_pressed)
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()
	set_process(false)


func _process(delta: float) -> void:
	advance_intro(delta)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED,
			NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		set_application_active(false)
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED,
			NOTIFICATION_WM_WINDOW_FOCUS_IN]:
		set_application_active(true)


func _exit_tree() -> void:
	close_intro()


func play(sequence: Resource) -> void:
	close_intro()
	_sequence = sequence
	_closed = false
	_paused = false
	_prompting = false
	_start_button.hide()
	_start_button.disabled = true
	_footer.show()
	_footer.add_theme_stylebox_override("panel", _playing_panel_style)
	_subtitle.show()
	_pause_button.show()
	_skip_button.show()
	_pause_button.text = "Pausar"
	_pause_button.disabled = false
	_skip_button.disabled = false
	_image.texture = null
	_previous_image.texture = null
	show()
	if _sequence == null or _sequence.slides.is_empty():
		_finish(false)
		return
	if _sequence.ambience != null:
		_ambience.stream = _sequence.ambience
		_ambience.volume_db = _sequence.ambience_volume_db
		_ambience.stream_paused = false
		_ambience.play()
	_show_slide(0)
	_pause_button.grab_focus()
	set_process(true)


func pause_intro() -> void:
	if _closed or _paused:
		return
	_paused = true
	_voice.stream_paused = true
	_ambience.stream_paused = true
	_pause_button.text = "Continuar"


func resume_intro() -> void:
	if _closed or not _paused or not _application_active:
		return
	_paused = false
	_voice.stream_paused = false
	_ambience.stream_paused = false
	_pause_button.text = "Pausar"


func skip_intro() -> void:
	get_viewport().set_input_as_handled()
	_finish(true)


func close_intro() -> void:
	_closed = true
	_prompting = false
	set_process(false)
	for channel: AudioStreamPlayer in [_voice, _ambience]:
		if is_instance_valid(channel):
			channel.stop()
			channel.stream = null


func get_slide_index() -> int:
	return _slide_index


func get_elapsed() -> float:
	return _elapsed


func is_intro_paused() -> bool:
	return _paused


func is_intro_closed() -> bool:
	return _closed


func advance_intro(delta: float) -> void:
	if _closed or _paused or _sequence == null:
		return
	_elapsed += maxf(0.0, delta)
	var slide: Resource = _sequence.slides[_slide_index]
	if not _companion_started and not slide.companion_subtitle.is_empty() \
			and _elapsed >= _length(slide.narration) + VOICE_GAP:
		_companion_started = true
		_subtitle.text = slide.companion_subtitle
		_play_voice(slide.companion_voice)
	_render_slide()
	if _elapsed >= _duration(slide):
		if _slide_index + 1 < _sequence.slides.size():
			_show_slide(_slide_index + 1)
		else:
			_finish(false)


func set_application_active(active: bool) -> void:
	_application_active = active
	if not active:
		pause_intro()


func show_start_prompt() -> void:
	if not _closed:
		return
	_prompting = true
	_subtitle.hide()
	_pause_button.hide()
	_skip_button.hide()
	_footer.add_theme_stylebox_override("panel", _prompt_panel_style)
	_image.modulate.a = 1.0
	_previous_image.hide()
	_start_button.show()
	_start_button.disabled = false
	_start_button.grab_focus()


func _show_slide(index: int) -> void:
	_previous_image.texture = _image.texture
	_previous_image.scale = _image.scale
	_previous_image.position = _image.position
	_slide_index = index
	_elapsed = 0.0
	_companion_started = false
	var slide: Resource = _sequence.slides[index]
	_image.texture = slide.image
	_subtitle.text = slide.subtitle
	_play_voice(slide.narration)
	_render_slide()


func _play_voice(stream: AudioStream) -> void:
	_voice.stop()
	_voice.stream_paused = false
	_voice.stream = stream
	if stream != null:
		_voice.play()


func _length(stream: AudioStream) -> float:
	return maxf(0.0, stream.get_length()) if stream != null else 0.0


func _duration(slide: Resource) -> float:
	var voice_duration := _length(slide.narration)
	if not slide.companion_subtitle.is_empty():
		voice_duration += VOICE_GAP + _length(slide.companion_voice)
	return maxf(slide.minimum_duration, voice_duration + VOICE_TAIL)


func _render_slide() -> void:
	if _sequence == null or _slide_index < 0:
		return
	var slide: Resource = _sequence.slides[_slide_index]
	var progress := clampf(_elapsed / maxf(0.01, _duration(slide)), 0.0, 1.0)
	var smooth := progress * progress * (3.0 - 2.0 * progress)
	var zoom := clampf(lerpf(slide.start_zoom, slide.end_zoom, smooth), 1.0, 1.2)
	_image.pivot_offset = size * 0.5
	_image.scale = Vector2.ONE * zoom
	_image.position = slide.start_offset.lerp(slide.end_offset, smooth)
	var transition: float = _sequence.transition_duration
	_image.modulate.a = clampf(_elapsed / transition, 0.0, 1.0) if transition > 0.0 else 1.0
	_previous_image.pivot_offset = size * 0.5
	_previous_image.visible = _image.modulate.a < 1.0


func _finish(skipped: bool) -> void:
	if _closed:
		return
	close_intro()
	_pause_button.disabled = true
	_skip_button.disabled = true
	finished.emit(skipped)


func _on_pause_pressed() -> void:
	get_viewport().set_input_as_handled()
	if _paused:
		resume_intro()
	else:
		pause_intro()


func _on_start_pressed() -> void:
	get_viewport().set_input_as_handled()
	if not _prompting:
		return
	_prompting = false
	_start_button.disabled = true
	start_requested.emit()


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
	for side: String in ["left", "top", "right", "bottom"]:
		_safe_area.add_theme_constant_override("margin_" + side, insets[["left", "top", "right", "bottom"].find(side)])
	var usable_width := maxf(0.0, viewport_size.x - insets.x - insets.z)
	var font_size := clampi(int(minf(usable_width * 0.028, viewport_size.y * 0.042)), 18, 28)
	_subtitle.add_theme_font_size_override("font_size", font_size)
	for button: Button in [_pause_button, _skip_button, _start_button]:
		button.add_theme_font_size_override("font_size", clampi(int(usable_width * 0.025), 18, 24))
	_render_slide()
