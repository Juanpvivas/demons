extends GutTest

const ConfigScript = preload("res://resources/schemas/commander_config.gd")
const SessionScript = preload("res://core/commander_session.gd")
const SoldierScript = preload("res://scenes/units/soldado.gd")


func _config() -> CommanderConfig:
	var config := ConfigScript.new()
	config.schema_version = 1
	config.policy_version = 1
	config.phase_end_waves.assign([3, 7, 10])
	config.prior_score = 0.5
	config.learning_rate = 0.15
	config.retention_per_match = 0.98
	config.confidence_visits = 3.0
	config.max_effective_visits = 20.0
	config.exploration_share = 0.25
	config.weight_gain = 0.25
	return config


func _memory(cells: Dictionary = {}) -> Dictionary:
	return {
		"schema_version": 1, "policy_version": 1,
		"compatibility_id": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		"generation": 0, "last_match_id": "", "cells": cells.duplicate(true),
	}


func _snapshot(wave: int = 1, role: String = "A", defense: String = "empty",
		load_value: int = 0) -> Dictionary:
	var defenders: Array[Dictionary] = []
	for lane in 5:
		defenders.append({
			"lane_id": lane, "alive": defense != "empty", "health": 15,
			"ammo": 0 if defense == "unarmed" else 5,
			"mode": SoldierScript.SoldierMode.MELEE if defense == "unarmed" else SoldierScript.SoldierMode.RIFLE,
			"movement_state": SoldierScript.MovementState.RETURNING if defense == "returning" else SoldierScript.MovementState.HOME,
		})
	return {"wave_number": wave, "role": role, "defenders": defenders,
		"lane_loads": [load_value, load_value, load_value, load_value, load_value]}


func _session(seed_value: int = 42, memory: Dictionary = {}, config: CommanderConfig = null) -> CommanderSession:
	var session := SessionScript.new()
	session.begin_match("selector-test", seed_value, _config() if config == null else config,
		_memory() if memory.is_empty() else memory)
	return session


func _decision(session: CommanderSession, snapshot: Dictionary = {}) -> Dictionary:
	var decision := session.choose_lane(_snapshot() if snapshot.is_empty() else snapshot)
	var shape_ok := decision.has_all(["ordinal", "lane", "context", "token"])
	assert_true(shape_ok, "La configuración válida debe producir una propuesta pública de carril")
	if not shape_ok:
		return {}
	assert_eq(typeof(decision.lane), TYPE_INT)
	assert_between(decision.lane, 0, 4)
	return decision


func _confirm(session: CommanderSession, decision: Dictionary, ordinal: int) -> bool:
	var applied := session.register_spawn(decision, 1000 + ordinal, 1, 1008.0, 96.0)
	assert_true(applied, "Una propuesta propia debe confirmar su aparición una sola vez")
	return applied


func _probabilities(session: CommanderSession) -> Dictionary:
	var diagnostic := session.get_decision_snapshot()
	assert_true(diagnostic.has("probabilities"), "El diagnóstico público expone probabilidades para contrastar el contrato")
	return diagnostic.get("probabilities", {})


func test_valid_configuration_proposes_only_lane_context_ordinal_and_token() -> void:
	var decision := _decision(_session())
	if decision.is_empty():
		return
	var keys := decision.keys()
	keys.sort()
	assert_eq(keys, ["context", "lane", "ordinal", "token"])
	assert_eq(decision.ordinal, 0)
	assert_eq(decision.context, "early/A/%d/empty/zero" % decision.lane)


func test_invalid_configuration_never_produces_an_attack(params = use_parameters([
	["schema_version", 0], ["policy_version", 0],
	["phase_end_waves", [3, 7]], ["phase_end_waves", [3, 3, 10]],
	["phase_end_waves", [0, 7, 10]], ["phase_end_waves", [3, 7, 9]],
	["prior_score", 0.4], ["learning_rate", 0.0], ["learning_rate", 0.2],
	["retention_per_match", -0.1], ["retention_per_match", 1.0],
	["confidence_visits", 0.0], ["confidence_visits", 21.0],
	["max_effective_visits", 2.0], ["max_effective_visits", 21.0],
	["exploration_share", 0.2], ["exploration_share", 1.0],
	["weight_gain", 0.0], ["weight_gain", 0.3], ["weight_gain", NAN],
	["confidence_visits", INF],
])) -> void:
	var config := _config()
	if params[0] == "phase_end_waves":
		config.phase_end_waves.assign(params[1])
	else:
		config.set(params[0], params[1])
	var session := _session(42, _memory(), config)
	assert_true(session.choose_lane(_snapshot()).is_empty(), "Config inválida no debe ocultarse como decisión válida")


