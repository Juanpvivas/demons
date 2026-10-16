## Interfaz de presentación observacional; comportamiento pendiente de RED.
class_name SoldadoVisual
extends AnimatedSprite2D


func reset_visual(_mode: int) -> void:
	pass


func observe_mode(_mode: int) -> void:
	pass


func play_confirmed_attack(_mode: int) -> void:
	pass


func play_confirmed_hit() -> void:
	pass


func play_confirmed_morale() -> void:
	pass


func deactivate_visual() -> void:
	pass


func capture_defeat_snapshot(_world_position: Vector2) -> Dictionary:
	return {}
