## Secuencia narrativa inmutable; no contiene progreso del jugador.
class_name IntroSequence
extends Resource

@export var version: String = "la_carta_v1"
@export var slides: Array[IntroSlide] = []
@export_range(0.0, 2.0, 0.05) var transition_duration: float = 0.5
