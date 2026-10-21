extends GutTest
## T003: contrato observable del instrumento optativo; no asserts de FPS.

const Probe := preload("res://tools/performance/probe.gd")
const SoldierScene := preload("res://scenes/units/Soldado.tscn")
const EnemyScene := preload("res://scenes/enemies/EnemigoBase.tscn")
const PickupScene := preload("res://scenes/levels/AmmoPickup.tscn")
const KEYS := ["engine_build", "renderer", "scenario", "viewport", "surface", "pacing", "configuration", "observer"]
const START := 1000000
var _probe: Probe


func before_each() -> void:
	_probe = autofree(Probe.new())


func _config(id := "run-b", window := 9000) -> Dictionary:
	return {
		"run_id": id, "revision": "base", "artifact": "base.pck", "window_usec": window,
		"conditions": {
			"engine_build": "4.7.1.standard", "renderer": "gl_compatibility/fixture",
			"scenario": {"id": "constant", "seed": 17}, "viewport": [1152, 648, 1.0],
			"surface": {"canvas": [1152, 648], "dpr": 1.0},
			"pacing": {"cap": 0, "vsync": false, "focus": true},
			"configuration": {"fixture": "v1", "flags": []}, "observer": "probe-v1/detailed",
		},
		"expected_counts": {"soldiers": 1, "enemies_active": 1, "enemies_inactive": 0, "pickups": 1, "queued": 0},
	}


func _snapshot(id := "run-b", phase := "initial", at := START, offset := 0) -> Dictionary:
	# Observaciones sintéticas independientes: no se copian de config/expected.
	var values := {
		"engine_build": "4.7.1.standard", "renderer": "gl_compatibility/fixture",
		"scenario": {"id": "constant", "seed": 17}, "viewport": [1152, 648, 1.0],
		"surface": {"canvas": [1152, 648], "dpr": 1.0},
		"pacing": {"cap": 0, "vsync": false, "focus": true},
		"configuration": {"fixture": "v1", "flags": []}, "observer": "probe-v1/detailed",
	}
	var observed := {}
	for key: String in values:
		observed[key] = {"value": values[key], "source": "%s:collector:%s" % [id, key], "availability": "observed"}
	return {
		"counts": {"soldiers": 1, "enemies_active": 1, "enemies_inactive": 0, "pickups": 1, "queued": 0},
		"entities": [
			{"key": "owner:1", "type": "soldier", "instance_id": 101 + offset, "activation": 1,
				"position": [144.0, 144.0], "health": 30, "ammo": 10, "morale": 7.0, "movement": "HOME"},
			{"key": "opponent:1", "type": "enemy", "instance_id": 102 + offset, "activation": 1,
				"position": [500.0, 144.0], "health": 10, "state": "active"},
			{"key": "supply:1", "type": "pickup", "instance_id": 103 + offset, "activation": 0,
				"position": [384.0, 144.0], "amount": 3},
		],
		"observation": {"run_id": id, "phase": phase, "at_usec": at, "conditions": observed},
	}


func _record_four(start := START) -> void:
	# Intervalos 4,1,3,2 ms. No se entrega ningún delta de juego al probe.
	for elapsed: int in [4000, 5000, 8000, 10000]:
		_probe.record_wall_interval(start + elapsed)


func _valid(report: Dictionary) -> void:
	assert_has(report, "valid", "el resultado debe declarar validez explícita")
	assert_true(report.get("valid", false), "la ejecución compatible debe ser válida")
	assert_eq(report.get("errors", ["missing"]), [], "una ejecución válida no conserva errores previos")


func _invalid(report: Dictionary, reason: String) -> void:
	# El stub {} nunca puede pasar esta comprobación mediante un fallback false.
	assert_has(report, "valid", "un rechazo debe declarar valid=false")
	assert_false(report.get("valid", true), "la entrada incompatible no puede aceptarse")
	var errors: Variant = report.get("errors", [])
	assert_true(errors is Array, "errors debe ser una lista de motivos")
	if not errors is Array:
		return
	assert_gt(errors.size(), 0, "un rechazo debe explicar su causa")
	assert_string_contains(str(errors).to_lower(), reason)
	assert_true(not report.has("frame_ms") or report["frame_ms"].is_empty(), "un run inválido no publica tiempos cero ficticios")


