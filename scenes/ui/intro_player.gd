## Interfaz neutral del reproductor, sin reproducción ni navegación en setup.
extends Control

signal finished(skipped: bool)
signal start_requested


func play(_sequence: Resource) -> void:
	pass


func pause_intro() -> void:
	pass


func resume_intro() -> void:
	pass


func skip_intro() -> void:
	pass


func close_intro() -> void:
	pass


func get_slide_index() -> int:
	return -1


func get_elapsed() -> float:
	return 0.0


func is_intro_paused() -> bool:
	return false


func is_intro_closed() -> bool:
	return false


func advance_intro(_delta: float) -> void:
	pass


func set_application_active(_active: bool) -> void:
	pass


func show_start_prompt() -> void:
	pass
