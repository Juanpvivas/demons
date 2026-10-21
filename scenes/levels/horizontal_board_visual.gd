## Guía discreta de carriles; las piezas de trinchera representan las plazas.
## Solo representa datos del tablero;
## no posee input, física, ocupación, economía ni reglas de combate.
class_name LaneBoardVisual
extends Node2D

@export var board_config: LaneBoardConfig:
	set(value):
		board_config = value
		queue_redraw()


func _draw() -> void:
	if board_config == null:
		return
	var cell_size := Vector2(board_config.cell_size)
	for lane in board_config.home_cells.size():
		var home := Rect2(Vector2(board_config.home_cells[lane]) * cell_size, cell_size)
		var end_x := board_config.spawn_positions[lane].x + cell_size.x * 0.5
		var band := Rect2(home.position, Vector2(end_x - home.position.x, cell_size.y))
		var shade := Color(0.85, 0.77, 0.52, 0.10 if lane % 2 == 0 else 0.035)
		draw_rect(band, shade)
		draw_rect(band, Color(0.85, 0.79, 0.57, 0.35), false, 1.0)
		var label_position := home.position + Vector2(-28, cell_size.y * 0.5 + 7)
		draw_string(ThemeDB.fallback_font, label_position, str(lane + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.95, 0.87, 0.66))
