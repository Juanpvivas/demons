## Interfaz neutral de memoria; no accede a archivos ni publica experiencia.
class_name CommanderMemoryStore
extends RefCounted

var storage_base_path: String = ""
var transient: bool = false

## Puerto opcional: exists/size devuelven {error, value}; read(path, max_bytes)
## devuelve {error, text}; write(path, text) y remove(path) devuelven {error}.
## Un error de write incluye apertura, escritura, flush o cierre fallidos.
var io_backend: Object = null

## Inyección completa de waves, soldier_stats y board; vacío reserva las fuentes
## autoradas para la implementación posterior, sin cargarlas en este setup.
var compatibility_sources: Dictionary = {}


func load_compatible(_config: CommanderConfig) -> Dictionary:
	return {}


func save(_candidate: Dictionary, _expected_generation: int) -> Dictionary:
	return {}


func clear() -> Dictionary:
	return {}
