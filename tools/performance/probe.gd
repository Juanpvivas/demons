## Instrumento optativo de QA: sólo conserva lecturas, nunca gobierna la partida.
extends Node

const _CONDITIONS := ["engine_build", "renderer", "scenario", "viewport", "surface", "pacing", "configuration", "observer"]
const _COUNTS := ["soldiers", "enemies_active", "enemies_inactive", "pickups", "queued"]

var _config: Dictionary = {}
var _initial: Dictionary = {}
var _intervals: Array[int] = []
var _errors: Array[String] = []
var _started: bool = false
var _closed: bool = false
var _start_at: int = 0
var _last_at: int = 0
var _report: Dictionary = {}


func start(config: Dictionary, initial_snapshot: Dictionary, at_usec: int) -> bool:
	_errors.clear()
	_intervals.clear()
	_report.clear()
	_started = true
	_closed = false
	_start_at = at_usec
	_last_at = at_usec
	_config = _copy_input(config, "configuration", _errors)
	_initial = _copy_input(initial_snapshot, "initial_snapshot", _errors)
	_validate_config(_config, _errors)
	if at_usec < 0:
		_error(_errors, "at_usec: negative initial clock")
	_validate_snapshot(_config, _initial, "initial", at_usec, true, _errors)
	return _errors.is_empty()


func record_wall_interval(at_usec: int) -> void:
	if not _started or _closed or not _errors.is_empty():
		return
	if at_usec <= _last_at:
		_error(_errors, "interval: clock must increase")
		return
	if _last_at - _start_at >= int(_config.get("window_usec", 0)):
		return
	_intervals.append(at_usec - _last_at)
	_last_at = at_usec


func snapshot_recursive(root: Node) -> Dictionary:
	var result := {"counts": {"soldiers": 0, "enemies_active": 0, "enemies_inactive": 0, "pickups": 0, "queued": 0}, "entities": []}
	var ordinals := {"soldier": 0, "enemy": 0, "pickup": 0}
	if is_instance_valid(root):
		_capture(root, result, ordinals)
	return result


func finish(final_snapshot: Dictionary) -> Dictionary:
	if _closed:
		return _report.duplicate(true)
	var final := _copy_input(final_snapshot, "final_snapshot", _errors)
	if not _started:
		_error(_errors, "start: no run was started")
	_validate_snapshot(_config, final, "final", _last_at, false, _errors)
	_compare_cohort(_initial, final, true, _errors)
	_validate_intervals(_intervals, _config.get("window_usec", 0), _errors)
	_report = _config.duplicate(true)
	_report.merge({"initial_snapshot": _initial.duplicate(true), "final_snapshot": final,
		"valid": _errors.is_empty(), "errors": _errors.duplicate(), "sample_count": _intervals.size(),
		"duration_usec": _last_at - _start_at, "frame_intervals_usec": _intervals.duplicate(),
		"frame_ms": _frame_stats(_intervals) if _errors.is_empty() else {}}, true)
	_closed = true
	return _report.duplicate(true)


