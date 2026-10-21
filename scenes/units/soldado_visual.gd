## Presentación por instancia: observa hechos y nunca escribe gameplay.
class_name SoldadoVisual
extends AnimatedSprite2D

const _RIFLE_MODE: int = 0 # SoldierMode.RIFLE; no depende del script padre.
const _SHOT_SECONDS: float = 0.16
const _MELEE_SECONDS: float = 0.24
const _HIT_SECONDS: float = 0.12
const _MORALE_SECONDS: float = 0.16
const _RETURNING: int = 4 # MovementState.RETURNING; dato observado, no autoridad.
const _MOVEMENT_THRESHOLD: float = 0.01

var _mode: int = _RIFLE_MODE
var _alive: bool = false
var _generation: int = 0
var _movement_state: int = 0
var _moving: bool = false
var _attack_active: bool = false
var _authored_captured: bool = false
var _authored_scale: Vector2
var _authored_offset: Vector2
var _authored_flip_h: bool
var _authored_flip_v: bool
var _authored_z: int
var _authored_material: Material
var _authored_rotation: float
var _authored_speed_scale: float
var _action_tween: Tween
var _hit_tween: Tween
var _morale_tween: Tween


func _ready() -> void:
	_capture_authored()


func reset_visual(mode: int) -> void:
	_capture_authored()
	deactivate_visual()
	_alive = true
	_mode = mode
	_movement_state = 0
	_moving = false
	visible = true
	_show_idle()


func observe_mode(mode: int) -> void:
	if not _alive or _mode == mode:
		return
	_mode = mode
	_generation += 1
	if _action_tween != null:
		_action_tween.kill()
	_attack_active = false
	_show_idle()


## Solo observa el resultado físico; un bloqueo no representa pasos ficticios.
func observe_motion(movement_state: int, displacement: Vector2) -> void:
	if not _alive:
		return
	var returning := movement_state == _RETURNING
	if returning != (_movement_state == _RETURNING):
		_generation += 1
		if _action_tween != null:
			_action_tween.kill()
		_attack_active = false
	_movement_state = movement_state
	_moving = displacement.length() > _MOVEMENT_THRESHOLD
	flip_h = not _authored_flip_h if returning else _authored_flip_h
	if not _attack_active:
		_show_idle()


func play_confirmed_attack(mode: int) -> void:
	if not _alive or mode != _mode or _movement_state == _RETURNING:
		return
	if _action_tween != null:
		_action_tween.kill()
	_generation += 1
	_attack_active = true
	var rifle := mode == _RIFLE_MODE
	_play_pose(&"rifle_shot" if rifle else &"melee_attack")
	_action_tween = create_tween()
	_action_tween.tween_interval(_SHOT_SECONDS if rifle else _MELEE_SECONDS)
	_action_tween.tween_callback(_finish_attack.bind(_generation))


func play_confirmed_hit() -> void:
	if not _alive:
		return
	if _hit_tween != null:
		_hit_tween.kill()
	modulate = Color(1.0, 0.55, 0.45)
	_hit_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_hit_tween.tween_property(self, "modulate", Color.WHITE, _HIT_SECONDS)


func play_confirmed_morale() -> void:
	if not _alive:
		return
	if _morale_tween != null:
		_morale_tween.kill()
	scale = _authored_scale * 1.10
	_morale_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_morale_tween.tween_property(self, "scale", _authored_scale, _MORALE_SECONDS)


func deactivate_visual() -> void:
	_capture_authored()
	_alive = false
	_attack_active = false
	_generation += 1
	for tween: Tween in [_action_tween, _hit_tween, _morale_tween]:
		if tween != null:
			tween.kill()
	stop()
	if sprite_frames != null and sprite_frames.has_animation(animation):
		set_frame_and_progress(0, 0.0)
	visible = false
	scale = _authored_scale
	offset = _authored_offset
	flip_h = _authored_flip_h
	flip_v = _authored_flip_v
	z_index = _authored_z
	material = _authored_material
	rotation = _authored_rotation
	speed_scale = _authored_speed_scale
	modulate = Color.WHITE


func capture_defeat_snapshot(world_position: Vector2) -> Dictionary:
	_capture_authored()
	return {
		"world_position": world_position,
		"sprite_frames": sprite_frames,
		"defeat_animation": &"defeat",
		"visual_scale": _authored_scale,
		"visual_offset": _authored_offset,
		"flip_h": flip_h,
		"flip_v": flip_v,
		"visual_z": _authored_z,
		"visual_material": _authored_material,
	}


func _capture_authored() -> void:
	if _authored_captured:
		return
	_authored_captured = true
	_authored_scale = scale
	_authored_offset = offset
	_authored_flip_h = flip_h
	_authored_flip_v = flip_v
	_authored_z = z_index
	_authored_material = material
	_authored_rotation = rotation
	_authored_speed_scale = speed_scale


func _finish_attack(generation: int) -> void:
	if _alive and generation == _generation:
		_attack_active = false
		_show_idle()


func _show_idle() -> void:
	if _movement_state == _RETURNING:
		_play_pose(&"returning" if _moving else &"returning_idle")
	elif _mode == _RIFLE_MODE:
		_play_pose(&"rifle_idle")
	else:
		_play_pose(&"melee_march" if _moving else &"melee_idle")


func _play_pose(pose: StringName) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(pose):
		push_error("SoldadoVisual requiere la animación %s" % pose)
		return
	if animation == pose and is_playing():
		return
	play(pose)
	set_frame_and_progress(0, 0.0)
