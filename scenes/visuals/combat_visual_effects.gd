## Servicio del nivel: observa derrotas y recicla imágenes, nunca actores.
class_name CombatVisualEffects
extends Node

const _EFFECT_SCENE: PackedScene = preload("res://scenes/visuals/DeathVisualEffect.tscn")

var _pool: ObjectPool


func setup(initial_size: int = 10) -> void:
	assert(_pool == null, "CombatVisualEffects.setup solo admite una preparación")
	_pool = ObjectPool.new()
	add_child(_pool)
	_pool.instance_created.connect(_on_effect_created)
	_pool.setup(_EFFECT_SCENE, initial_size)


func register_actor(actor: Node) -> void:
	if not actor.has_signal("defeat_visual_requested"):
		push_warning("Actor sin contrato visual de derrota")
		return
	if not actor.is_connected("defeat_visual_requested", request_defeat):
		actor.connect("defeat_visual_requested", request_defeat)


func request_defeat(snapshot: Dictionary) -> void:
	var frames := snapshot.get("sprite_frames") as SpriteFrames
	var animation: StringName = snapshot.get("defeat_animation", &"")
	if _pool == null or frames == null or not frames.has_animation(animation):
		push_warning("No se pudo representar la derrota: falta pool o recurso visual")
		return
	var effect := _pool.acquire() as DeathVisualEffect
	effect.play_snapshot(snapshot)


func get_active_effect_count() -> int:
	return _pool.in_use_count() if _pool != null else 0


func get_available_effect_count() -> int:
	return _pool.available_count() if _pool != null else 0


func _on_effect_created(instance: Node) -> void:
	(instance as DeathVisualEffect).finished.connect(_on_effect_finished)


func _on_effect_finished(effect: Node2D, activation: int) -> void:
	if (effect as DeathVisualEffect).get_activation_id() == activation:
		_pool.release(effect)
