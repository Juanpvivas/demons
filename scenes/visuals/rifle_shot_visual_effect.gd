## Destello y trazadora cosméticos; los endpoints nunca siguen a un actor.
class_name RifleShotVisualEffect
extends Node2D

signal finished(effect: Node2D, activation: int)

const _LIFE_SECONDS: float = 0.16
const _FLASH_SECONDS: float = 0.09
const _TRACER_LENGTH: float = 46.0

var _activation: int = 0
var _active: bool = false
var _elapsed: float = 0.0
var _origin_world: Vector2
var _target_world: Vector2


func play_snapshot(snapshot: Dictionary) -> void:
	_reset_presentation()
	_origin_world = snapshot["origin_world"]
	_target_world = snapshot["target_world"]
	global_position = _origin_world
	_active = true
	visible = true
	set_process(true)
	queue_redraw()


func on_pool_acquired() -> void:
	_reset_presentation()


func on_pool_released() -> void:
	_reset_presentation()


func get_activation_id() -> int:
	return _activation


func get_shot_snapshot() -> Dictionary:
	if not _active:
		return {}
	return {"origin_world": _origin_world, "target_world": _target_world}


func complete_activation(activation: int) -> void:
	if not _active or activation != _activation:
		return
	_active = false
	visible = false
	set_process(false)
	queue_redraw()
	finished.emit(self, activation)


func _process(delta: float) -> void:
	if not _active or GameStateManager._current_state == GameStateManager.GameState.PAUSED:
		return
	_elapsed += delta
	if _elapsed >= _LIFE_SECONDS:
		complete_activation(_activation)
	else:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var displacement := _target_world - _origin_world
	var distance := displacement.length()
	var direction := displacement.normalized() if distance > 0.0 else Vector2.RIGHT
	var progress := _elapsed / _LIFE_SECONDS
	var fade := 1.0 - progress
	# Un segmento corto se disuelve en la dirección del tiro, sin haz sostenido.
	var length := minf(_TRACER_LENGTH, distance)
	var start := lerpf(minf(10.0, distance), maxf(0.0, distance - length), progress)
	var from := to_local(_origin_world + direction * start)
	var to := to_local(_origin_world + direction * minf(start + length, distance))
	draw_line(from, to, Color(0.68, 0.49, 0.28, 0.18 * fade), 3.0, true)
	draw_line(from, to, Color(0.89, 0.76, 0.49, 0.65 * fade), 1.2, true)
	var flash_fade := maxf(0.0, 1.0 - _elapsed / _FLASH_SECONDS)
	if flash_fade > 0.0:
		_draw_flash(direction, flash_fade)


func _draw_flash(direction: Vector2, fade: float) -> void:
	var across := direction.orthogonal()
	var silhouette := PackedVector2Array([
		Vector2(0, -1.0), Vector2(5, -3.0), Vector2(4, -1.0),
		Vector2(12, -1.8), Vector2(8, 0), Vector2(13, 1.0),
		Vector2(4, 1.0), Vector2(5, 3.0), Vector2(0, 1.0),
	])
	var points := PackedVector2Array()
	for point: Vector2 in silhouette:
		points.append(to_local(_origin_world + direction * point.x + across * point.y))
	draw_colored_polygon(points, Color(0.81, 0.61, 0.32, 0.36 * fade))
	points.append(points[0])
	draw_polyline(points, Color(0.74, 0.54, 0.28, 0.18 * fade), 1.5, true)
	draw_line(to_local(_origin_world), to_local(_origin_world + direction * 8.0),
		Color(0.96, 0.85, 0.60, 0.88 * fade), 2.0, true)


func _reset_presentation() -> void:
	# También seguro durante prewarm, antes de _ready y del primer acquire.
	_activation += 1
	_active = false
	_elapsed = 0.0
	_origin_world = Vector2.ZERO
	_target_world = Vector2.ZERO
	transform = Transform2D.IDENTITY
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	visible = false
	set_process(false)
	queue_redraw()
