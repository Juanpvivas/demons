## Memoria JSON local de dos slots. No carga Resources desde datos del usuario.
class_name CommanderMemoryStore
extends RefCounted

const _LIMIT_BYTES: int = 128 * 1024
const _MAX_GENERATION: int = 9007199254740991
const _MEMORY_FIELDS: Array[String] = ["schema_version", "policy_version", "compatibility_id", "generation", "last_match_id", "cells"]
const _CONFIG_FIELDS: Array[String] = ["schema_version", "policy_version", "phase_end_waves", "prior_score", "learning_rate", "retention_per_match", "confidence_visits", "max_effective_visits", "exploration_share", "weight_gain"]
const _ENEMY_FIELDS: Array[String] = ["max_health", "move_speed", "melee_damage", "rifle_range", "rifle_damage", "rifle_interval", "ammo_drop"]
const _SOLDIER_FIELDS: Array[String] = ["max_health", "max_ammo", "damage_per_shot", "fire_rate", "rifle_range", "machete_base_damage", "machete_moral_multiplier", "machete_moral_per_kill", "machete_heal_per_kill", "moral_per_kill", "advance_speed", "return_speed", "deploy_ammo_cost"]

var storage_base_path: String = ""
var transient: bool = false
## exists/size -> {error,value}; read(path,max_bytes) -> {error,text};
## write(path,text) y remove(path) -> {error}. write incluye flush/cierre.
var io_backend: Object = null
## Fuentes completas y confiables: waves, soldier_stats y board. Nunca se mutan.
var compatibility_sources: Dictionary = {}

var _memory: Dictionary = {}
var _config: CommanderConfig
var _compatibility_id: String = ""
var _active_path: String = ""
var _disk_signature: Array = []
var _loaded: bool = false
var _load_status: String = "INVALID"


func load_compatible(config: CommanderConfig) -> Dictionary:
	var fingerprint := _fingerprint(config)
	if fingerprint.is_empty():
		_loaded = false
		return _result("INVALID")
	_config = config.duplicate(true) as CommanderConfig
	var same_content := fingerprint == _compatibility_id
	_compatibility_id = fingerprint
	if transient:
		if not same_content or _memory.is_empty():
			_memory = _neutral()
		_loaded = true
		_load_status = "TRANSIENT"
		return _result("TRANSIENT")
	var disk := _scan_slots()
	_disk_signature = disk.signature.duplicate(true)
	_active_path = disk.get("path", "")
	_load_status = disk.status
	_memory = _neutral()
	if disk.has("memory"):
		var latest: Dictionary = disk.memory
		if latest.schema_version != _config.schema_version \
				or latest.policy_version != _config.policy_version \
				or latest.compatibility_id != _compatibility_id:
			_load_status = "INCOMPATIBLE"
			# La experiencia es neutral; la generación conserva el orden de los slots.
			_memory.generation = latest.generation
		else:
			_memory = latest.duplicate(true)
	_loaded = true
	return _result(_load_status)


func save(candidate: Dictionary, expected_generation: int) -> Dictionary:
	if not _loaded or _config == null or not _valid_candidate(candidate):
		return _save_result("INVALID")
	var next_memory: Dictionary = candidate.memory.duplicate(true)
	if next_memory.compatibility_id != _compatibility_id:
		return _save_result("INCOMPATIBLE")
	if expected_generation != _memory.generation \
			or next_memory.generation != expected_generation \
			or candidate.match_id == _memory.last_match_id:
		return _save_result("CONFLICT")
	if expected_generation >= _MAX_GENERATION:
		return _save_result("INVALID")
	next_memory.generation = expected_generation + 1
	if transient:
		_memory = next_memory
		return _save_result("OK", true, false)
	if _load_status in ["IO_ERROR", "CONFLICT"]:
		return _save_result(_load_status)
	var current := _scan_slots()
	if current.status == "IO_ERROR":
		return _save_result("IO_ERROR")
	if current.signature != _disk_signature or current.status == "CONFLICT":
		return _save_result("CONFLICT")
	var target := _path("b") if _active_path == _path("a") else _path("a")
	var payload := JSON.stringify(next_memory, "", true, true)
	var envelope := JSON.stringify({"payload": payload, "sha256": payload.sha256_text()}, "", true, true)
	if envelope.to_utf8_buffer().size() > _LIMIT_BYTES:
		return _save_result("INVALID")
	var written := _io_write(target, envelope)
	if written.get("error", FAILED) != OK:
		return _save_result("IO_ERROR")
	var verified := _read_slot(target)
	if verified.status != "OK" or verified.get("memory") != next_memory:
		return _save_result("IO_ERROR")
	# Sólo el slot reabierto y validado se convierte en experiencia publicada.
	_memory = next_memory
	_active_path = target
	var target_index: int = 0 if target == _path("a") else 1
	_disk_signature[target_index] = verified.signature
	_load_status = "OK"
	return _save_result("OK", true, true)