func _report(id := "run-b", start := START, offset := 0, changes := {}) -> Dictionary:
	var config := _config(id)
	var initial := _snapshot(id, "initial", start, offset)
	var final := _snapshot(id, "final", start + 10000, offset)
	for key: String in changes:
		config["conditions"][key] = changes[key]
		initial["observation"]["conditions"][key]["value"] = changes[key]
		final["observation"]["conditions"][key]["value"] = changes[key]
	assert_true(_probe.start(config, initial, start), "precondición: el run debe aceptar sus observaciones verificadas")
	_record_four(start)
	return _probe.finish(final)


func test_wall_microseconds_produce_milliseconds_and_nearest_rank_percentiles() -> void:
	var report := _report()
	_valid(report)
	assert_eq(report.get("sample_count", -1), 4, "debe conservar también el frame que cruza la ventana")
	assert_eq(report.get("duration_usec", -1), 10000, "duración real de4+1+3+2ms, no9000us solicitados")
	var metrics: Dictionary = report.get("frame_ms", {})
	for key: String in {"mean": 2.5, "p50": 2.0, "p95": 4.0, "p99": 4.0, "max": 4.0}:
		var expected := {"mean": 2.5, "p50": 2.0, "p95": 4.0, "p99": 4.0, "max": 4.0}
		assert_almost_eq(float(metrics.get(key, -1.0)), expected[key], 0.000001, key)
	assert_eq(report.get("frame_intervals_usec", []), [4000, 1000, 3000, 2000], "la serie original permite recalcular los percentiles")


func test_two_intervals_are_enough_when_the_requested_window_is_complete() -> void:
	assert_true(_probe.start(_config("run-b", 10000), _snapshot(), START))
	_probe.record_wall_interval(START + 1000)
	_probe.record_wall_interval(START + 10000)
	var report := _probe.finish(_snapshot("run-b", "final", START + 10000))
	_valid(report)
	assert_eq(report.get("sample_count", -1), 2)
	assert_almost_eq(float(report.get("frame_ms", {}).get("mean", -1.0)), 5.0, 0.000001)


func test_empty_and_single_interval_runs_are_rejected_with_sample_reason() -> void:
	for samples: int in [0, 1]:
		assert_true(_probe.start(_config(), _snapshot(), START))
		if samples == 1:
			_probe.record_wall_interval(START + 10000)
		_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), "sample")


func test_short_window_is_not_reported_as_a_successful_run() -> void:
	assert_true(_probe.start(_config(), _snapshot(), START))
	_probe.record_wall_interval(START + 1000)
	_probe.record_wall_interval(START + 2000)
	_invalid(_probe.finish(_snapshot("run-b", "final", START + 2000)), "window")


func test_zero_or_regressive_clock_invalidates_even_after_later_good_samples() -> void:
	for bad_time: int in [START + 1000, START + 999]:
		assert_true(_probe.start(_config(), _snapshot(), START))
		_probe.record_wall_interval(START + 1000)
		_probe.record_wall_interval(bad_time)
		_record_four()
		_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), "interval")


func test_initial_count_oracle_is_independent_of_the_snapshot() -> void:
	var config := _config()
	config["expected_counts"]["pickups"] = 19
	assert_false(_probe.start(config, _snapshot(), START))
	_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), "pickups")


func test_required_expected_conditions_cannot_be_omitted() -> void:
	for key: String in KEYS:
		var config := _config()
		config["conditions"].erase(key)
		assert_false(_probe.start(config, _snapshot(), START), key)
		_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), key)


func test_initial_observation_missing_or_different_is_not_replaced_by_expected() -> void:
	for key: String in KEYS:
		for missing: bool in [true, false]:
			var initial := _snapshot()
			if missing:
				initial["observation"]["conditions"].erase(key)
			else:
				initial["observation"]["conditions"][key]["value"] = "different actual value"
			assert_false(_probe.start(_config(), initial, START), key)
			_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), key)