func test_context_categories_cover_all_360_finite_keys() -> void:
	var contexts: Dictionary = {}
	for phase_wave in [["early", 1], ["middle", 4], ["late", 8]]:
		for role in ["A", "R"]:
			for defense in ["empty", "armed", "unarmed", "returning"]:
				for load_case in [["zero", 0], ["one", 1], ["two_plus", 3]]:
					var session := _session()
					for ordinal in 5:
						var decision := _decision(session, _snapshot(phase_wave[1], role, defense, load_case[1]))
						if decision.is_empty():
							return
						var expected := "%s/%s/%d/%s/%s" % [phase_wave[0], role, decision.lane, defense, load_case[0]]
						assert_eq(decision.context, expected)
						contexts[decision.context] = true
						if not _confirm(session, decision, ordinal):
							return
	assert_eq(contexts.size(), 360)


func test_phase_boundaries_follow_resource_and_not_fixed_wave_ranges() -> void:
	var config := _config()
	config.phase_end_waves.assign([2, 8, 10])
	for wave_phase in [[2, "early"], [3, "middle"], [8, "middle"], [9, "late"]]:
		var decision := _decision(_session(42, _memory(), config), _snapshot(wave_phase[0]))
		if decision.is_empty():
			return
		assert_eq(decision.context, "%s/A/%d/empty/zero" % [wave_phase[1], decision.lane])


func test_empty_and_returning_defense_take_precedence_over_ammo_and_weapon() -> void:
	var snapshot := _snapshot(1, "A", "returning", 2)
	for defender in snapshot.defenders:
		defender.alive = false
	var absent := _decision(_session(), snapshot)
	if absent.is_empty():
		return
	assert_eq(absent.context, "early/A/%d/empty/two_plus" % absent.lane)
	var returning := _decision(_session(), _snapshot(1, "A", "returning", 2))
	if returning.is_empty():
		return
	assert_eq(returning.context, "early/A/%d/returning/two_plus" % returning.lane)


func test_all_seeded_99_spawn_sequences_have_19_permutations_and_four_distinct_tail_lanes() -> void:
	var variants: Dictionary = {}
	for seed_value in 256:
		var session := _session(seed_value)
		var block: Array[int] = []
		var sequence: Array[int] = []
		for ordinal in 99:
			var wave := 1 if ordinal < 3 else (2 if ordinal < 7 else 3)
			var decision := _decision(session, _snapshot(wave, "R" if ordinal % 3 == 2 else "A"))
			if decision.is_empty():
				return
			assert_eq(decision.ordinal, ordinal)
			assert_false(block.has(decision.lane), "Cambio de oleada no reinicia carriles del bloque")
			block.append(decision.lane)
			sequence.append(decision.lane)
			if not _confirm(session, decision, ordinal):
				return
			if block.size() == 5:
				block.sort()
				assert_eq(block, [0, 1, 2, 3, 4])
				block.clear()
		assert_eq(block.size(), 4)
		assert_true(session.choose_lane(_snapshot()).is_empty(), "No completar el último bloque con un enemigo100")
		variants[str(sequence)] = true
	assert_gt(variants.size(), 1, "Semillas diferentes deben permitir más de un reparto")


func test_same_seed_replays_and_global_cosmetic_rng_cannot_change_sequence() -> void:
	var first := _session(173)
	var second := _session(173)
	for ordinal in 20:
		seed(9876 + ordinal)
		for ignored in 7:
			randf()
		var a := _decision(first)
		var b := _decision(second)
		if a.is_empty() or b.is_empty():
			return
		assert_eq(a.lane, b.lane)
		assert_eq(a.context, b.context)
		if not _confirm(first, a, ordinal) or not _confirm(second, b, ordinal):
			return


func test_neutral_memory_is_uniform_even_when_scores_have_no_effective_evidence() -> void:
	var cells: Dictionary = {}
	for lane in 5:
		cells["early/A/%d/empty/zero" % lane] = {"q": 1.0 if lane == 0 else 0.0, "n": 0.0}
	var session := _session(42, _memory(cells))
	if _decision(session).is_empty():
		return
	var probabilities := _probabilities(session)
	assert_eq(probabilities.size(), 5)
	for lane in 5:
		assert_almost_eq(probabilities.get(lane, -1.0), 0.2, 0.000001)


