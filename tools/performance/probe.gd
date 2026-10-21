## Interfaz invocable para las pruebas RED del instrumento optativo de QA.
extends Node


func start(_config: Dictionary, _initial_snapshot: Dictionary, _at_usec: int) -> bool:
	return false


func record_wall_interval(_at_usec: int) -> void:
	pass


func snapshot_recursive(_root: Node) -> Dictionary:
	return {}


func finish(_final_snapshot: Dictionary) -> Dictionary:
	return {}


func compare_runs(_base: Dictionary, _candidate: Dictionary) -> Dictionary:
	return {}