func test_unavailable_unknown_and_unsourced_observations_are_rejected() -> void:
	for status: String in ["unknown", "unavailable", ""]:
		var initial := _snapshot()
		initial["observation"]["conditions"]["renderer"]["availability"] = status
		assert_false(_probe.start(_config(), initial, START))
		_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), "renderer")
	var initial := _snapshot()
	initial["observation"]["conditions"]["surface"]["source"] = ""
	assert_false(_probe.start(_config(), initial, START))
	_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), "surface")


func test_initial_run_phase_and_timestamp_must_match_the_boundary() -> void:
	for key: String in ["run_id", "phase", "at_usec"]:
		var initial := _snapshot()
		initial["observation"][key] = START - 1 if key == "at_usec" else "stale"
		assert_false(_probe.start(_config(), initial, START), key)
		_invalid(_probe.finish(_snapshot("run-b", "final", START + 10000)), key)


func test_final_conditions_are_rechecked_for_missing_different_or_unavailable_values() -> void:
	for key: String in KEYS:
		for problem: String in ["missing", "different", "unavailable", "unsourced"]:
			assert_true(_probe.start(_config(), _snapshot(), START))
			_record_four()
			var final := _snapshot("run-b", "final", START + 10000)
			if problem == "missing":
				final["observation"]["conditions"].erase(key)
			elif problem == "different":
				final["observation"]["conditions"][key]["value"] = "changed during window"
			else:
				final["observation"]["conditions"][key]["availability" if problem == "unavailable" else "source"] = ""
			_invalid(_probe.finish(final), key)


func test_final_run_phase_and_timestamp_cannot_refer_to_another_boundary() -> void:
	for key: String in ["run_id", "phase", "at_usec"]:
		assert_true(_probe.start(_config(), _snapshot(), START))
		_record_four()
		var final := _snapshot("run-b", "final", START + 10000)
		final["observation"][key] = START + 9999 if key == "at_usec" else "stale"
		_invalid(_probe.finish(final), key)


func test_retirement_or_reactivation_within_a_constant_run_invalidates_the_cohort() -> void:
	for field: String in ["instance_id", "activation", "health", "position"]:
		assert_true(_probe.start(_config(), _snapshot(), START))
		_record_four()
		var final := _snapshot("run-b", "final", START + 10000)
		final["entities"][0][field] = [145.0, 144.0] if field == "position" else 99
		_invalid(_probe.finish(final), field)


func test_configuration_and_snapshots_are_copied_instead_of_becoming_live_authority() -> void:
	var config := _config()
	var initial := _snapshot()
	assert_true(_probe.start(config, initial, START))
	config["run_id"] = "outside mutation"
	config["conditions"]["viewport"][0] = 1
	initial["counts"]["soldiers"] = 999
	initial["entities"][0]["health"] = -1
	_record_four()
	var report := _probe.finish(_snapshot("run-b", "final", START + 10000))
	_valid(report)
	assert_eq(report.get("run_id", ""), "run-b")
	assert_eq(report.get("initial_snapshot", {}).get("counts", {}).get("soldiers", -1), 1)


func test_finish_is_idempotent_and_returns_copies_that_cannot_rewrite_history() -> void:
	var report := _report()
	_valid(report)
	var original := report.duplicate(true)
	report["frame_ms"] = {"mean": -1.0}
	_probe.record_wall_interval(START + 999999)
	assert_eq(_probe.finish({}), original, "cerrar de nuevo no consume otro snapshot ni el frame posterior")


func test_starting_another_run_removes_old_samples_context_and_errors() -> void:
	assert_false(_probe.start(_config(), {}, START))
	var report := _report("run-c", START + 100000, 1000)
	_valid(report)
	assert_eq(report.get("run_id", ""), "run-c")
	assert_eq(report.get("sample_count", -1), 4)
	assert_eq(report.get("frame_intervals_usec", []), [4000, 1000, 3000, 2000])


func test_compare_accepts_distinct_revisions_artifacts_instance_ids_sources_and_times() -> void:
	var base := _report()
	var candidate := _report("run-c", START + 100000, 1000)
	candidate["revision"] = "candidate"
	candidate["artifact"] = "candidate.pck"
	_valid(_probe.compare_runs(base, candidate))


