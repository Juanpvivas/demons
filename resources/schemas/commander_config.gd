## Parámetros compartidos e inmutables del comandante; sin memoria de partida.
class_name CommanderConfig
extends Resource

@export_group("Compatibilidad")
@export_range(1, 1, 1) var schema_version: int = 0
@export_range(1, 1, 1) var policy_version: int = 0

@export_group("Contexto")
@export var phase_end_waves: Array[int] = []

@export_group("Aprendizaje")
@export_range(0.5, 0.5, 0.01) var prior_score: float = 0.0
@export_range(0.001, 0.15, 0.001) var learning_rate: float = 0.0
@export_range(0.0, 0.999, 0.001) var retention_per_match: float = 0.0
@export_range(0.001, 20.0, 0.001) var confidence_visits: float = 0.0
@export_range(0.001, 20.0, 0.001) var max_effective_visits: float = 0.0

@export_group("Selección")
@export_range(0.25, 0.999, 0.001) var exploration_share: float = 0.0
@export_range(0.001, 0.25, 0.001) var weight_gain: float = 0.0