func clear() -> Dictionary:
	return {} # El borrado se implementa en T019, tras su propio RED.


func _neutral() -> Dictionary:
	return {"schema_version": 1, "policy_version": 1,
		"compatibility_id": _compatibility_id, "generation": 0,
		"last_match_id": "", "cells": {}}


func _result(status: String) -> Dictionary:
	return {"status": status, "memory": _memory.duplicate(true)}


func _save_result(status: String, applied: bool = false, saved: bool = false) -> Dictionary:
	var result := _result(status)
	result.applied = applied
	result.saved = saved
	return result


func _path(slot: String) -> String:
	var base := "user://" if storage_base_path.is_empty() else storage_base_path
	return base.path_join("commander_memory_%s.json" % slot)


func _scan_slots() -> Dictionary:
	var slots: Array[Dictionary] = [_read_slot(_path("a")), _read_slot(_path("b"))]
	var result := {"status": "MISSING", "signature": [slots[0].signature, slots[1].signature]}
	var valid: Array[int] = []
	for index: int in 2:
		if slots[index].status == "IO_ERROR":
			result.status = "IO_ERROR"
			return result
		if slots[index].status == "OK":
			valid.append(index)
		elif slots[index].status == "INVALID":
			result.status = "INVALID"
	if valid.is_empty():
		return result
	var selected: int = valid[0]
	if valid.size() == 2:
		var first: Dictionary = slots[0].memory
		var second: Dictionary = slots[1].memory
		if first.generation == second.generation and first != second:
			result.status = "CONFLICT"
			return result
		if second.generation > first.generation:
			selected = 1
	result.status = "OK"
	result.memory = slots[selected].memory
	result.path = _path("a" if selected == 0 else "b")
	return result


func _read_slot(path: String) -> Dictionary:
	var exists := _io_exists(path)
	if exists.get("error", FAILED) != OK:
		return {"status": "IO_ERROR", "signature": "IO_ERROR"}
	if not exists.get("value", false):
		return {"status": "MISSING", "signature": "MISSING"}
	var size_result := _io_size(path)
	if size_result.get("error", FAILED) != OK:
		return {"status": "IO_ERROR", "signature": "IO_ERROR"}
	var size_bytes: int = size_result.get("value", -1)
	if size_bytes < 0 or size_bytes > _LIMIT_BYTES:
		return {"status": "INVALID", "signature": "SIZE:%d" % size_bytes}
	var read_result := _io_read(path, _LIMIT_BYTES)
	if read_result.get("error", FAILED) != OK:
		return {"status": "IO_ERROR", "signature": "IO_ERROR"}
	var text: String = read_result.get("text", "")
	var result := {"status": "INVALID", "signature": text.sha256_text()}
	if text.to_utf8_buffer().size() != size_bytes:
		return result
	var outer: Variant = JSON.parse_string(text)
	if not _exact_fields(outer, ["payload", "sha256"]):
		return result
	if not outer.payload is String or not _valid_hash(outer.sha256) \
			or outer.payload.sha256_text() != outer.sha256:
		return result
	var payload: Variant = JSON.parse_string(outer.payload)
	if not _valid_memory(payload):
		return result
	result.status = "OK"
	result.memory = payload
	return result


func _valid_candidate(candidate: Dictionary) -> bool:
	if not _exact_fields(candidate, ["changed", "memory", "match_id"]) \
			or not candidate.changed is bool or not candidate.changed \
			or not candidate.match_id is String or candidate.match_id.is_empty() \
			or candidate.match_id.length() > 64 or not _valid_memory(candidate.memory):
		return false
	return candidate.memory.last_match_id == candidate.match_id \
		and candidate.memory.schema_version == _config.schema_version \
		and candidate.memory.policy_version == _config.policy_version