func test_extreme_memory_has_analytic_bounded_probabilities_and_never_suppresses_legal_alternatives() -> void:
	var cells: Dictionary = {}
	for lane in 5:
		cells["early/A/%d/empty/zero" % lane] = {"q": 1.0 if lane == 0 else 0.0, "n": 20.0}
	var session := _session(42, _memory(cells))
	if _decision(session).is_empty():
		return
	var probabilities := _probabilities(session)
	assert_eq(probabilities.size(), 5)
	var total := 0.0
	var minimum := 1.0
	var maximum := 0.0
	for lane in 5:
		var probability := float(probabilities.get(lane, -1.0))
		assert_gt(probability, 0.0)
		assert_almost_eq(probability, 23.0 / 85.0 if lane == 0 else 31.0 / 170.0, 0.000001)
		total += probability
		minimum = minf(minimum, probability)
		maximum = maxf(maximum, probability)
	assert_almost_eq(total, 1.0, 0.000001)
	assert_lte(maximum / minimum, 5.0 / 3.0 + 0.000001)


func test_pending_proposal_is_reused_without_another_rng_draw_or_retroactive_context_change() -> void:
	var session := _session()
	var first := _decision(session)
	if first.is_empty():
		return
	var before := session.get_decision_snapshot().duplicate(true)
	var second := _decision(session, _snapshot(10, "R", "returning", 4))
	if second.is_empty():
		return
	assert_eq(second, first)
	assert_eq(session.get_decision_snapshot(), before)


func test_register_rejects_wrong_and_consumed_tokens_without_advancing_the_block() -> void:
	var session := _session()
	var decision := _decision(session)
	if decision.is_empty():
		return
	var forged := decision.duplicate(true)
	forged.token = -999
	var before := session.get_decision_snapshot().duplicate(true)
	assert_false(session.register_spawn(forged, 1000, 1, 1008.0, 96.0))
	assert_eq(session.get_decision_snapshot(), before)
	if not _confirm(session, decision, 0):
		return
	var after := session.get_decision_snapshot().duplicate(true)
	assert_eq(after.get("wave_index", -1), 1)
	assert_false(session.register_spawn(decision, 1000, 1, 1008.0, 96.0))
	assert_eq(session.get_decision_snapshot(), after)


func test_cancel_restores_rng_and_unconsumed_carril_but_invalidates_the_old_token() -> void:
	var session := _session()
	var before := session.get_decision_snapshot().duplicate(true)
	var first := _decision(session)
	if first.is_empty():
		return
	assert_true(session.cancel_proposal(first.token))
	var restored := session.get_decision_snapshot()
	assert_eq(restored.get("rng_state"), before.get("rng_state"))
	assert_eq(restored.get("wave_index", -1), 0)
	assert_eq(restored.get("pending_lanes", []), [0, 1, 2, 3, 4])
	assert_false(session.cancel_proposal(first.token))
	var again := _decision(session)
	if again.is_empty():
		return
	assert_eq(again.lane, first.lane)
	assert_eq(again.ordinal, first.ordinal)
	assert_eq(again.context, first.context)
	assert_ne(again.token, first.token)
	assert_false(session.register_spawn(first, 1000, 1, 1008.0, 96.0))
	assert_true(session.cancel_proposal(again.token))


func test_forced_fifth_lane_still_consumes_exactly_one_rng_draw() -> void:
	var session := _session(71)
	for ordinal in 4:
		var decision := _decision(session)
		if decision.is_empty() or not _confirm(session, decision, ordinal):
			return
	var pending: Array = session.get_decision_snapshot().get("pending_lanes", [])
	assert_eq(pending.size(), 1)
	if pending.size() != 1:
		return
	var forced := _decision(session)
	if forced.is_empty():
		return
	assert_eq(forced.lane, pending[0])
	assert_almost_eq(_probabilities(session).get(forced.lane, -1.0), 1.0, 0.000001)
	if not _confirm(session, forced, 4):
		return
	var reference := RandomNumberGenerator.new()
	reference.seed = 71
	for draw in 5:
		reference.randf()
	assert_eq(session.get_decision_snapshot().get("rng_state"), reference.state)
	assert_eq(session.get_decision_snapshot().get("pending_lanes", []), [0, 1, 2, 3, 4])


