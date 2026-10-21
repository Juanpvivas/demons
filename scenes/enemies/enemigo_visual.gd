## Presentación por aparición: observa movimiento/daño, sin escribir gameplay.
class_name EnemigoVisual
extends AnimatedSprite2D

const _MOVEMENT_THRESHOLD: float = 0.01
const _HIT_SECONDS: float = 0.12
const _HIT_COLOR := Color(1.0, 0.55, 0.45)

var _alive: bool = false
var _generation: int = 0
var _authored_captured: bool = false
var _authored_scale: Vector2
var _authored_offset: Vector2
var _authored_flip_h: bool
var _authored_flip_v: bool
var _authored_z: int
var _authored_material: Material
var _authored_rotation: float
var _authored_speed_scale: float
var _hit_tween: Tween


func _ready() -> void:
	_capture_authored()


func reset_visual() -> void:
	deactivate_visual()
	_alive = true
	visible = true
	_play_pose(&"contact")


## Recibe desplazamiento físico confirmado; la velocidad deseada no basta.
func observe_displacement(displacement: Vector2) -> void:
	if not _alive:
		return
	_play_pose(&"advance" if displacement.length() > _MOVEMENT_THRESHOLD else &"contact")


func play_confirmed_hit() -> void:
	if not _alive:
		return
	if _hit_tween != null:
		_hit_tween.kill()
	modulate = _HIT_COLOR
	_hit_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_hit_tween.tween_method(_apply_hit_progress.bind(_generation), 0.0, 1.0, _HIT_SECONDS)


func deactivate_visual() -> void:
	_capture_authored()
	_alive = false
	_generation += 1
	if _hit_tween != null:
		_hit_tween.kill()
		_hit_tween = null
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
		"flip_h": _authored_flip_h,
		"flip_v": _authored_flip_v,
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


func _apply_hit_progress(progress: float, generation: int) -> void:
	if _alive and generation == _generation:
		modulate = _HIT_COLOR.lerp(Color.WHITE, progress)


func _play_pose(pose: StringName) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(pose):
		push_error("EnemigoVisual requiere la animación %s" % pose)
		return
	if animation == pose and is_playing():
		return
	play(pose)
	set_frame_and_progress(0, 0.0)
