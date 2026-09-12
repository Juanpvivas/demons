extends GutTest
## T014: test del BoardManager (`core/board_manager.gd`) — cubre que
## `is_cell_free` refleja correctamente ocupación/liberación de celdas
## (depende de T012).
##
## BoardManager no es autoload (es una utilidad instanciable por-nivel, ver
## `core/board_manager.gd`), así que se testea directo con `BoardManager.new()`.
##
## Cubre el escenario observable relevante de `spec.md` (FR-001, FR-010 y el
## Edge Case de liberar la celda del tablero al derrotar un soldado), no los
## detalles internos del diccionario `_occupied_cells`.

var _board: BoardManager


func before_each() -> void:
	_board = BoardManager.new()


## --- is_cell_free: estado inicial ---

func test_is_cell_free_is_true_for_any_cell_on_a_fresh_board() -> void:
	# Given: un BoardManager recién creado, sin ninguna ocupación registrada
	# Then: cualquier celda consultada está libre
	assert_true(
		_board.is_cell_free(Vector2i(0, 0)),
		"una celda nunca ocupada debe reportarse libre"
	)
	assert_true(
		_board.is_cell_free(Vector2i(5, 3)),
		"otra celda arbitraria nunca ocupada también debe reportarse libre"
	)


## --- occupy_cell: éxito y reflejo en is_cell_free ---

func test_occupy_cell_marks_the_cell_as_no_longer_free() -> void:
	# Given: una celda libre
	var cell := Vector2i(2, 4)
	var soldado := Node.new()
	autofree(soldado)

	# When: se despliega un soldado en esa celda
	var occupied := _board.occupy_cell(cell, soldado)

	# Then: occupy_cell reporta éxito y la celda deja de estar libre
	assert_true(occupied, "occupy_cell debe retornar true al ocupar una celda libre")
	assert_false(
		_board.is_cell_free(cell),
		"is_cell_free debe reflejar que la celda quedó ocupada tras occupy_cell"
	)


func test_occupy_cell_does_not_affect_other_cells() -> void:
	# Given/When: se ocupa una celda puntual
	var occupied_cell := Vector2i(1, 1)
	var other_cell := Vector2i(1, 2)
	var soldado := Node.new()
	autofree(soldado)
	_board.occupy_cell(occupied_cell, soldado)

	# Then: una celda vecina no ocupada sigue libre
	assert_true(
		_board.is_cell_free(other_cell),
		"ocupar una celda no debe afectar la disponibilidad de celdas distintas"
	)


## --- occupy_cell: rechazo si ya está ocupada ---

func test_occupy_cell_returns_false_when_cell_already_occupied() -> void:
	# Given: una celda ya ocupada por un primer soldado
	var cell := Vector2i(3, 3)
	var first_soldado := Node.new()
	var second_soldado := Node.new()
	autofree(first_soldado)
	autofree(second_soldado)
	_board.occupy_cell(cell, first_soldado)

	# When: se intenta ocupar la misma celda con un segundo nodo
	var occupied_again := _board.occupy_cell(cell, second_soldado)

	# Then: el segundo intento es rechazado
	assert_false(
		occupied_again,
		"occupy_cell debe retornar false si la celda ya está ocupada"
	)


func test_occupy_cell_does_not_overwrite_existing_occupant_when_rejected() -> void:
	# Given: una celda ocupada por first_soldado
	var cell := Vector2i(3, 3)
	var first_soldado := Node.new()
	var second_soldado := Node.new()
	autofree(first_soldado)
	autofree(second_soldado)
	_board.occupy_cell(cell, first_soldado)

	# When: se intenta (sin éxito) ocupar la celda con otro nodo
	_board.occupy_cell(cell, second_soldado)

	# Then: el ocupante original se mantiene, no fue reemplazado
	assert_eq(
		_board.get_occupant(cell), first_soldado,
		"un occupy_cell rechazado no debe reemplazar al ocupante existente"
	)


## --- free_cell: liberación y reflejo en is_cell_free ---

func test_free_cell_makes_the_cell_free_again() -> void:
	# Given: una celda ocupada (ej. soldado desplegado)
	var cell := Vector2i(7, 2)
	var soldado := Node.new()
	autofree(soldado)
	_board.occupy_cell(cell, soldado)

	# When: se libera la celda (ej. el soldado fue derrotado, spec.md Edge Cases)
	_board.free_cell(cell)

	# Then: is_cell_free vuelve a reportar la celda como disponible
	assert_true(
		_board.is_cell_free(cell),
		"is_cell_free debe reflejar que la celda quedó libre tras free_cell"
	)


func test_cell_can_be_occupied_again_after_being_freed() -> void:
	# Given: una celda ocupada y luego liberada
	var cell := Vector2i(7, 2)
	var first_soldado := Node.new()
	var second_soldado := Node.new()
	autofree(first_soldado)
	autofree(second_soldado)
	_board.occupy_cell(cell, first_soldado)
	_board.free_cell(cell)

	# When: se despliega un nuevo soldado en la misma celda ya liberada
	var occupied := _board.occupy_cell(cell, second_soldado)

	# Then: la nueva ocupación se acepta con éxito
	assert_true(
		occupied,
		"una celda liberada debe poder volver a ocuparse con éxito"
	)
	assert_eq(
		_board.get_occupant(cell), second_soldado,
		"el nuevo ocupante debe quedar registrado tras reocupar una celda liberada"
	)


func test_free_cell_on_an_already_free_cell_is_idempotent_and_does_not_error() -> void:
	# Given: una celda que nunca fue ocupada
	var cell := Vector2i(9, 9)

	# When/Then: liberarla no debe fallar ni alterar su estado libre
	_board.free_cell(cell)
	assert_true(
		_board.is_cell_free(cell),
		"free_cell sobre una celda ya libre no debe romper nada (idempotente)"
	)


## --- get_occupant ---

func test_get_occupant_returns_the_node_that_occupies_the_cell() -> void:
	# Given: una celda ocupada por un soldado específico
	var cell := Vector2i(4, 4)
	var soldado := Node.new()
	autofree(soldado)
	_board.occupy_cell(cell, soldado)

	# Then: get_occupant retorna exactamente ese nodo
	assert_eq(
		_board.get_occupant(cell), soldado,
		"get_occupant debe retornar el nodo ocupante correcto para una celda ocupada"
	)


func test_get_occupant_returns_null_for_a_free_cell() -> void:
	# Given: una celda nunca ocupada
	var cell := Vector2i(6, 6)

	# Then: get_occupant retorna null
	assert_null(
		_board.get_occupant(cell),
		"get_occupant debe retornar null para una celda libre"
	)


func test_get_occupant_returns_null_after_the_cell_is_freed() -> void:
	# Given: una celda ocupada y luego liberada
	var cell := Vector2i(4, 4)
	var soldado := Node.new()
	autofree(soldado)
	_board.occupy_cell(cell, soldado)
	_board.free_cell(cell)

	# Then: get_occupant ya no devuelve el nodo anterior
	assert_null(
		_board.get_occupant(cell),
		"get_occupant debe retornar null tras liberar la celda, no el ocupante anterior"
	)
