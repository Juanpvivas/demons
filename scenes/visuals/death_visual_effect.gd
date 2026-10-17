## Derrota sin cuerpo/input. El final solo retira esta activación visual.
class_name DeathVisualEffect
extends Node2D

signal finished(effect: Node2D, activation: int)

const _DEFEAT_SECONDS: float = 0.40

var _activation: int = 0
var _active: bool = false
var _completion_tween: Tween
var _sprite: AnimatedSprite2D


func play_snapshot(snapshot: Dictionary) -> void:
	_reset_presentation()
	_active = true
	visible = true
	global_position = snapshot["world_position"]
	_sprite.sprite_frames = snapshot["sprite_frames"]
	_sprite.scale = snapshot["visual_scale"]
	_sprite.offset = snapshot["visual_offset"]
	_sprite.flip_h = snapshot["flip_h"]
	_sprite.flip_v = snapshot["flip_v"]
	_sprite.z_index = snapshot["visual_z"]
	_sprite.material = snapshot.get("visual_material") as Material
	_sprite.play(snapshot["defeat_animation"])
	_sprite.set_frame_and_progress(0, 0.0)
	_completion_tween = create_tween()
	_completion_tween.tween_interval(_DEFEAT_SECONDS)
	_completion_tween.tween_callback(complete_activation.bind(_activation))


func on_pool_acquired() -> void:
	_reset_presentation()
	visible = true


func on_pool_released() -> void:
	_reset_presentation()
	visible = false


func get_activation_id() -> int:
	return _activation


func complete_activation(activation: int) -> void:
	if not _active or activation != _activation:
		return
	_active = false
	_sprite.stop()
	visible = false
	finished.emit(self, activation)


func _reset_presentation() -> void:
	# ObjectPool puede liberar una instancia antes de que entre al árbol.
	if _sprite == null:
		_sprite = get_node("AnimatedSprite2D")
	_activation += 1
	_active = false
	if _completion_tween != null:
		_completion_tween.kill()
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	_sprite.stop()
	_sprite.visible = true
	_sprite.modulate = Color.WHITE
	_sprite.material = null
	_sprite.scale = Vector2.ONE
	_sprite.offset = Vector2.ZERO
	_sprite.rotation = 0.0
	_sprite.flip_h = false
	_sprite.flip_v = false
	_sprite.speed_scale = 1.0
	_sprite.set_frame_and_progress(0, 0.0)
