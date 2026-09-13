## BoardManager: estructura de datos simple que mantiene qué celdas de la
## cuadrícula del tablero están ocupadas y por qué nodo (`research.md` §5).
## No es autoload — el estado de ocupación es por-nivel, no global de la
## partida completa; cada nivel instancia el suyo (`docs/ARCHITECTURE.md`
## §4.5, mismo precedente que `core/object_pool.gd`).
##
## Deliberadamente no depende de `TileMap` ni de ninguna escena: es una
## estructura de datos testeable con GUT sin necesidad de árbol de escena
## (`research.md` §5, alternativa rechazada). Quien la usa (ej.
## `nivel_monte_calvo.gd`) es responsable de traducir posiciones de mundo a
## celdas (`Vector2i`) antes de consultarla.
##
## Uso típico:
##   var board := BoardManager.new()
##   if board.is_cell_free(cell):
##       board.occupy_cell(cell, soldado)
##   ...
##   board.free_cell(cell)  # ej. al derrotar al soldado (spec.md Edge Cases)
class_name BoardManager
extends RefCounted

## Celdas ocupadas del tablero: `Vector2i` (celda) → `Node` (ocupante,
## normalmente un `Soldado`). Ausencia de una clave equivale a celda libre.
var _occupied_cells: Dictionary = {}


## `true` si la celda no tiene ocupante registrado — condición que
## `nivel_monte_calvo.gd` DEBE consultar antes de desplegar un soldado
## nuevo (FR-001, FR-010).
func is_cell_free(cell: Vector2i) -> bool:
	return not _occupied_cells.has(cell)


## Registra `node` como ocupante de `cell`. Retorna `false` sin modificar
## nada si la celda ya estaba ocupada (el llamador debe consultar
## `is_cell_free()` antes, pero este método no confía ciegamente en eso).
func occupy_cell(cell: Vector2i, node: Node) -> bool:
	if not is_cell_free(cell):
		return false
	_occupied_cells[cell] = node
	return true


## Libera `cell`, quedando disponible para un futuro `occupy_cell()`. No
## falla si la celda ya estaba libre (idempotente). Se usa, por ejemplo, al
## derrotar un soldado (`spec.md` Edge Cases: "libera esa posición del
## tablero").
func free_cell(cell: Vector2i) -> void:
	_occupied_cells.erase(cell)


## Nodo ocupante de `cell`, o `null` si está libre. Conveniencia para no
## acceder al diccionario interno directamente desde fuera de esta clase.
func get_occupant(cell: Vector2i) -> Node:
	return _occupied_cells.get(cell)
