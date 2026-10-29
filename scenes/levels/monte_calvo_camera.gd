## Centra el rectángulo completo sin mover actores, grid o geometría del nivel.
extends Camera2D

## La UI lee el canvas vigente después de aplicar el encuadre.
signal framing_changed

@export var board_config: LaneBoardConfig = preload("res://resources/levels/monte_calvo_board.tres")


func _ready() -> void:
	get_viewport().size_changed.connect(_update_framing)
	_update_framing()


func _update_framing() -> void:
	position = board_config.design_rect.get_center()
	force_update_scroll()
	framing_changed.emit()
