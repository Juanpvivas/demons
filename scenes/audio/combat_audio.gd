## Contrato neutral de audio de sesión; todavía no observa ni reproduce.
class_name CombatAudio
extends Node

signal cue_started(cue: StringName)


func setup(_profile: Resource) -> void:
	pass


func register_actor(_actor: Node) -> void:
	pass


func set_application_active(_active: bool) -> void:
	pass


func close_match() -> void:
	pass


func get_active_voice_count() -> int:
	return 0


func get_voice_capacity() -> int:
	return 0