func test_memory_and_diagnostic_are_copied_and_unrelated_input_keys_do_not_reveal_answers() -> void:
	var cells := {"early/A/0/empty/zero": {"q": 1.0, "n": 20.0}}
	var memory := _memory(cells)
	var before := memory.duplicate(true)
	var session := _session(42, memory)
	var control := _session(42, before)
	memory.cells.clear()
	var snapshot := _snapshot()
	snapshot["future_player_commands"] = ["reload_lane_4"]
	snapshot["acceptable_lane"] = 4
	var actual := _decision(session, snapshot)
	var expected := _decision(control)
	if actual.is_empty() or expected.is_empty():
		return
	assert_eq(actual.lane, expected.lane)
	assert_eq(_probabilities(session), _probabilities(control))
	var diagnostic := session.get_decision_snapshot()
	diagnostic.get("pending_lanes", []).clear()
	diagnostic.get("probabilities", {}).clear()
	assert_eq(session.get_decision_snapshot().get("pending_lanes", []), [0, 1, 2, 3, 4])
	assert_eq(_probabilities(session).size(), 5)
	assert_eq(before.cells.size(), 1)


func _candidate(session: CommanderSession, result: int = GameStateManager.GameState.WON) -> Dictionary:
	var candidate := session.finish(result)
	var valid_shape := candidate.has_all(["changed", "memory", "match_id"])
	assert_true(valid_shape, "finish debe devolver explícitamente candidato y changed, incluso sin muestras")
	return candidate if valid_shape else {}


func _spawn_sample(session: CommanderSession, actor_id: int, generation: int = 1,
		spawn_x: float = 1008.0, defended_right: float = 96.0) -> Dictionary:
	var decision := _decision(session)
	if decision.is_empty():
		return {}
	assert_true(session.register_spawn(decision, actor_id, generation, spawn_x, defended_right))
	return decision


func test_death_reward_uses_injected_geometry_and_clamps_progress(params = use_parameters([
	[250.0, 50.0, 300.0, 0.425], [250.0, 50.0, 250.0, 0.425],
	[250.0, 50.0, 150.0, 0.5], [250.0, 50.0, 50.0, 0.575],
	[250.0, 50.0, -20.0, 0.575], [1008.0, 96.0, 552.0, 0.5],
])) -> void:
	var session := _session()
	var decision := _spawn_sample(session, 700, 1, params[0], params[1])
	session.record_defeat(700, 1, params[2])
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	assert_true(candidate.changed)
	assert_eq(candidate.match_id, "selector-test")
	assert_eq(candidate.memory.last_match_id, "selector-test")
	assert_eq(candidate.memory.generation, 0, "Sólo Store incrementa la generación al verificar save")
	assert_eq(candidate.memory.cells.size(), 1)
	var cell: Dictionary = candidate.memory.cells.get(decision.context, {})
	assert_almost_eq(cell.get("q", -1.0), params[3], 0.000001)
	assert_almost_eq(cell.get("n", -1.0), 1.0, 0.000001)


func test_breach_is_one_and_first_valid_closure_wins_over_duplicate_death() -> void:
	var session := _session()
	var decision := _spawn_sample(session, 701)
	session.record_breach(701, 1)
	session.record_breach(701, 1)
	session.record_defeat(701, 1, 1008.0)
	var candidate := _candidate(session, GameStateManager.GameState.LOST)
	if candidate.is_empty():
		return
	var cell: Dictionary = candidate.memory.cells.get(decision.context, {})
	assert_almost_eq(cell.get("q", -1.0), 0.575, 0.000001)
	assert_almost_eq(cell.get("n", -1.0), 1.0, 0.000001)


func test_defeat_first_is_not_replaced_by_later_breach_or_invalid_positions() -> void:
	var session := _session()
	var decision := _spawn_sample(session, 702)
	session.record_defeat(702, 1, NAN)
	session.record_defeat(702, 1, INF)
	session.record_defeat(702, 1, 1008.0)
	session.record_breach(702, 1)
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	assert_almost_eq(candidate.memory.cells.get(decision.context, {}).get("q", -1.0), 0.425, 0.000001)


func test_censored_survivors_and_unregistered_initial_do_not_create_zero_samples() -> void:
	var session := _session()
	var first := _spawn_sample(session, 710)
	for actor_id in range(711, 719):
		_spawn_sample(session, actor_id)
	session.record_breach(710, 1)
	session.record_breach(9999, 1) # INITIAL jamás recibió register_spawn WAVE.
	session.record_defeat(9999, 1, 0.0)
	var candidate := _candidate(session, GameStateManager.GameState.LOST)
	if candidate.is_empty():
		return
	assert_eq(candidate.memory.cells.size(), 1, "OPEN es censura, no recompensa cero")
	assert_almost_eq(candidate.memory.cells.get(first.context, {}).get("q", -1.0), 0.575, 0.000001)


