## Interfaz neutral de memoria; no accede a archivos ni publica experiencia.
class_name CommanderMemoryStore
extends RefCounted

var storage_base_path: String = ""
var transient: bool = false


func load_compatible(_config: CommanderConfig) -> Dictionary:
	return {}


func save(_candidate: Dictionary, _expected_generation: int) -> Dictionary:
	return {}


func clear() -> Dictionary:
	return {}
