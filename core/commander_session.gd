## Interfaz neutral del comandante; el comportamiento se guía desde RED.
class_name CommanderSession
extends RefCounted


func begin_match(_match_id: String, _seed_value: int, _config: CommanderConfig,
		_memory: Dictionary) -> void:
	pass


func choose_lane(_snapshot: Dictionary) -> Dictionary:
	return {}


func register_spawn(_decision: Dictionary, _actor_id: int, _generation: int,
		_spawn_x: float, _defended_right: float) -> bool:
	return false


func cancel_proposal(_token: Variant) -> bool:
	return false


func record_defeat(_actor_id: int, _generation: int, _death_x: float) -> void:
	pass


func record_breach(_actor_id: int, _generation: int) -> void:
	pass


func finish(_result: Variant) -> Dictionary:
	return {}


func abandon() -> void:
	pass


func get_decision_snapshot() -> Dictionary:
	return {}
