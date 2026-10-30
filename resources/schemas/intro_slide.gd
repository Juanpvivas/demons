## Datos autorados de una escena; el reproductor mantiene su estado aparte.
class_name IntroSlide
extends Resource

@export var image: Texture2D
@export_multiline var subtitle: String = ""
@export_multiline var companion_subtitle: String = ""
@export var caption: String = ""
@export var narration: AudioStream
@export var companion_voice: AudioStream
@export_range(0.0, 120.0, 0.1) var minimum_duration: float = 0.0
@export_range(1.0, 1.2, 0.001) var start_zoom: float = 1.0
@export_range(1.0, 1.2, 0.001) var end_zoom: float = 1.0
@export var start_offset: Vector2 = Vector2.ZERO
@export var end_offset: Vector2 = Vector2.ZERO
