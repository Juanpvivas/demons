## Geometría compartida de un tablero por carriles, sin estado de partida.
## La integración del nivel se implementa después de las pruebas RED.
class_name LaneBoardConfig
extends Resource

@export_group("Geometría")
@export var design_rect: Rect2 = Rect2()
@export var cell_size: Vector2i = Vector2i.ZERO
@export var defended_rect: Rect2 = Rect2()

@export_group("Carriles")
@export var home_cells: Array[Vector2i] = []
@export var spawn_positions: Array[Vector2] = []
