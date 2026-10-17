## Centra el avance horizontal sin desplazar el origen vertical del nivel.
extends Camera2D

const _COMBAT_AXIS_X: float = 576.0


func _ready() -> void:
	get_viewport().size_changed.connect(_update_framing)
	_update_framing()


func _update_framing() -> void:
	position = Vector2(_COMBAT_AXIS_X, get_viewport_rect().size.y * 0.5)
	force_update_scroll()
