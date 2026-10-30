## Recuerdo local dedicado a la versión narrativa, sin progreso de combate.
class_name IntroProgress
extends RefCounted

var storage_path: String = "user://intro_progress.cfg"


func has_seen(version: String) -> bool:
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null or version.is_empty():
		return false
	# Sólo aceptamos el registro canónico escrito por nosotros. Así un archivo
	# corrupto no llega al parser de ConfigFile ni produce errores de motor.
	return file.get_as_text() == _record(version).encode_to_text()


func mark_seen(version: String) -> Error:
	if version.is_empty():
		return ERR_INVALID_PARAMETER
	return _record(version).save(storage_path)


func _record(version: String) -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("introduction", "schema_version", 1)
	config.set_value("introduction", "version", version)
	config.set_value("introduction", "seen", true)
	return config