func _valid_memory(value: Variant) -> bool:
	if not _exact_fields(value, _MEMORY_FIELDS):
		return false
	if not _integer_in(value.schema_version, 1, _MAX_GENERATION) \
			or not _integer_in(value.policy_version, 1, _MAX_GENERATION) \
			or not _integer_in(value.generation, 0, _MAX_GENERATION) \
			or not _valid_hash(value.compatibility_id) \
			or not value.last_match_id is String or value.last_match_id.length() > 64 \
			or not value.cells is Dictionary or value.cells.size() > 360:
		return false
	for key: Variant in value.cells:
		if not _valid_context(key):
			return false
		var cell: Variant = value.cells[key]
		if not _exact_fields(cell, ["q", "n"]) \
				or not _number_in(cell.q, 0.0, 1.0) or not _number_in(cell.n, 0.0, 20.0):
			return false
	return true


func _exact_fields(value: Variant, fields: Array) -> bool:
	return value is Dictionary and value.size() == fields.size() and value.has_all(fields)


func _number_in(value: Variant, lower: float, upper: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and value >= lower and value <= upper


func _integer_in(value: Variant, lower: int, upper: int) -> bool:
	return _number_in(value, lower, upper) and float(value) == floor(float(value))


func _valid_hash(value: Variant) -> bool:
	if not value is String or value.length() != 64:
		return false
	for character: String in value:
		if not character in "0123456789abcdef":
			return false
	return true


func _valid_context(value: Variant) -> bool:
	if not value is String:
		return false
	var parts: PackedStringArray = value.split("/")
	return parts.size() == 5 and parts[0] in ["early", "middle", "late"] \
		and parts[1] in ["A", "R"] and parts[2] in ["0", "1", "2", "3", "4"] \
		and parts[3] in ["empty", "armed", "unarmed", "returning"] \
		and parts[4] in ["zero", "one", "two_plus"]


func _fingerprint(config: CommanderConfig) -> String:
	if not _valid_config(config):
		return ""
	var sources := compatibility_sources
	if sources.is_empty():
		var waves: Array[WaveData] = []
		for number: int in range(1, 11):
			waves.append(load("res://resources/waves/nivel_montecalvo_oleada_%02d.tres" % number))
		sources = {"waves": waves,
			"soldier_stats": load("res://resources/units/soldado_base_stats.tres"),
			"board": load("res://resources/levels/monte_calvo_board.tres")}
	if not sources.get("waves") is Array or sources.waves.size() != 10 \
			or not sources.get("soldier_stats") is UnitStats or not sources.get("board") is LaneBoardConfig:
		return ""
	var schedules: Array = []
	for wave: Variant in sources.waves:
		if not wave is WaveData:
			return ""
		var spawns: Array = []
		for entry: WaveSpawnEntry in wave.spawn_entries:
			if entry == null or entry.enemy_stats == null or entry.count <= 0 \
					or not is_finite(entry.spawn_interval) or entry.spawn_interval <= 0.0:
				return ""
			var stats := _fields(entry.enemy_stats, _ENEMY_FIELDS)
			if stats.is_empty():
				return ""
			var role: String = "R" if entry.enemy_stats.rifle_range > 0.0 \
				and entry.enemy_stats.rifle_damage > 0 and entry.enemy_stats.rifle_interval > 0.0 else "A"
			for ordinal: int in entry.count:
				spawns.append({"role": role, "interval": entry.spawn_interval, "stats": stats})
		schedules.append({"wave_number": wave.wave_number, "spawns": spawns})
	var board: LaneBoardConfig = sources.board
	var homes: Array = []
	var spawns: Array = []
	for cell: Vector2i in board.home_cells:
		homes.append([cell.x, cell.y])
	for position: Vector2 in board.spawn_positions:
		if not is_finite(position.x) or not is_finite(position.y):
			return ""
		spawns.append([position.x, position.y])
	var geometry := {"design_rect": _rect_values(board.design_rect),
		"cell_size": [board.cell_size.x, board.cell_size.y],
		"defended_rect": _rect_values(board.defended_rect),
		"home_cells": homes, "spawn_positions": spawns}
	var soldier := _fields(sources.soldier_stats, _SOLDIER_FIELDS)
	if soldier.is_empty() or geometry.design_rect.is_empty() or geometry.defended_rect.is_empty():
		return ""
	# JSON compacto, claves ordenadas y precisión completa; arrays conservan orden.
	var canonical := {"config": _fields(config, _CONFIG_FIELDS),
		"categories": {"phase": ["early", "middle", "late"], "role": ["A", "R"],
			"lane": [0, 1, 2, 3, 4], "defense": ["empty", "armed", "unarmed", "returning"],
			"load": ["zero", "one", "two_plus"]},
		"waves": schedules, "soldier_stats": soldier, "board": geometry}
	return JSON.stringify(canonical, "", true, true).sha256_text()


func _fields(resource: Resource, names: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for field: String in names:
		var value: Variant = resource.get(field)
		if value is float and not is_finite(value):
			return {}
		result[field] = value
	return result


func _rect_values(rect: Rect2) -> Array:
	var values: Array = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	for value: float in values:
		if not is_finite(value):
			return []
	return values


func _valid_config(config: CommanderConfig) -> bool:
	if config == null or config.schema_version != 1 or config.policy_version != 1 \
			or config.phase_end_waves.size() != 3 or config.phase_end_waves[0] <= 0 \
			or config.phase_end_waves[0] >= config.phase_end_waves[1] \
			or config.phase_end_waves[1] >= config.phase_end_waves[2] or config.phase_end_waves[2] != 10:
		return false
	return config.prior_score == 0.5 \
		and _number_in(config.learning_rate, 0.0, 0.15) and config.learning_rate > 0.0 \
		and _number_in(config.retention_per_match, 0.0, 1.0) and config.retention_per_match < 1.0 \
		and _number_in(config.confidence_visits, 0.0, config.max_effective_visits) and config.confidence_visits > 0.0 \
		and _number_in(config.max_effective_visits, config.confidence_visits, 20.0) \
		and _number_in(config.exploration_share, 0.25, 1.0) and config.exploration_share < 1.0 \
		and _number_in(config.weight_gain, 0.0, 0.25) and config.weight_gain > 0.0


func _io_exists(path: String) -> Dictionary:
	if io_backend != null:
		return io_backend.call("exists", path)
	return {"error": OK, "value": FileAccess.file_exists(path)}


func _io_size(path: String) -> Dictionary:
	if io_backend != null:
		return io_backend.call("size", path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": FileAccess.get_open_error()}
	var size_bytes := file.get_length()
	var error := file.get_error()
	file.close()
	return {"error": error, "value": size_bytes}


func _io_read(path: String, max_bytes: int) -> Dictionary:
	if io_backend != null:
		return io_backend.call("read", path, max_bytes)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": FileAccess.get_open_error()}
	var size_bytes := file.get_length()
	if size_bytes > max_bytes:
		file.close()
		return {"error": ERR_FILE_CANT_READ}
	var bytes := file.get_buffer(size_bytes)
	var error := file.get_error()
	file.close()
	if bytes.size() != size_bytes:
		return {"error": ERR_FILE_CANT_READ}
	var text := bytes.get_string_from_utf8()
	if text.to_utf8_buffer() != bytes:
		return {"error": ERR_FILE_CORRUPT}
	return {"error": error, "text": text}


func _io_write(path: String, text: String) -> Dictionary:
	if io_backend != null:
		return io_backend.call("write", path, text)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": FileAccess.get_open_error(), "stage": "open"}
	var bytes := text.to_utf8_buffer()
	file.store_buffer(bytes)
	var error := file.get_error()
	if error == OK and file.get_position() != bytes.size():
		error = ERR_FILE_CANT_WRITE
	if error != OK:
		file.close()
		return {"error": error, "stage": "write"}
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK:
		return {"error": error, "stage": "flush"}
	# close() no ofrece Error en Godot; su efecto y la relectura se verifican.
	return {"error": ERR_FILE_CANT_WRITE if file.is_open() else OK, "stage": "close"}