func test_wrong_generation_and_recycled_actor_ids_cannot_close_another_activation() -> void:
	var session := _session()
	var first := _spawn_sample(session, 720, 1)
	session.record_breach(720, 2)
	session.record_defeat(720, 0, 0.0)
	session.record_defeat(720, 1, 1008.0)
	var second := _spawn_sample(session, 720, 2)
	session.record_breach(720, 1)
	session.record_breach(720, 2)
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	assert_eq(candidate.memory.cells.size(), 2)
	assert_almost_eq(candidate.memory.cells.get(first.context, {}).get("q", -1.0), 0.425, 0.000001)
	assert_almost_eq(candidate.memory.cells.get(second.context, {}).get("q", -1.0), 0.575, 0.000001)


func test_each_context_receives_mean_reward_and_one_visit_per_match() -> void:
	var session := _session()
	var decisions: Array[Dictionary] = []
	for ordinal in 10:
		decisions.append(_spawn_sample(session, 800 + ordinal))
	var observed: String = decisions[0].context
	session.record_defeat(800, 1, 1008.0)
	for ordinal in range(5, 10):
		if decisions[ordinal].context == observed:
			session.record_breach(800 + ordinal, 1)
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	assert_eq(candidate.memory.cells.size(), 1)
	assert_almost_eq(candidate.memory.cells.get(observed, {}).get("q", -1.0), 0.5, 0.000001)
	assert_almost_eq(candidate.memory.cells.get(observed, {}).get("n", -1.0), 1.0, 0.000001)


func test_terminal_with_samples_decays_all_cells_and_caps_observed_effective_visits() -> void:
	var cells: Dictionary = {}
	for lane in 5:
		cells["early/A/%d/empty/zero" % lane] = {"q": 0.9, "n": 20.0}
	cells["late/R/4/armed/two_plus"] = {"q": 0.1, "n": 10.0}
	var original := _memory(cells)
	var before := original.duplicate(true)
	var session := _session(42, original)
	var decision := _spawn_sample(session, 900)
	session.record_defeat(900, 1, 1008.0)
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	var observed: Dictionary = candidate.memory.cells.get(decision.context, {})
	assert_almost_eq(observed.get("q", -1.0), 0.7582, 0.000001)
	assert_almost_eq(observed.get("n", -1.0), 20.0, 0.000001)
	var old: Dictionary = candidate.memory.cells.get("late/R/4/armed/two_plus", {})
	assert_almost_eq(old.get("q", -1.0), 0.108, 0.000001)
	assert_almost_eq(old.get("n", -1.0), 9.8, 0.000001)
	assert_eq(original, before, "El candidato nunca publica ni muta la memoria de entrada")


func test_five_contradictory_matches_reverse_extreme_prior_without_growing_visits() -> void:
	var cells: Dictionary = {}
	for lane in 5:
		cells["early/A/%d/empty/zero" % lane] = {"q": 1.0, "n": 20.0}
	var memory := _memory(cells)
	var expected_q := 1.0
	for match_index in 5:
		var session := SessionScript.new()
		session.begin_match("reverse-%d" % match_index, 42, _config(), memory)
		for ordinal in 5:
			_spawn_sample(session, 1000 + ordinal)
			session.record_defeat(1000 + ordinal, 1, 1008.0)
		var candidate := _candidate(session)
		if candidate.is_empty():
			return
		memory = candidate.memory
		expected_q = (0.5 + 0.98 * (expected_q - 0.5)) * 0.85
		for cell: Dictionary in memory.cells.values():
			assert_almost_eq(cell.q, expected_q, 0.000001)
			assert_almost_eq(cell.n, 20.0, 0.000001)
	assert_lt(expected_q, 0.5, "Experiencia contraria debe superar una preferencia extrema antigua")


func test_effective_confidence_interpolates_before_three_visits() -> void:
	var cells: Dictionary = {}
	for lane in 5:
		cells["early/A/%d/empty/zero" % lane] = {"q": 1.0, "n": 1.5} if lane == 0 else {"q": 0.5, "n": 0.0}
	var session := _session(42, _memory(cells))
	_decision(session)
	var probabilities := _probabilities(session)
	assert_almost_eq(probabilities.get(0, -1.0), 0.05 + 0.75 * 1.125 / 5.125, 0.000001)
	assert_almost_eq(probabilities.get(1, -1.0), 0.05 + 0.75 / 5.125, 0.000001)


