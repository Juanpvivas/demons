extends GutTest
## 005/T005: datos autorados inertes. Ya pueden estar GREEN en T003;
## no constituyen RED de la integración del nivel.
const Config := preload("res://resources/levels/monte_calvo_board.tres")


func test_authored_board_has_five_distinct_home_cells_and_aligned_entries() -> void:
	var expected_homes: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5)]
	assert_eq(Config.home_cells, expected_homes, "Solo cinco plazas, una por fila")
	assert_eq(Config.spawn_positions.size(), 5)
	if Config.spawn_positions.size() != 5:
		return
	for lane in 5:
		assert_eq(Config.spawn_positions[lane], Vector2(1008, 144 + 96 * lane), "Entrada derecha alineada con su plaza")
	assert_eq(Config.cell_size, Vector2i(96, 96))


func test_authored_design_and_left_defense_cover_all_five_rows() -> void:
	assert_eq(Config.design_rect, Rect2(0, 0, 1152, 648))
	assert_eq(Config.defended_rect, Rect2(48, 96, 48, 480))
	for lane in 5:
		var row_y := 144.0 + 96.0 * lane
		assert_true(Config.defended_rect.has_point(Vector2(72, row_y)), "La defensa cruza cada fila")
		assert_false(Config.defended_rect.has_point(Vector2(144, row_y)), "La plaza no está dentro de la zona de derrota")
