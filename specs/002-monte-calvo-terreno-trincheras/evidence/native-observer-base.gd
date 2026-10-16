extends Node

# Temporary read-only observer: no game methods, state setters, input injection,
# event consumption, interactive controls, timers affecting gameplay or scene changes.
var _sequence: int = 0
var _sample_elapsed: float = 0.0
var _last_sample: String = ""
var _readout: Label
var _input_pre: Dictionary = {}
var _last_gesture: String = "Sin gestos"
var _frame_deltas_ms: Array[float] = []
var _perf_window: float = 0.0
var _perf_elapsed: float = 0.0
var _first_process_ticks_ms: int = 0
var _last_perf: String = "FPS: esperando muestra"

func _ready() -> void:
	# Read-only instrumentation, outside production. These Controls cannot
	# consume input and only display values already logged by this observer.
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_readout = Label.new()
	_readout.position = Vector2(12, 8)
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout.focus_mode = Control.FOCUS_NONE
	_readout.add_theme_font_size_override("font_size", 19)
	_readout.add_theme_color_override("font_color", Color.WHITE)
	_readout.add_theme_color_override("font_outline_color", Color.BLACK)
	_readout.add_theme_constant_override("outline_size", 7)
	layer.add_child(_readout)
	for marker: Dictionary in [{"name": "[A]", "position": Vector2(224, 514)}, {"name": "[B]", "position": Vector2(608, 514)}]:
		var label := Label.new()
		label.text = marker["name"]
		label.position = marker["position"]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.focus_mode = Control.FOCUS_NONE
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(0.3, 1.0, 1.0))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		layer.add_child(label)
	EconomyManager.ammo_pool_changed.connect(_on_ammo_changed)
	EconomyManager.deploy_or_reload_rejected.connect(_on_rejected)
	GameStateManager.game_state_changed.connect(_on_state_changed)
	call_deferred("_initial_report")

func _initial_report() -> void:
	_emit("INITIAL", _snapshot())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_sequence += 1
		_input_pre[_sequence] = _snapshot()
		_emit("INPUT_PRE", {"sequence": _sequence, "kind": "mouse", "position": _xy(event.position), "state": _snapshot()})
		_after_input(_sequence)
	elif event is InputEventScreenTouch and event.pressed:
		_sequence += 1
		_input_pre[_sequence] = _snapshot()
		_emit("INPUT_PRE", {"sequence": _sequence, "kind": "touch", "position": _xy(event.position), "state": _snapshot()})
		_after_input(_sequence)

func _after_input(sequence: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var after: Dictionary = _snapshot()
	var before: Dictionary = _input_pre.get(sequence, after)
	_last_gesture = "Gesto %s: reserva %s -> %s; soldados %s -> %s" % [sequence, before["ammo"], after["ammo"], before["soldiers"].size(), after["soldiers"].size()]
	_input_pre.erase(sequence)
	_emit("INPUT_POST", {"sequence": sequence, "state": after})

func _process(delta: float) -> void:
	if _first_process_ticks_ms == 0:
		_first_process_ticks_ms = Time.get_ticks_msec()
	_frame_deltas_ms.append(delta * 1000.0)
	_perf_elapsed += delta
	_perf_window += delta
	if _perf_window >= 5.0:
		_perf_window = 0.0
		var ordered: Array[float] = _frame_deltas_ms.duplicate()
		ordered.sort()
		var p95: float = ordered[int((ordered.size() - 1) * 0.95)]
		_last_perf = "Obs FPS %.1f | p95 %.1fms | %.0fs" % [ordered.size() / _perf_elapsed, p95, _perf_elapsed]
		_emit("PERFORMANCE", {"frames": ordered.size(), "elapsed_process_seconds": _perf_elapsed, "engine_fps": Engine.get_frames_per_second(), "mean_fps_from_delta": ordered.size() / _perf_elapsed, "p50_delta_ms": ordered[int((ordered.size() - 1) * 0.5)], "p95_delta_ms": p95, "max_delta_ms": ordered[-1], "first_process_engine_ticks_ms": _first_process_ticks_ms})
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
	if _readout != null:
		var status: Dictionary = _snapshot()
		var states: Array[String] = ["JUGANDO", "PAUSA", "GANADA", "PERDIDA"]
		_readout.text = "OBSERVACION TEMPORAL / NO PRODUCCION\nReserva: %s | Soldados: %s | %s\n%s\n%s" % [status["ammo"], status["soldiers"].size(), states[status["game_state"]], _last_gesture, _last_perf]
	print("WEB_OBSERVER ", JSON.stringify({"kind": kind, "ticks_ms": Time.get_ticks_msec(), "data": data}))
