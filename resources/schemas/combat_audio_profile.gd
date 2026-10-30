## Configuración sonora autorada e inmutable; no contiene estado jugable.
class_name CombatAudioProfile
extends Resource

@export var rifle: Array[AudioStream] = []
@export var enemy_death: Array[AudioStream] = []
@export var soldier_death: Array[AudioStream] = []
@export var victory: Array[AudioStream] = []
@export var defeat: Array[AudioStream] = []
@export_range(1, 32, 1) var combat_voice_count: int = 8
@export var volume_db: Dictionary[StringName, float] = {
	&"rifle": -18.0,
	&"enemy_death": -18.0,
	&"soldier_death": -18.0,
	&"victory": -12.0,
	&"defeat": -12.0,
}
@export var pitch_range: Vector2 = Vector2(0.97, 1.03)
@export_range(0.0, 6.0, 0.1) var volume_variation_db: float = 1.5
