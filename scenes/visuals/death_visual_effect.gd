## Contrato de una activación visual, sin reproducción ni reciclado resueltos.
class_name DeathVisualEffect
extends Node2D

signal finished(effect: Node2D, activation: int)


func play_snapshot(_snapshot: Dictionary) -> void:
	pass


func on_pool_acquired() -> void:
	pass


func on_pool_released() -> void:
	pass


func get_activation_id() -> int:
	return 0


func complete_activation(_activation: int) -> void:
	pass
