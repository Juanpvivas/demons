## Molde neutral de configuración; los parámetros autorados llegan tras RED.
class_name CommanderConfig
extends Resource

@export_group("Compatibilidad")
@export var schema_version: int = 0
@export var policy_version: int = 0

@export_group("Contexto")
@export var phase_end_waves: Array[int] = []

@export_group("Aprendizaje")
@export var prior_score: float = 0.0
@export var learning_rate: float = 0.0
@export var retention_per_match: float = 0.0
@export var confidence_visits: float = 0.0
@export var max_effective_visits: float = 0.0

@export_group("Selección")
@export var exploration_share: float = 0.0
@export var weight_gain: float = 0.0
