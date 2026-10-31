## Selector local de carriles; no instancia actores ni gobierna sus tiempos.
class_name CommanderSession
extends RefCounted

const _LANES: Array[int] = [0, 1, 2, 3, 4]
const _PHASES: Array[String] = ["early", "middle", "late"]
const _MAX_WAVE_SPAWNS: int = 99

var _config: CommanderConfig
var _memory: Dictionary = {}
var _match_id: String = ""
var _state: String = "INACTIVE"
var _rng := RandomNumberGenerator.new()
var _pending_lanes: Array[int] = []
var _wave_index: int = 0
var _next_token: int = 1
var _proposal: Dictionary = {}
var _probabilities: Dictionary = {}
var _rng_before_proposal: int = 0
var _records: Dictionary = {}


func begin_match(match_id: String, seed_value: int, config: CommanderConfig,
		memory: Dictionary) -> void:
	_state = "INACTIVE"
	_proposal.clear()
	_probabilities.clear()
	_records.clear()
	_wave_index = 0
	_pending_lanes.assign(_LANES)
	_match_id = match_id
	_memory = memory.duplicate(true)
	_config = null
	if match_id.is_empty() or match_id.length() > 64 or not _valid_config(config):
		return
	_config = config.duplicate(true) as CommanderConfig
	_rng.seed = seed_value
	_state = "ACTIVE"


func choose_lane(snapshot: Dictionary) -> Dictionary:
	if _state != "ACTIVE" or _wave_index >= _MAX_WAVE_SPAWNS:
		return {}
	if not _proposal.is_empty():
		return _proposal.duplicate(true)
	var contexts := _contexts(snapshot)
	if contexts.is_empty():
		return {}
	var weights: Dictionary = {}
	var total_weight: float = 0.0
	for lane: int in _pending_lanes:
		var cell := _cell(contexts[lane])
		var confidence := minf(float(cell.n) / _config.confidence_visits, 1.0)
		var score := _config.prior_score + (float(cell.q) - _config.prior_score) * confidence
		var weight := 1.0 + _config.weight_gain * (2.0 * score - 1.0)
		weights[lane] = weight
		total_weight += weight
	_probabilities.clear()
	for lane: int in _pending_lanes:
		_probabilities[lane] = _config.exploration_share / _pending_lanes.size() \
				+ (1.0 - _config.exploration_share) * float(weights[lane]) / total_weight
	_rng_before_proposal = _rng.state
	var draw := _rng.randf()
	var cumulative: float = 0.0
	var selected_lane: int = _pending_lanes[-1]
	for lane: int in _pending_lanes:
		cumulative += float(_probabilities[lane])
		if draw < cumulative:
			selected_lane = lane
			break
	_proposal = {
		"ordinal": _wave_index, "lane": selected_lane,
		"context": contexts[selected_lane],
		"token": "%d:%d" % [get_instance_id(), _next_token],
	}
	_next_token += 1
	return _proposal.duplicate(true)


func register_spawn(decision: Dictionary, actor_id: int, generation: int,
		spawn_x: float, defended_right: float) -> bool:
	if _state != "ACTIVE" or _proposal.is_empty() or decision != _proposal:
		return false
	if actor_id <= 0 or generation < 0 or not is_finite(spawn_x) \
			or not is_finite(defended_right) or spawn_x <= defended_right:
		return false
	var actor_key := "%d:%d" % [actor_id, generation]
	if _records.has(actor_key):
		return false
	_records[actor_key] = {
		"actor_id": actor_id, "generation": generation,
		"ordinal": _wave_index, "lane": _proposal.lane,
		"context": _proposal.context, "spawn_x": spawn_x,
		"defended_right": defended_right, "status": "OPEN",
	}
	_pending_lanes.erase(int(_proposal.lane))
	_wave_index += 1
	if _pending_lanes.is_empty():
		_pending_lanes.assign(_LANES)
	_proposal.clear()
	_probabilities.clear()
	return true


func cancel_proposal(token: Variant) -> bool:
	if _state != "ACTIVE" or _proposal.is_empty() or token != _proposal.token:
		return false
	_rng.state = _rng_before_proposal
	_proposal.clear()
	_probabilities.clear()
	return true


func record_defeat(actor_id: int, generation: int, death_x: float) -> void:
	if not is_finite(death_x):
		return
	var key := "%d:%d" % [actor_id, generation]
	if _state != "ACTIVE" or not _records.has(key) or _records[key].status != "OPEN":
		return
	var record: Dictionary = _records[key]
	record.reward = clampf((record.spawn_x - death_x) / (record.spawn_x - record.defended_right), 0.0, 1.0)
	record.status = "DEFEATED"


func record_breach(actor_id: int, generation: int) -> void:
	var key := "%d:%d" % [actor_id, generation]
	if _state != "ACTIVE" or not _records.has(key) or _records[key].status != "OPEN":
		return
	_records[key].reward = 1.0
	_records[key].status = "BREACHED"


