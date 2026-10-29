## Zona de recarga sin decoración; pinta sólo las piezas del hogar enlazado.
class_name TrenchReloadControl
extends Button

enum GlowState { NORMAL, DIM, PULSING }

const _DIM_STRENGTH := 0.12
const _PULSE_LOW := 0.18
const _PULSE_HIGH := 0.60
const _RED := Color(1.0, 0.04, 0.015)
const _GLOW_SCALE := Vector2(1.03, 1.03)

var glow_state: GlowState = GlowState.NORMAL
var glow_strength: float = 0.0:
	set(value):
		glow_strength = value
		for glow: Sprite2D in _glows:
			if is_instance_valid(glow):
				glow.self_modulate = Color(_RED.r, _RED.g, _RED.b, value)
				glow.visible = value > 0.0

var _parts: Array[Sprite2D] = []
var _glows: Array[Sprite2D] = []
var _pulse: Tween


func _init() -> void:
	text = ""
	custom_minimum_size = Vector2(112, 48)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var empty := StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		add_theme_stylebox_override(state, empty)


func _ready() -> void:
	if glow_state == GlowState.PULSING:
		_start_pulse()


func bind_trench_parts(parts: Array[Sprite2D]) -> void:
	if _parts == parts:
		return
	var previous := glow_state
	_clear_glows()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for part: Sprite2D in parts:
		if not is_instance_valid(part):
			continue
		_parts.append(part)
		var glow := Sprite2D.new()
		glow.name = "ReloadGlow"
		glow.texture = part.texture
		glow.texture_filter = part.texture_filter
		glow.texture_repeat = part.texture_repeat
		glow.centered = part.centered
		glow.offset = part.offset
		glow.flip_h = part.flip_h
		glow.flip_v = part.flip_v
		glow.region_enabled = part.region_enabled
		glow.region_rect = part.region_rect
		glow.region_filter_clip_enabled = part.region_filter_clip_enabled
		glow.scale = _GLOW_SCALE
		glow.material = additive
		glow.hide()
		part.add_child(glow)
		_glows.append(glow)
	_set_glow_state(previous)


func set_reload_state(needs_reload: bool, can_reload: bool) -> void:
	visible = needs_reload
	disabled = not needs_reload or not can_reload
	var next := GlowState.NORMAL
	if needs_reload:
		next = GlowState.PULSING if can_reload else GlowState.DIM
	_set_glow_state(next)


## El HUD proyecta el área del arte, no la posición actual del soldado.
func get_trench_world_rect(fallback_anchor: Vector2) -> Rect2:
	var result := Rect2()
	var found := false
	for part: Sprite2D in _parts:
		if is_instance_valid(part):
			var rect := part.global_transform * part.get_rect()
			result = result.merge(rect) if found else rect
			found = true
	return result if found else Rect2(fallback_anchor + Vector2(-64, -28), Vector2(128, 64))


func _set_glow_state(next: GlowState) -> void:
	if next == glow_state:
		return
	_stop_pulse()
	glow_state = next
	match glow_state:
		GlowState.NORMAL:
			glow_strength = 0.0
		GlowState.DIM:
			glow_strength = _DIM_STRENGTH
		GlowState.PULSING:
			_start_pulse()


func _start_pulse() -> void:
	glow_strength = _PULSE_LOW
	if not is_inside_tree():
		return
	_pulse = create_tween().set_loops()
	_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(self, "glow_strength", _PULSE_HIGH, 0.6)
	_pulse.tween_property(self, "glow_strength", _PULSE_LOW, 0.6)


func _stop_pulse() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = null


func _clear_glows() -> void:
	_stop_pulse()
	glow_state = GlowState.NORMAL
	glow_strength = 0.0
	for glow: Sprite2D in _glows:
		if is_instance_valid(glow):
			glow.get_parent().remove_child(glow)
			glow.queue_free()
	_glows.clear()
	_parts.clear()


func _exit_tree() -> void:
	_clear_glows()
