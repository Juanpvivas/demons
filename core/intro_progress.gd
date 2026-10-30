## Interfaz neutral de recuerdo local; la implementación sigue a RED.
class_name IntroProgress
extends RefCounted

var storage_path: String = "user://intro_progress.cfg"


func has_seen(_version: String) -> bool:
	return false


func mark_seen(_version: String) -> Error:
	return ERR_UNAVAILABLE