func finish(result: Variant) -> Dictionary:
	var unchanged := {"changed": false, "memory": _memory.duplicate(true), "match_id": _match_id}
	if _state != "ACTIVE" or not result is int \
			or result not in [GameStateManager.GameState.WON, GameStateManager.GameState.LOST]:
		return unchanged
	# Cerrar antes de procesar cualquier resultado: los callbacks tardíos no consolidan dos veces.
	_state = "FINALIZED"
	_proposal.clear()
	_probabilities.clear()
	var totals: Dictionary = {}
	for record: Dictionary in _records.values():
		if record.status == "OPEN":
			record.status = "CENSORED"
			continue
		if record.status not in ["DEFEATED", "BREACHED"]:
			continue
		var context: String = record.context
		if not totals.has(context):
			totals[context] = {"sum": 0.0, "count": 0}
		totals[context].sum += record.reward
		totals[context].count += 1
	if totals.is_empty():
		return unchanged
	var candidate := _memory.duplicate(true)
	var cells: Dictionary = candidate.get("cells", {})
	for cell: Dictionary in cells.values():
		cell.q = _config.prior_score + _config.retention_per_match * (float(cell.q) - _config.prior_score)
		cell.n = _config.retention_per_match * float(cell.n)
	for context: String in totals:
		var cell: Dictionary = cells.get(context, {"q": _config.prior_score, "n": 0.0})
		var mean_reward: float = float(totals[context].sum) / int(totals[context].count)
		cell.q = float(cell.q) + _config.learning_rate * (mean_reward - float(cell.q))
		cell.n = minf(_config.max_effective_visits, float(cell.n) + 1.0)
		cells[context] = cell
	candidate.cells = cells
	candidate.last_match_id = _match_id
	return {"changed": true, "memory": candidate, "match_id": _match_id}


func abandon() -> void:
	if _state != "ACTIVE":
		return
	_state = "ABANDONED"
	_records.clear()
	_proposal.clear()
	_probabilities.clear()


func get_decision_snapshot() -> Dictionary:
	return {
		"pending_lanes": _pending_lanes.duplicate(), "wave_index": _wave_index,
		"proposal": _proposal.duplicate(true), "state": _state,
		"rng_state": _rng.state, "probabilities": _probabilities.duplicate(true),
	}


func _valid_config(config: CommanderConfig) -> bool:
	if config == null or config.schema_version != 1 or config.policy_version != 1:
		return false
	if config.phase_end_waves.size() != 3 or config.phase_end_waves[0] <= 0 \
			or config.phase_end_waves[0] >= config.phase_end_waves[1] \
			or config.phase_end_waves[1] >= config.phase_end_waves[2] \
			or config.phase_end_waves[2] != 10:
		return false
	var values: Array[float] = [config.prior_score, config.learning_rate,
		config.retention_per_match, config.confidence_visits,
		config.max_effective_visits, config.exploration_share, config.weight_gain]
	for value: float in values:
		if not is_finite(value):
			return false
	return config.prior_score == 0.5 \
		and config.learning_rate > 0.0 and config.learning_rate <= 0.15 \
		and config.retention_per_match >= 0.0 and config.retention_per_match < 1.0 \
		and config.confidence_visits > 0.0 \
		and config.max_effective_visits >= config.confidence_visits \
		and config.max_effective_visits <= 20.0 \
		and config.exploration_share >= 0.25 and config.exploration_share < 1.0 \
		and config.weight_gain > 0.0 and config.weight_gain <= 0.25


func _contexts(snapshot: Dictionary) -> Dictionary:
	var wave: Variant = snapshot.get("wave_number")
	var role: Variant = snapshot.get("role")
	var defenders: Variant = snapshot.get("defenders")
	var loads: Variant = snapshot.get("lane_loads")
	if not wave is int or wave < 1 or wave > _config.phase_end_waves[-1] \
			or not role is String or role not in ["A", "R"] \
			or not defenders is Array or defenders.size() != 5 \
			or not loads is Array or loads.size() != 5:
		return {}
	var phase: String = _PHASES[0]
	for phase_index: int in 3:
		if wave <= _config.phase_end_waves[phase_index]:
			phase = _PHASES[phase_index]
			break
	var result: Dictionary = {}
	for lane: int in _LANES:
		var defender: Variant = defenders[lane]
		var load_value: Variant = loads[lane]
		if not defender is Dictionary or not load_value is int or load_value < 0:
			return {}
		if defender.get("lane_id") != lane or not defender.get("alive") is bool:
			return {}
		var defense: String = "empty"
		if defender.alive:
			if defender.get("movement_state") == Soldado.MovementState.RETURNING:
				defense = "returning"
			elif defender.get("ammo", 0) > 0 and defender.get("mode") == Soldado.SoldierMode.RIFLE:
				defense = "armed"
			else:
				defense = "unarmed"
		var load_category: String = "zero" if load_value == 0 else ("one" if load_value == 1 else "two_plus")
		result[lane] = "%s/%s/%d/%s/%s" % [phase, role, lane, defense, load_category]
	return result


func _cell(context: String) -> Dictionary:
	var cells: Variant = _memory.get("cells", {})
	if cells is Dictionary:
		var cell: Variant = cells.get(context)
		if cell is Dictionary:
			var q: Variant = cell.get("q")
			var n: Variant = cell.get("n")
			if (q is float or q is int) and (n is float or n is int) \
					and is_finite(float(q)) and is_finite(float(n)) \
					and q >= 0.0 and q <= 1.0 and n >= 0.0 and n <= _config.max_effective_visits:
				return {"q": float(q), "n": float(n)}
	return {"q": _config.prior_score, "n": 0.0}