func compare_runs(base: Dictionary, candidate: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	for run: Dictionary in [base, candidate]:
		if not _serializable(run):
			_error(errors, "valid: report contains unsupported values")
			continue
		if run.get("valid") != true or not run.get("errors") is Array or not run.get("errors", []).is_empty():
			_error(errors, "valid: comparison requires valid runs")
		_validate_config(run, errors)
		var initial: Dictionary = _dictionary(run.get("initial_snapshot"))
		var final: Dictionary = _dictionary(run.get("final_snapshot"))
		var initial_clock: Variant = _dictionary(initial.get("observation")).get("at_usec")
		var initial_at: int = initial_clock if initial_clock is int else -1
		_validate_snapshot(run, initial, "initial", initial_at, true, errors)
		var series: Array = run.get("frame_intervals_usec", []) if run.get("frame_intervals_usec", []) is Array else []
		var duration: int = _validate_intervals(series, run.get("window_usec", 0), errors)
		_validate_snapshot(run, final, "final", initial_at + duration, false, errors)
		if run.get("sample_count") != series.size() or run.get("duration_usec") != duration:
			_error(errors, "sample: report disagrees with original intervals")
		_compare_cohort(initial, final, true, errors)
	for key: String in _CONDITIONS:
		if _observed_value(base, key) != _observed_value(candidate, key):
			_error(errors, "%s: observed conditions differ between runs" % key)
	if base.get("window_usec") != candidate.get("window_usec"):
		_error(errors, "window_usec: requested windows differ")
	_compare_cohort(_dictionary(base.get("initial_snapshot")), _dictionary(candidate.get("initial_snapshot")), false, errors)
	return {"valid": errors.is_empty(), "errors": errors}


func _validate_config(config: Dictionary, errors: Array[String]) -> void:
	for key: String in ["run_id", "revision", "artifact"]:
		if not _source_present(config.get(key)):
			_error(errors, "%s: missing context" % key)
	if not config.get("window_usec") is int or config.get("window_usec", 0) <= 0:
		_error(errors, "window_usec: positive integer required")
	var conditions := _dictionary(config.get("conditions"))
	for key: String in _CONDITIONS:
		if not conditions.has(key) or conditions[key] == null or not _serializable(conditions[key]) \
				or (conditions[key] is String and not _source_present(conditions[key])):
			_error(errors, "%s: expected condition missing or unsupported" % key)
	_validate_counts(_dictionary(config.get("expected_counts")), errors)


func _validate_snapshot(config: Dictionary, snapshot: Dictionary, phase: String, boundary: int,
		exact_time: bool, errors: Array[String]) -> void:
	var observation := _dictionary(snapshot.get("observation"))
	for key: String in ["run_id", "phase"]:
		var expected: Variant = config.get("run_id") if key == "run_id" else phase
		if not observation.has(key) or observation[key] != expected:
			_error(errors, "%s: wrong %s observation" % [key, phase])
	var at: Variant = observation.get("at_usec")
	if not at is int or at < 0 or (at != boundary if exact_time else at < boundary):
		_error(errors, "at_usec: wrong %s boundary" % phase)
	var expected_conditions := _dictionary(config.get("conditions"))
	var observed := _dictionary(observation.get("conditions"))
	for key: String in _CONDITIONS:
		var reading := _dictionary(observed.get(key))
		if reading.get("availability") != "observed" or not _source_present(reading.get("source")) \
				or not reading.has("value") or not expected_conditions.has(key) \
				or reading.get("value") != expected_conditions.get(key):
			_error(errors, "%s: invalid %s observation" % [key, phase])
	var counts := _dictionary(snapshot.get("counts"))
	_validate_counts(counts, errors)
	var expected_counts := _dictionary(config.get("expected_counts"))
	for key: String in _COUNTS:
		if counts.get(key) != expected_counts.get(key):
			_error(errors, "%s: count differs from independent oracle" % key)
	_validate_entities(snapshot, errors)


func _validate_counts(counts: Dictionary, errors: Array[String]) -> void:
	for key: String in _COUNTS:
		if not counts.get(key) is int or counts.get(key, -1) < 0:
			_error(errors, "%s: nonnegative integer count required" % key)


func _validate_entities(snapshot: Dictionary, errors: Array[String]) -> void:
	if not snapshot.get("entities") is Array:
		_error(errors, "cohort: entities missing")
		return
	var seen: Dictionary = {}
	var identities: Dictionary = {}
	var counts := {"soldiers": 0, "enemies_active": 0, "enemies_inactive": 0, "pickups": 0, "queued": 0}
	for entry: Variant in snapshot["entities"]:
		if not entry is Dictionary:
			_error(errors, "cohort: unsupported entity")
			continue
		var entity: Dictionary = entry
		var key: Variant = entity.get("key")
		if not _source_present(key) or seen.has(key):
			_error(errors, "cohort.key: missing or duplicated logical role")
		seen[key] = true
		var instance: Variant = entity.get("instance_id")
		if not instance is int or instance <= 0 or identities.has(instance):
			_error(errors, "cohort.instance_id: invalid or duplicated identity")
		identities[instance] = true
		if not entity.get("activation") is int or entity.get("activation", -1) < 0:
			_error(errors, "cohort.activation: invalid generation")
		var position: Variant = entity.get("position")
		if not position is Array or position.size() != 2 \
				or not (position[0] is int or position[0] is float) \
				or not (position[1] is int or position[1] is float):
			_error(errors, "cohort.position: global coordinates missing")
		var kind: Variant = entity.get("type")
		var fields: Array = {"soldier": ["health", "ammo", "morale", "movement"],
			"enemy": ["health", "state"], "pickup": ["amount"]}.get(kind, [])
		for field: String in fields:
			if not entity.has(field) or entity[field] == null:
				_error(errors, "cohort.%s: applicable value missing" % field)
		if not ["soldier", "enemy", "pickup"].has(kind):
			_error(errors, "cohort.type: unknown actor")
		elif entity.get("state") == "queued":
			counts["queued"] += 1
		elif kind == "enemy":
			if not ["active", "inactive"].has(entity.get("state")):
				_error(errors, "cohort.state: enemy activity missing")
			else:
				counts["enemies_active" if entity["state"] == "active" else "enemies_inactive"] += 1
		else:
			counts["soldiers" if kind == "soldier" else "pickups"] += 1
	for key: String in _COUNTS:
		if counts[key] != _dictionary(snapshot.get("counts")).get(key):
			_error(errors, "%s: inventory disagrees with count" % key)


func _compare_cohort(initial: Dictionary, final: Dictionary, identity: bool, errors: Array[String]) -> void:
	var before := _entities_by_key(initial)
	var after := _entities_by_key(final)
	if before.size() != after.size():
		_error(errors, "cohort: population changed")
	for key: Variant in before:
		if not after.has(key):
			_error(errors, "cohort.key: logical role changed")
			continue
		var a: Dictionary = before[key]
		var b: Dictionary = after[key]
		for field: Variant in a.keys() + b.keys():
			if not identity and field in ["instance_id", "activation"]:
				continue
			if not a.has(field) or not b.has(field) or a[field] != b[field]:
				_error(errors, "cohort.%s: value changed for %s" % [field, key])
	if initial.get("counts") != final.get("counts"):
		_error(errors, "cohort: counts differ")


func _entities_by_key(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var entities: Variant = snapshot.get("entities", [])
	if entities is Array:
		for entry: Variant in entities:
			if entry is Dictionary:
				result[entry.get("key")] = entry
	return result


func _observed_value(run: Dictionary, key: String) -> Variant:
	var snapshot := _dictionary(run.get("initial_snapshot"))
	var conditions := _dictionary(_dictionary(snapshot.get("observation")).get("conditions"))
	return _dictionary(conditions.get(key)).get("value")


func _validate_intervals(series: Array, window: Variant, errors: Array[String]) -> int:
	var total: int = 0
	if series.size() < 2:
		_error(errors, "sample: at least two intervals required")
	for interval: Variant in series:
		if not interval is int or interval <= 0:
			_error(errors, "interval: positive integer required")
		else:
			total += interval
	if not window is int or window <= 0 or total < window:
		_error(errors, "window: requested duration not reached")
	return total


func _frame_stats(series: Array[int]) -> Dictionary:
	var ordered: Array[int] = series.duplicate()
	ordered.sort()
	var total: int = 0
	for interval: int in ordered:
		total += interval
	return {"mean": float(total) / ordered.size() / 1000.0,
		"p50": ordered[int(ceil(0.50 * ordered.size())) - 1] / 1000.0,
		"p95": ordered[int(ceil(0.95 * ordered.size())) - 1] / 1000.0,
		"p99": ordered[int(ceil(0.99 * ordered.size())) - 1] / 1000.0,
		"max": ordered[-1] / 1000.0}


func _capture(node: Node, result: Dictionary, ordinals: Dictionary) -> void:
	var entity: Dictionary = {}
	if node is Soldado or node is Enemigo or node is AmmoPickup:
		var kind: String = "soldier" if node is Soldado else ("enemy" if node is Enemigo else "pickup")
		var actor := node as Node2D
		# El escenario conserva el orden de roles; la clave no contiene IDs de proceso.
		entity = {"key": "%s:%d" % [kind, ordinals[kind]], "type": kind,
			"instance_id": node.get_instance_id(), "activation": 0,
			"position": [actor.global_position.x, actor.global_position.y]}
		ordinals[kind] += 1
		if node is Soldado:
			var state := (node as Soldado).get_reload_state()
			entity.merge({"health": state["health"], "ammo": state["ammo"], "morale": state["morale"], "movement": state["movement_state"]})
		elif node is Enemigo:
			var enemy := node as Enemigo
			entity.merge({"activation": enemy.activation_generation, "health": enemy.get("_current_health"),
				"state": "active" if enemy.is_targetable() else "inactive"}, true)
		else:
			entity["amount"] = (node as AmmoPickup).amount
		if node.is_queued_for_deletion():
			entity["state"] = "queued"
			result["counts"]["queued"] += 1
		elif kind == "enemy":
			result["counts"]["enemies_active" if entity["state"] == "active" else "enemies_inactive"] += 1
		else:
			result["counts"]["soldiers" if kind == "soldier" else "pickups"] += 1
		result["entities"].append(entity)
	for child: Node in node.get_children():
		_capture(child, result, ordinals)


func _source_present(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty() and not ["unknown", "unavailable"].has(value.to_lower())


func _dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _copy_input(value: Dictionary, key: String, errors: Array[String]) -> Dictionary:
	if not _serializable(value):
		_error(errors, "%s: only serializable values are allowed" % key)
		return {}
	return value.duplicate(true)


func _serializable(value: Variant, depth: int = 0) -> bool:
	if depth > 64:
		return false
	if value is Dictionary:
		for key: Variant in value:
			if not key is String or not _serializable(value[key], depth + 1):
				return false
		return true
	if value is Array:
		for item: Variant in value:
			if not _serializable(item, depth + 1):
				return false
		return true
	return typeof(value) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]


func _error(errors: Array[String], message: String) -> void:
	if not errors.has(message):
		errors.append(message)
