## Interfaz reservada para la presentación observacional de I2.
class_name EnemigoVisual
extends AnimatedSprite2D


func reset_visual() -> void:
	pass


func observe_displacement(_displacement: Vector2) -> void:
	pass


func play_confirmed_hit() -> void:
	pass


func deactivate_visual() -> void:
	pass


func capture_defeat_snapshot(_world_position: Vector2) -> Dictionary:
	return {}