func test_compare_rejects_equally_valid_runs_with_different_observed_conditions() -> void:
	var base := _report()
	for key: String in KEYS:
		var candidate := _report("run-c", START + 100000, 1000, {key: "other effective condition"})
		_invalid(_probe.compare_runs(base, candidate), key)


func test_compare_revalidates_observations_instead_of_trusting_valid_or_expected() -> void:
	for key: String in KEYS:
		var base := _report()
		var candidate := _report("run-c", START + 100000, 1000)
		# El informe viene de finish; la manipulación debe invalidar la comparación.
		var final := _snapshot("run-c", "final", START + 110000, 1000)
		final["observation"]["conditions"].erase(key)
		candidate["final_snapshot"] = final
		_invalid(_probe.compare_runs(base, candidate), key)


func test_compare_rejects_a_different_logical_cohort_and_an_invalid_run() -> void:
	var base := _report()
	var candidate := _report("run-c", START + 100000, 1000)
	var final := _snapshot("run-c", "final", START + 110000, 1000)
	final["entities"][0]["key"] = "another owner"
	candidate["final_snapshot"] = final
	_invalid(_probe.compare_runs(base, candidate), "cohort")
	candidate["valid"] = false
	candidate["errors"] = ["collector rejected input"]
	_invalid(_probe.compare_runs(base, candidate), "valid")


func _entity_by_id(snapshot: Dictionary, id: int) -> Dictionary:
	for entity: Dictionary in snapshot.get("entities", []):
		if entity.get("instance_id", -1) == id:
			return entity
	return {}


func test_recursive_inventory_counts_hidden_active_nested_inactive_and_queued_without_mutation() -> void:
	var root := Node2D.new()
	root.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(root)
	var pool := Node2D.new()
	pool.name = "NestedPool"
	root.add_child(pool)
	var soldier := SoldierScene.instantiate() as Soldado
	root.add_child(soldier)
	soldier.position = Vector2(144, 144)
	soldier.set("_current_morale", 7.0)
	var active := EnemyScene.instantiate() as Enemigo
	pool.add_child(active)
	active.prepare_for_spawn(active.stats, Vector2(500, 144), 0)
	active.hide()
	var inactive := EnemyScene.instantiate() as Enemigo
	pool.add_child(inactive)
	inactive.on_pool_released()
	var pickup := PickupScene.instantiate() as AmmoPickup
	pickup.amount = 3
	pool.add_child(pickup)
	pickup.position = Vector2(384, 144)
	var queued := EnemyScene.instantiate() as Enemigo
	pool.add_child(queued)
	queued.queue_free()
	var before := [soldier.get_reload_state().duplicate(true), active.get("_current_health"), active.activation_generation,
		active.position, active.visible, inactive.is_targetable(), pickup.amount, pickup.position, EconomyManager.collected_ammo]
	var snapshot: Dictionary = _probe.snapshot_recursive(root)
	assert_eq(snapshot.get("counts", {}), {"soldiers": 1, "enemies_active": 1, "enemies_inactive": 1, "pickups": 1, "queued": 1})
	var supply := _entity_by_id(snapshot, pickup.get_instance_id())
	assert_eq(supply.get("type", ""), "pickup")
	assert_eq(supply.get("amount", -1), 3)
	assert_false(str(supply.get("key", "")).is_empty(), "el drop anidado tiene identidad lógica")
	var enemy := _entity_by_id(snapshot, active.get_instance_id())
	assert_eq(enemy.get("activation", -1), active.activation_generation, "un actor oculto sigue activo")
	var after := [soldier.get_reload_state().duplicate(true), active.get("_current_health"), active.activation_generation,
		active.position, active.visible, inactive.is_targetable(), pickup.amount, pickup.position, EconomyManager.collected_ammo]
	assert_eq(after, before, "leer el inventario no mueve, revive, cobra ni cambia stats o visibilidad")
	supply["amount"] = 999
	assert_eq(pickup.amount, 3, "los valores devueltos no son autoridad viva del pickup")
