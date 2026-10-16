extends Node

# Temporary read-only observer: no game methods, state setters, input injection,
# event consumption, extra controls, timers affecting gameplay or scene changes.
var _sequence: int = 0
var _sample_elapsed: float = 0.0
var _last_sample: String = ""

func _ready() -> void:
	EconomyManager.ammo_pool_changed.connect(_on_ammo_changed)
	EconomyManager.deploy_or_reload_rejected.connect(_on_rejected)
	GameStateManager.game_state_changed.connect(_on_state_changed)
	call_deferred("_initial_report")

func _initial_report() -> void:
	_emit("INITIAL", _snapshot())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_sequence += 1
		_emit("INPUT_PRE", {"sequence": _sequence, "kind": "mouse", "position": _xy(event.position), "state": _snapshot()})
		_after_input(_sequence)
	elif event is InputEventScreenTouch and event.pressed:
		_sequence += 1
		_emit("INPUT_PRE", {"sequence": _sequence, "kind": "touch", "position": _xy(event.position), "state": _snapshot()})
		_after_input(_sequence)

func _after_input(sequence: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_emit("INPUT_POST", {"sequence": sequence, "state": _snapshot()})

func _process(delta: float) -> void:
	_sample_elapsed += delta
	if _sample_elapsed < 0.25:
		return
	_sample_elapsed = 0.0
	var data: Dictionary = _snapshot()
	var serialized: String = JSON.stringify(data)
	if serialized != _last_sample:
		_last_sample = serialized
		_emit("SAMPLE", data)

func _on_ammo_changed(value: int) -> void:
	_emit("AMMO", {"amount": value})

func _on_rejected(reason: String) -> void:
	_emit("REJECTED", {"reason": reason})

func _on_state_changed(value: int) -> void:
	_emit("TERMINAL_OR_STATE", {"state": value})

func _xy(value: Vector2) -> Array:
	return [snappedf(value.x, 0.01), snappedf(value.y, 0.01)]

func _snapshot() -> Dictionary:
	var level: Node = get_parent()
	var tilemap: TileMap = level.get_node("Tablero") as TileMap
	var soldiers: Array = []
	var pickups: Array = []
	var pending: Array[Node] = [level]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current.is_queued_for_deletion():
			continue
		if current is Soldado:
			var cell: Vector2i = current.get("_grid_cell")
			soldiers.append({"name": str(current.name), "position": _xy(current.global_position), "cell": [cell.x, cell.y], "rifle_ammo": current.get("_current_ammo")})
		elif current is AmmoPickup:
			var pickup_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(current.global_position))
			pickups.append({"name": str(current.name), "position": _xy(current.global_position), "cell": [pickup_cell.x, pickup_cell.y], "amount": current.amount})
		for child: Node in current.get_children():
			pending.append(child)
	var board: RefCounted = level.get("_board_manager")
	var occupied: Dictionary = board.get("_occupied_cells")
	var occupied_cells: Array = []
	for cell: Vector2i in occupied:
		occupied_cells.append([cell.x, cell.y])
	return {"ammo": EconomyManager.collected_ammo, "soldiers": soldiers, "pickups": pickups, "occupied_cells": occupied_cells, "game_state": GameStateManager.get("_current_state")}

func _emit(kind: String, data: Dictionary) -> void:
	print("WEB_OBSERVER ", JSON.stringify({"kind": kind, "ticks_ms": Time.get_ticks_msec(), "data": data}))
