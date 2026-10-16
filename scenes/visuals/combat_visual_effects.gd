## Contrato mínimo del servicio local de efectos; sin pool ni conexiones aún.
class_name CombatVisualEffects
extends Node


func setup(_initial_size: int = 10) -> void:
	pass


func register_actor(_actor: Node) -> void:
	pass


func request_defeat(_snapshot: Dictionary) -> void:
	pass


func get_active_effect_count() -> int:
	return 0


func get_available_effect_count() -> int:
	return 0