func test_recorded_results_do_not_change_selection_until_the_next_match() -> void:
	var session := _session(23)
	var control := _session(23)
	for ordinal in 5:
		var decision := _spawn_sample(session, 1100 + ordinal)
		var reference := _spawn_sample(control, 1100 + ordinal)
		assert_eq(decision.lane, reference.lane)
		session.record_breach(1100 + ordinal, 1)
	var next := _decision(session)
	var reference_next := _decision(control)
	assert_eq(next.lane, reference_next.lane)
	assert_eq(_probabilities(session), _probabilities(control))
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	assert_true(session.choose_lane(_snapshot()).is_empty(), "FINALIZED cancela cualquier propuesta pendiente")
	var next_match := _session(23, candidate.memory)
	_decision(next_match)
	assert_eq(candidate.memory.cells.size(), 5)
	for cell: Dictionary in candidate.memory.cells.values():
		assert_almost_eq(cell.q, 0.575, 0.000001)


func test_nonterminal_results_do_not_close_session_and_terminal_only_commits_once() -> void:
	var session := _session()
	_spawn_sample(session, 1200)
	session.record_breach(1200, 1)
	for result in [GameStateManager.GameState.PLAYING, GameStateManager.GameState.PAUSED, GameStateManager.GameState.MENU]:
		var rejected := session.finish(result)
		assert_false(rejected.get("changed", false))
		assert_eq(session.get_decision_snapshot().get("state"), "ACTIVE")
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	assert_true(candidate.changed)
	assert_eq(session.get_decision_snapshot().get("state"), "FINALIZED")
	assert_false(session.finish(GameStateManager.GameState.LOST).get("changed", false))
	session.abandon()
	assert_eq(session.get_decision_snapshot().get("state"), "FINALIZED")


func test_zero_closed_samples_preserve_memory_exactly_without_decay(params = use_parameters([
	GameStateManager.GameState.WON, GameStateManager.GameState.LOST,
])) -> void:
	var memory := _memory({"late/R/4/armed/one": {"q": 0.8, "n": 17.0}})
	memory.generation = 9
	memory.last_match_id = "previous"
	var session := _session(42, memory)
	_spawn_sample(session, 1300)
	session.record_breach(9999, 1) # INITIAL u otra identidad no registrada.
	var candidate := _candidate(session, params)
	if candidate.is_empty():
		return
	assert_false(candidate.changed)
	assert_eq(candidate.memory, memory)
	assert_eq(session.get_decision_snapshot().get("state"), "FINALIZED")


func test_abandon_discards_closed_samples_idempotently_and_disables_selection() -> void:
	var session := _session()
	_spawn_sample(session, 1400)
	session.record_breach(1400, 1)
	session.abandon()
	session.abandon()
	assert_eq(session.get_decision_snapshot().get("state"), "ABANDONED")
	assert_true(session.choose_lane(_snapshot()).is_empty())
	assert_false(session.finish(GameStateManager.GameState.WON).get("changed", false))


func test_valid_config_parameters_drive_learning_and_retention_instead_of_literal_defaults() -> void:
	var config := _config()
	config.learning_rate = 0.1
	config.retention_per_match = 0.9
	var cells: Dictionary = {}
	for lane in 5:
		cells["early/A/%d/empty/zero" % lane] = {"q": 0.8, "n": 3.0}
	var session := _session(42, _memory(cells), config)
	var decision := _spawn_sample(session, 1500)
	session.record_breach(1500, 1)
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	var cell: Dictionary = candidate.memory.cells.get(decision.context, {})
	assert_almost_eq(cell.get("q", -1.0), 0.793, 0.000001)
	assert_almost_eq(cell.get("n", -1.0), 3.7, 0.000001)


func test_one_learned_experience_changes_next_match_preference_with_confidence_and_alternatives() -> void:
	var session := _session()
	var decision := _spawn_sample(session, 1600)
	session.record_breach(1600, 1)
	var candidate := _candidate(session)
	if candidate.is_empty():
		return
	var following := _session(42, candidate.memory)
	_decision(following)
	var probabilities := _probabilities(following)
	assert_gt(probabilities.get(decision.lane, -1.0), 0.2)
	assert_almost_eq(probabilities.get(decision.lane, -1.0), 0.05 + 0.75 * 1.0125 / 5.0125, 0.000001)
	for lane in 5:
		assert_gt(probabilities.get(lane, -1.0), 0.0)
