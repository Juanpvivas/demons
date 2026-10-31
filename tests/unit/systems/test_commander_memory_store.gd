extends GutTest

const StoreScript = preload("res://core/commander_memory_store.gd")
const ConfigScript = preload("res://resources/schemas/commander_config.gd")
const LIMIT_BYTES: int = 128 * 1024
const MAX_GENERATION: int = 9007199254740991
const CELL: String = "early/A/0/empty/zero"
var _directory: String


# Doble del puerto público. Un write sólo devuelve OK si terminó open/write/flush/close.
# La relectura posterior sigue siendo responsabilidad del Store, no de este doble.
class FakeIO extends RefCounted:
	var files: Dictionary = {}
	var calls: Array[String] = []
	var fail_stage: String = ""
	var last_written: String = ""
	var tamper_after_write: bool = false
	var readback_armed: bool = false
	var fail_remove_path: String = ""
	var lie_remove_path: String = ""
	var fail_verify_path: String = ""
	var removal_attempts: Array[String] = []

	func exists(path: String) -> Dictionary:
		calls.append("exists:" + path)
		var failed := fail_stage == "exists" or (path == fail_verify_path and removal_attempts.has(path))
		return {"error": ERR_FILE_CANT_READ if failed else OK, "value": files.has(path)}

	func size(path: String) -> Dictionary:
		calls.append("size:" + path)
		return {"error": ERR_FILE_CANT_READ if fail_stage == "size" else OK,
			"value": str(files.get(path, "")).to_utf8_buffer().size()}

	func read(path: String, max_bytes: int) -> Dictionary:
		calls.append("read:" + path)
		if fail_stage == "read" or (fail_stage == "readback" and readback_armed and path == last_written):
			return {"error": ERR_FILE_CANT_READ, "text": ""}
		var text: String = files.get(path, "")
		if text.to_utf8_buffer().size() > max_bytes:
			return {"error": ERR_FILE_CANT_READ, "text": ""}
		return {"error": OK, "text": text}

	func write(path: String, text: String) -> Dictionary:
		last_written = path
		for stage in ["open", "write", "flush", "close"]:
			calls.append(stage + ":" + path)
			if fail_stage == stage:
				return {"error": ERR_FILE_CANT_WRITE, "stage": stage}
		files[path] = "truncated" if tamper_after_write else text
		readback_armed = fail_stage == "readback"
		return {"error": OK}

	func remove(path: String) -> Dictionary:
		calls.append("remove:" + path)
		removal_attempts.append(path)
		if path == fail_remove_path:
			return {"error": ERR_FILE_CANT_WRITE}
		if path != lie_remove_path:
			files.erase(path)
		return {"error": OK}


func before_each() -> void:
	_directory = "/tmp/commander-017-%d-%d" % [get_instance_id(), Time.get_ticks_usec()]
	assert_eq(DirAccess.make_dir_recursive_absolute(_directory), OK)


func after_each() -> void:
	# Sólo archivos creados por este caso, en una carpeta temporal exclusiva.
	for name in DirAccess.get_files_at(_directory):
		DirAccess.remove_absolute(_directory.path_join(name))
	DirAccess.remove_absolute(_directory)


func _config() -> CommanderConfig:
	return load("res://resources/director/monte_calvo_commander.tres").duplicate(true) as CommanderConfig


func _sources() -> Dictionary:
	# duplicate(true) de WaveData conserva Resources externos anidados en entradas.
	# Cada capa mutable tiene dueño propio, sin restaurar la caché global después.
	var waves: Array[WaveData] = []
	for number in range(1, 11):
		var authored: WaveData = load("res://resources/waves/nivel_montecalvo_oleada_%02d.tres" % number)
		var wave := WaveData.new()
		wave.wave_number = authored.wave_number
		for original: WaveSpawnEntry in authored.spawn_entries:
			var entry := WaveSpawnEntry.new()
			entry.count = original.count
			entry.spawn_interval = original.spawn_interval
			entry.enemy_stats = original.enemy_stats.duplicate(true) as EnemyStats
			wave.spawn_entries.append(entry)
		waves.append(wave)
	var authored_board: LaneBoardConfig = load("res://resources/levels/monte_calvo_board.tres")
	var board := LaneBoardConfig.new()
	board.design_rect = authored_board.design_rect
	board.cell_size = authored_board.cell_size
	board.defended_rect = authored_board.defended_rect
	board.home_cells.assign(authored_board.home_cells)
	board.spawn_positions.assign(authored_board.spawn_positions)
	return {"waves": waves,
		"soldier_stats": load("res://resources/units/soldado_base_stats.tres").duplicate(true),
		"board": board}


func _store(backend: Object = null, sources: Dictionary = {}) -> CommanderMemoryStore:
	var store := StoreScript.new()
	store.storage_base_path = _directory
	store.io_backend = backend
	store.compatibility_sources = sources
	return store


func _path(slot: String) -> String:
	return _directory.path_join("commander_memory_%s.json" % slot)


func _result_shape(result: Dictionary) -> bool:
	var valid := result.has_all(["status", "memory"])
	assert_true(valid, "Store debe comunicar estado explícito y memoria, no un retorno neutral de setup")
	return valid


func _save(store: CommanderMemoryStore, candidate: Dictionary, expected_generation: int) -> Dictionary:
	var result := store.save(candidate, expected_generation)
	assert_true(result.has_all(["applied", "saved"]), "Save siempre separa applied de saved")
	return result


func _neutral(store: CommanderMemoryStore, config: CommanderConfig = null) -> Dictionary:
	var result := store.load_compatible(_config() if config == null else config)
	if not _result_shape(result):
		return {}
	assert_eq(result.status, "TRANSIENT" if store.transient else "MISSING")
	var memory: Dictionary = result.memory
	assert_true(memory.has_all(["schema_version", "policy_version", "compatibility_id", "generation", "last_match_id", "cells"]))
	if not memory.has_all(["compatibility_id", "cells"]):
		return {}
	assert_eq(memory.cells, {})
	assert_eq(str(memory.compatibility_id).hex_decode().size(), 32, "Compatibilidad usa SHA256 de contenido")
	return memory


func _payload(neutral: Dictionary, generation: int = 1, match_id: String = "match-1") -> Dictionary:
	var memory := neutral.duplicate(true)
	memory.generation = generation
	memory.last_match_id = match_id
	memory.cells = {CELL: {"q": 0.575, "n": 1.0}}
	return memory


func _candidate(memory: Dictionary, match_id: String = "match-1") -> Dictionary:
	var candidate_memory := memory.duplicate(true)
	candidate_memory.last_match_id = match_id
	candidate_memory.cells = {CELL: {"q": 0.575, "n": 1.0}}
	return {"changed": true, "memory": candidate_memory, "match_id": match_id}


func _envelope(payload: Variant, pretty: bool = false) -> String:
	# El hash cubre el UTF-8 exacto del string payload, incluido whitespace/Unicode.
	# No depende de rutas, IDs Resource, UID, metadata ni orden de inserción Dictionary.
	var text := JSON.stringify(payload, "\t" if pretty else "", true, true)
	return JSON.stringify({"payload": text, "sha256": text.sha256_text()})


func _put(backend: FakeIO, slot: String, payload: Variant) -> void:
	backend.files[_path(slot)] = _envelope(payload)


func test_missing_store_returns_explicit_neutral_memory_without_creating_files() -> void:
	var store := _store()
	var memory := _neutral(store)
	if memory.is_empty():
		return
	assert_eq(memory.generation, 0)
	assert_eq(memory.last_match_id, "")
	assert_eq(DirAccess.get_files_at(_directory).size(), 0)


func test_real_temporary_files_persist_verified_envelope_and_reopen_without_user_data() -> void:
	var store := _store()
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var saved := _save(store, _candidate(neutral, "partida-á"), 0)
	if not _result_shape(saved):
		return
	assert_eq(saved.status, "OK")
	assert_true(saved.get("applied", false))
	assert_true(saved.get("saved", false))
	assert_eq(saved.memory.generation, 1)
	var files := DirAccess.get_files_at(_directory)
	assert_eq(files.size(), 1)
	if files.size() != 1:
		return
	var text := FileAccess.get_file_as_string(_directory.path_join(files[0]))
	var envelope: Dictionary = JSON.parse_string(text)
	assert_eq(envelope.sha256, str(envelope.payload).sha256_text())
	var reopened := _store().load_compatible(_config())
	if not _result_shape(reopened):
		return
	assert_eq(reopened.status, "OK")
	assert_eq(reopened.memory, saved.memory)


func test_older_valid_slot_recovers_after_newer_file_is_corrupt() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var valid := _payload(neutral, 4)
	_put(io, "a", valid)
	io.files[_path("b")] = "{broken"
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_eq(result.status, "OK")
	assert_eq(result.memory, valid)


func test_latest_generation_is_selected_even_when_its_content_is_incompatible() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	_put(io, "a", _payload(neutral, 4, "compatible-old"))
	var latest := _payload(neutral, 5, "incompatible-new")
	latest.compatibility_id = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	_put(io, "b", latest)
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_eq(result.status, "INCOMPATIBLE")
	assert_eq(result.memory.get("cells", {"wrong": true}), {}, "No resucitar el slot viejo compatible")


func test_highest_valid_generation_wins_independent_of_slot_name() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var newer := _payload(neutral, 8, "newer")
	_put(io, "a", newer)
	_put(io, "b", _payload(neutral, 7, "older"))
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_eq(result.memory, newer)


func test_equal_generation_different_payload_is_conflict_but_identical_payload_is_valid() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var memory := _payload(neutral, 8)
	_put(io, "a", memory)
	_put(io, "b", memory)
	var same := store.load_compatible(_config())
	if not _result_shape(same):
		return
	assert_eq(same.status, "OK")
	memory.cells[CELL].q = 0.6
	_put(io, "b", memory)
	var different := store.load_compatible(_config())
	if not _result_shape(different):
		return
	assert_eq(different.status, "CONFLICT")
	assert_eq(different.memory.get("cells", {"wrong": true}), {})


func test_payload_hash_covers_exact_utf8_instead_of_reserializing_parsed_json() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var memory := _payload(neutral, 1, "partida-á")
	io.files[_path("a")] = _envelope(memory, true)
	var valid := store.load_compatible(_config())
	if not _result_shape(valid):
		return
	assert_eq(valid.status, "OK")
	var envelope: Dictionary = JSON.parse_string(io.files[_path("a")])
	envelope.payload += " " # JSON semánticamente idéntico; hash exacto ya no coincide.
	io.files[_path("a")] = JSON.stringify(envelope)
	var tampered := store.load_compatible(_config())
	if not _result_shape(tampered):
		return
	assert_eq(tampered.status, "INVALID")
	assert_eq(tampered.memory.cells, {})


func test_envelope_rejects_wrong_structure_extra_fields_and_bad_hash(params = use_parameters([
	"not_json", "array", "payload_object", "hash_missing", "hash_bad", "extra",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var envelope: Dictionary = JSON.parse_string(_envelope(_payload(neutral)))
	match params:
		"not_json": io.files[_path("a")] = "{"
		"array": io.files[_path("a")] = "[]"
		"payload_object":
			envelope.payload = _payload(neutral)
			io.files[_path("a")] = JSON.stringify(envelope)
		"hash_missing":
			envelope.erase("sha256")
			io.files[_path("a")] = JSON.stringify(envelope)
		"hash_bad":
			envelope.sha256 = "0".repeat(64)
			io.files[_path("a")] = JSON.stringify(envelope)
		"extra":
			envelope.extra = 1
			io.files[_path("a")] = JSON.stringify(envelope)
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_eq(result.status, "INVALID")
	assert_eq(result.memory.cells, {})


func test_payload_rejects_extra_missing_wrong_types_and_out_of_range_numbers(params = use_parameters([
	"extra", "missing", "cells_array", "key_invalid", "cell_extra", "cell_array", "q_negative", "q_large",
	"q_bool", "q_null", "n_negative", "n_large", "n_bool", "gen_bool", "gen_fractional",
	"gen_negative", "gen_overflow", "match_too_long", "match_number", "compat_bad", "schema_bool",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var memory := _payload(neutral)
	match params:
		"extra": memory.extra = 1
		"missing": memory.erase("last_match_id")
		"cells_array": memory.cells = []
		"key_invalid": memory.cells = {"early/A/5/empty/zero": {"q": 0.5, "n": 0}}
		"cell_extra": memory.cells[CELL].other = 1
		"cell_array": memory.cells[CELL] = [0.5, 1.0]
		"q_negative": memory.cells[CELL].q = -0.1
		"q_large": memory.cells[CELL].q = 1.1
		"q_bool": memory.cells[CELL].q = true
		"q_null": memory.cells[CELL].q = null
		"n_negative": memory.cells[CELL].n = -0.1
		"n_large": memory.cells[CELL].n = 20.1
		"n_bool": memory.cells[CELL].n = false
		"gen_bool": memory.generation = true
		"gen_fractional": memory.generation = 1.5
		"gen_negative": memory.generation = -1
		"gen_overflow": memory.generation = MAX_GENERATION + 1
		"match_too_long": memory.last_match_id = "m".repeat(65)
		"match_number": memory.last_match_id = 12
		"compat_bad": memory.compatibility_id = "not-a-content-hash"
		"schema_bool": memory.schema_version = true
	_put(io, "a", memory)
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_eq(result.status, "INVALID")
	assert_eq(result.memory.cells, {})


func test_unknown_schema_or_policy_neutralizes_without_automatic_migration(params = use_parameters([
	"schema_version", "policy_version",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var memory := _payload(neutral)
	memory[params] = 2
	_put(io, "a", memory)
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_true(result.status in ["INVALID", "INCOMPATIBLE"], "Versión desconocida requiere motivo explícito, nunca OK")
	assert_eq(result.memory.cells, {})


func test_full_360_cell_vocabulary_is_valid_and_a_361st_key_is_rejected() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var memory := _payload(neutral)
	memory.cells = {}
	for phase in ["early", "middle", "late"]:
		for role in ["A", "R"]:
			for lane in 5:
				for defense in ["empty", "armed", "unarmed", "returning"]:
					for lane_load in ["zero", "one", "two_plus"]:
						memory.cells["%s/%s/%d/%s/%s" % [phase, role, lane, defense, lane_load]] = {"q": 0.5, "n": 0.0}
	_put(io, "a", memory)
	var full := store.load_compatible(_config())
	if not _result_shape(full):
		return
	assert_eq(full.status, "OK")
	assert_eq(full.memory.cells.size(), 360)
	memory.cells["early/A/0/empty/three_plus"] = {"q": 0.5, "n": 0}
	_put(io, "a", memory)
	assert_eq(store.load_compatible(_config()).get("status"), "INVALID")


func test_size_limit_accepts_128kib_and_rejects_larger_before_reading_the_whole_file() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var encoded := _envelope(_payload(neutral))
	io.files[_path("a")] = encoded + " ".repeat(LIMIT_BYTES - encoded.to_utf8_buffer().size())
	assert_eq(store.load_compatible(_config()).get("status"), "OK")
	io.files[_path("a")] += " "
	io.calls.clear()
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_eq(result.status, "INVALID")
	assert_false(io.calls.has("read:" + _path("a")), "Comprobar size antes de leer todo el slot sobredimensionado")


func test_default_and_equivalent_duplicated_sources_produce_same_content_fingerprint() -> void:
	var default_memory := _neutral(_store())
	var sources := _sources()
	var injected_memory := _neutral(_store(null, sources))
	if default_memory.is_empty() or injected_memory.is_empty():
		return
	assert_eq(default_memory.compatibility_id, injected_memory.compatibility_id)
	sources.board.resource_name = "Other editor label"
	sources.soldier_stats.set_meta("editor_note", "not combat")
	for wave: WaveData in sources.waves:
		wave.resource_name = "Editor label"
		for entry: WaveSpawnEntry in wave.spawn_entries:
			entry.enemy_stats.set_meta("art_preview", "texture.png")
	var metadata_memory := _neutral(_store(null, sources))
	if metadata_memory.is_empty():
		return
	assert_eq(metadata_memory.compatibility_id, default_memory.compatibility_id)


func test_every_variable_commander_config_field_changes_content_fingerprint(params = use_parameters([
	["phase_end_waves", [2, 8, 10]], ["learning_rate", 0.1], ["retention_per_match", 0.9],
	["confidence_visits", 2.0], ["max_effective_visits", 10.0], ["exploration_share", 0.5], ["weight_gain", 0.1],
])) -> void:
	var baseline := _neutral(_store())
	var config := _config()
	if params[0] == "phase_end_waves":
		config.phase_end_waves.assign(params[1])
	else:
		config.set(params[0], params[1])
	var changed := _neutral(_store(), config)
	if baseline.is_empty() or changed.is_empty():
		return
	assert_ne(changed.compatibility_id, baseline.compatibility_id, params[0])


func test_enemy_combat_fields_change_content_fingerprint(params = use_parameters([
	"max_health", "move_speed", "melee_damage", "rifle_range", "rifle_damage", "rifle_interval", "ammo_drop",
])) -> void:
	var baseline := _neutral(_store())
	for entry_index in [0, 1]: # A y R deben participar, no sólo un arquetipo.
		var sources := _sources()
		var stats: EnemyStats = sources.waves[0].spawn_entries[entry_index].enemy_stats
		stats.set(params, stats.get(params) + 1)
		var changed := _neutral(_store(null, sources))
		if baseline.is_empty() or changed.is_empty():
			return
		assert_ne(changed.compatibility_id, baseline.compatibility_id, "%s entry%d" % [params, entry_index])


func test_soldier_combat_fields_change_content_fingerprint(params = use_parameters([
	"max_health", "max_ammo", "damage_per_shot", "fire_rate", "rifle_range", "machete_base_damage",
	"machete_moral_multiplier", "machete_moral_per_kill", "machete_heal_per_kill", "moral_per_kill",
	"advance_speed", "return_speed", "deploy_ammo_cost",
])) -> void:
	var baseline := _neutral(_store())
	var sources := _sources()
	var stats: UnitStats = sources.soldier_stats
	stats.set(params, stats.get(params) + 1)
	var changed := _neutral(_store(null, sources))
	if baseline.is_empty() or changed.is_empty():
		return
	assert_ne(changed.compatibility_id, baseline.compatibility_id, params)


func test_board_geometry_and_flattened_order_count_intervals_change_fingerprint(params = use_parameters([
	"design_rect", "cell_size", "defended_rect", "home_cells", "spawn_positions", "order", "count", "interval",
])) -> void:
	var baseline := _neutral(_store())
	var sources := _sources()
	var board: LaneBoardConfig = sources.board
	match params:
		"design_rect": board.design_rect.size.x += 1.0
		"cell_size": board.cell_size.x += 1
		"defended_rect": board.defended_rect.size.x += 1.0
		"home_cells": board.home_cells[0].x += 1
		"spawn_positions": board.spawn_positions[0].x += 1.0
		"order": sources.waves[0].spawn_entries.reverse()
		"count": sources.waves[0].spawn_entries[0].count += 1
		"interval": sources.waves[0].spawn_entries[0].spawn_interval += 0.1
	var changed := _neutral(_store(null, sources))
	if baseline.is_empty() or changed.is_empty():
		return
	assert_ne(changed.compatibility_id, baseline.compatibility_id, params)


func test_equivalent_flattened_schedule_ignores_resource_grouping_and_editor_identity() -> void:
	var baseline := _neutral(_store())
	var sources := _sources()
	var wave: WaveData = sources.waves[0]
	var original: WaveSpawnEntry = wave.spawn_entries[0]
	var first := original.duplicate(true) as WaveSpawnEntry
	var second := original.duplicate(true) as WaveSpawnEntry
	first.count = 1
	second.count = original.count - 1
	wave.spawn_entries.remove_at(0)
	wave.spawn_entries.push_front(second)
	wave.spawn_entries.push_front(first)
	var changed := _neutral(_store(null, sources))
	if baseline.is_empty() or changed.is_empty():
		return
	assert_eq(changed.compatibility_id, baseline.compatibility_id, "Se hashea calendario aplanado, no agrupación de Resources")


func test_incompatible_balance_is_neutral_after_restart() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	_put(io, "a", _payload(neutral, 1))
	var changed_config := _config()
	changed_config.learning_rate = 0.1
	var result := _store(io).load_compatible(changed_config)
	if not _result_shape(result):
		return
	assert_eq(result.status, "INCOMPATIBLE")
	assert_eq(result.memory.cells, {})


func test_two_saves_alternate_slots_increment_generation_and_preserve_previous_copy() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var first := _save(store, _candidate(neutral, "one"), 0)
	if not _result_shape(first):
		return
	assert_eq(first.status, "OK")
	assert_eq(first.memory.generation, 1)
	assert_true(first.get("saved", false))
	var active: String = io.last_written
	var active_bytes: String = io.files.get(active, "")
	var second := _save(store, _candidate(first.memory, "two"), 1)
	if not _result_shape(second):
		return
	assert_eq(second.status, "OK")
	assert_eq(second.memory.generation, 2)
	assert_ne(io.last_written, active)
	assert_eq(io.files.get(active), active_bytes)
	assert_eq(io.files.size(), 2)
	assert_true(io.calls.has("read:" + io.last_written), "Publicar sólo después de relectura verificable")
	assert_eq(_store(io).load_compatible(_config()).get("memory"), second.memory)


func test_stale_expected_generation_or_already_committed_match_is_conflict() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var saved := _save(store, _candidate(neutral), 0)
	if not _result_shape(saved):
		return
	var files_before := io.files.duplicate(true)
	var duplicate := _save(store, _candidate(saved.memory, "match-1"), 1)
	assert_eq(duplicate.get("status"), "CONFLICT")
	assert_false(duplicate.get("applied", false))
	assert_eq(io.files, files_before)
	var stale := _save(store, _candidate(neutral, "match-2"), 0)
	assert_eq(stale.get("status"), "CONFLICT")
	assert_eq(io.files, files_before)


func test_save_rereads_disk_generation_instead_of_trusting_loaded_ram() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	_put(io, "b", _payload(neutral, 2, "external-writer"))
	var before := io.files.duplicate(true)
	var result := _save(store, _candidate(neutral), 0)
	if not _result_shape(result):
		return
	assert_eq(result.status, "CONFLICT")
	assert_false(result.get("applied", false))
	assert_eq(io.files, before)


func test_save_rejects_nonfinite_memory_mismatched_ids_or_overflow_before_writing(params = use_parameters([
	"nan", "infinity", "bool", "different_match", "too_long_match", "max_generation", "wrong_compatibility",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var candidate := _candidate(neutral)
	match params:
		"nan": candidate.memory.cells[CELL].q = NAN
		"infinity": candidate.memory.cells[CELL].n = INF
		"bool": candidate.memory.generation = true
		"different_match": candidate.match_id = "does-not-match-memory"
		"too_long_match":
			candidate.match_id = "m".repeat(65)
			candidate.memory.last_match_id = candidate.match_id
		"max_generation":
			candidate.memory.generation = MAX_GENERATION
			_put(io, "a", _payload(neutral, MAX_GENERATION, "previous-max"))
			store.load_compatible(_config())
		"wrong_compatibility": candidate.memory.compatibility_id = "c".repeat(64)
	var files_before := io.files.duplicate(true)
	io.calls.clear()
	var result := _save(store, candidate, MAX_GENERATION if params == "max_generation" else 0)
	if not _result_shape(result):
		return
	assert_true(result.status in ["INVALID", "INCOMPATIBLE"])
	assert_false(result.get("applied", false))
	assert_false(result.get("saved", false))
	assert_eq(io.files, files_before)
	for call: String in io.calls:
		assert_false(call.begins_with("write:") or call.begins_with("open:"))


func test_write_stage_and_readback_failures_never_publish_ram_or_damage_active_slot(params = use_parameters([
	"open", "write", "flush", "close", "readback", "tamper",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var first := _save(store, _candidate(neutral, "previous"), 0)
	if not _result_shape(first):
		return
	var active := io.last_written
	var active_text: String = io.files.get(active, "")
	io.fail_stage = "" if params == "tamper" else params
	io.tamper_after_write = params == "tamper"
	var failed := _save(store, _candidate(first.memory, "new"), 1)
	if not _result_shape(failed):
		return
	assert_eq(failed.status, "IO_ERROR")
	assert_false(failed.get("saved", false))
	assert_false(failed.get("applied", false))
	assert_eq(failed.memory, first.memory, "RAM sólo se publica tras validación de relectura")
	assert_eq(io.files.get(active), active_text)
	assert_ne(io.last_written, active)


func test_load_io_errors_have_explicit_status_and_neutral_memory(params = use_parameters([
	"exists", "size", "read",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	_put(io, "a", _payload(neutral))
	io.fail_stage = params
	var result := store.load_compatible(_config())
	if not _result_shape(result):
		return
	assert_eq(result.status, "IO_ERROR")
	assert_eq(result.memory.cells, {})


func test_transient_publishes_ram_with_saved_false_and_performs_zero_io() -> void:
	var io := FakeIO.new()
	io.fail_stage = "exists" # Cualquier acceso quedaría registrado y fallaría.
	var store := _store(io)
	store.transient = true
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var saved := _save(store, _candidate(neutral), 0)
	if not _result_shape(saved):
		return
	assert_eq(saved.status, "OK")
	assert_true(saved.get("applied", false))
	assert_false(saved.get("saved", true))
	assert_eq(saved.memory.generation, 1)
	assert_eq(store.load_compatible(_config()).get("memory"), saved.memory)
	assert_eq(io.calls, [], "TRANSIENT no inspecciona ni lee ni escribe rutas reales")
	assert_eq(DirAccess.get_files_at(_directory).size(), 0)


func test_returned_memory_is_detached_from_store_ram() -> void:
	var store := _store()
	store.transient = true
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var candidate := _candidate(neutral)
	var saved := _save(store, candidate, 0)
	if not _result_shape(saved):
		return
	candidate.memory.cells.clear()
	saved.memory.cells.clear()
	var loaded := store.load_compatible(_config())
	if not _result_shape(loaded):
		return
	assert_eq(loaded.memory.cells.size(), 1)


func _cleared(store: CommanderMemoryStore) -> Dictionary:
	var result := store.clear()
	var shape_ok := result.has_all(["status", "memory", "applied", "saved"])
	assert_true(shape_ok, "clear debe comunicar resultado explícito y distinguir borrado persistente de RAM")
	return result if shape_ok else {}


func _two_generations(store: CommanderMemoryStore) -> Dictionary:
	var neutral := _neutral(store)
	if neutral.is_empty():
		return {}
	var first := _save(store, _candidate(neutral, "clear-previous"), 0)
	if not _result_shape(first):
		return {}
	assert_eq(first.status, "OK")
	var second := _save(store, _candidate(first.memory, "clear-current"), 1)
	if not _result_shape(second):
		return {}
	assert_eq(second.status, "OK")
	return second.memory


func _write_witness() -> String:
	var path := _directory.path_join("intro_progress.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	if file != null:
		file.store_string("intro-only-witness: capítulo-á; preferences unchanged")
		file.close()
	return path


func test_clear_real_files_removes_both_slots_restarts_neutral_and_preserves_foreign_witness() -> void:
	var witness := _write_witness()
	var witness_before := FileAccess.get_file_as_bytes(witness)
	var store := _store()
	var previous := _two_generations(store)
	if previous.is_empty():
		return
	assert_true(FileAccess.file_exists(_path("a")))
	assert_true(FileAccess.file_exists(_path("b")))
	var result := _cleared(store)
	if result.is_empty():
		return
	assert_eq(result.status, "OK")
	assert_true(result.applied)
	assert_true(result.saved)
	assert_eq(result.memory.cells, {})
	assert_eq(result.memory.generation, 0)
	assert_eq(result.memory.last_match_id, "")
	assert_false(FileAccess.file_exists(_path("a")))
	assert_false(FileAccess.file_exists(_path("b")))
	assert_eq(FileAccess.get_file_as_bytes(witness), witness_before)
	assert_eq(DirAccess.get_files_at(_directory), PackedStringArray(["intro_progress.json"]))
	var reopened := _neutral(_store())
	assert_false(reopened.is_empty())


func test_clear_deletes_inactive_before_active_and_checks_absence_of_each() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var previous := _two_generations(store)
	if previous.is_empty():
		return
	var active := io.last_written
	var inactive := _path("a") if active == _path("b") else _path("b")
	io.calls.clear()
	var result := _cleared(store)
	if result.is_empty():
		return
	assert_eq(result.status, "OK")
	var remove_calls: Array[String] = []
	for call: String in io.calls:
		if call.begins_with("remove:"):
			remove_calls.append(call)
	assert_eq(remove_calls, ["remove:" + inactive, "remove:" + active])
	for path in [inactive, active]:
		var remove_index := io.calls.find("remove:" + path)
		var last_check := io.calls.rfind("exists:" + path)
		assert_gt(last_check, remove_index, "No basta recibir OK de remove: verificar ausencia después")
	assert_eq(io.files, {})
	assert_eq(result.memory.cells, {})


func test_clear_missing_slots_is_idempotent_without_recreating_any_file() -> void:
	var io := FakeIO.new()
	var store := _store(io)
	if _neutral(store).is_empty():
		return
	for attempt in 2:
		var result := _cleared(store)
		if result.is_empty():
			return
		assert_eq(result.status, "OK")
		assert_true(result.applied)
		assert_true(result.saved)
		assert_eq(result.memory.cells, {})
	assert_eq(io.files, {})
	for call: String in io.calls:
		assert_false(call.begins_with("open:") or call.begins_with("write:"), "Clear no guarda un backup ni repuebla memoria")


func test_clear_also_removes_invalid_copies_and_leaves_foreign_file_untouched() -> void:
	var witness := _write_witness()
	var before := FileAccess.get_file_as_bytes(witness)
	for slot in ["a", "b"]:
		var file := FileAccess.open(_path(slot), FileAccess.WRITE)
		assert_not_null(file)
		if file != null:
			file.store_string("{corrupt slot")
			file.close()
	var store := _store()
	assert_eq(store.load_compatible(_config()).get("status"), "INVALID")
	var result := _cleared(store)
	if result.is_empty():
		return
	assert_eq(result.status, "OK")
	assert_false(FileAccess.file_exists(_path("a")))
	assert_false(FileAccess.file_exists(_path("b")))
	assert_eq(FileAccess.get_file_as_bytes(witness), before)
	assert_false(_neutral(_store()).is_empty())


func test_clear_remove_failure_preserves_ram_and_remaining_disk_copy_is_revalidated(params = use_parameters([
	"inactive", "active",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var previous := _two_generations(store)
	if previous.is_empty():
		return
	var active := io.last_written
	var inactive := _path("a") if active == _path("b") else _path("b")
	var active_bytes: String = io.files[active]
	io.fail_remove_path = inactive if params == "inactive" else active
	var result := _cleared(store)
	if result.is_empty():
		return
	assert_eq(result.status, "IO_ERROR")
	assert_false(result.applied)
	assert_false(result.saved)
	assert_eq(result.memory, previous)
	assert_eq(io.files.get(active), active_bytes)
	if params == "active":
		assert_false(io.files.has(inactive), "Fallo parcial: el primer borrado puede haber sucedido")
	io.fail_remove_path = ""
	var reloaded := _store(io).load_compatible(_config())
	if not _result_shape(reloaded):
		return
	assert_eq(reloaded.status, "OK")
	assert_eq(reloaded.memory, previous)


func test_clear_rejects_reported_success_when_a_file_still_exists(params = use_parameters([
	"inactive", "active",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var previous := _two_generations(store)
	if previous.is_empty():
		return
	var active := io.last_written
	var inactive := _path("a") if active == _path("b") else _path("b")
	io.lie_remove_path = inactive if params == "inactive" else active
	var result := _cleared(store)
	if result.is_empty():
		return
	assert_eq(result.status, "IO_ERROR")
	assert_false(result.applied)
	assert_false(result.saved)
	assert_eq(result.memory, previous)
	assert_true(io.files.has(io.lie_remove_path))
	io.lie_remove_path = ""
	var reloaded := _store(io).load_compatible(_config())
	if not _result_shape(reloaded):
		return
	assert_eq(reloaded.status, "OK", "Reabrir valida cualquier slot restante; no asumir borrado que falló")
	assert_eq(reloaded.memory.cells.size(), 1)


func test_clear_verification_io_error_preserves_ram_even_if_deletion_already_happened(params = use_parameters([
	"inactive", "active",
])) -> void:
	var io := FakeIO.new()
	var store := _store(io)
	var previous := _two_generations(store)
	if previous.is_empty():
		return
	var active := io.last_written
	var inactive := _path("a") if active == _path("b") else _path("b")
	io.fail_verify_path = inactive if params == "inactive" else active
	var result := _cleared(store)
	if result.is_empty():
		return
	assert_eq(result.status, "IO_ERROR")
	assert_false(result.applied)
	assert_false(result.saved)
	assert_eq(result.memory, previous)
	assert_false(io.files.has(io.fail_verify_path), "El fallo de verificación ocurre después de eliminar el archivo")
	io.fail_verify_path = ""
	var reloaded := _store(io).load_compatible(_config())
	if not _result_shape(reloaded):
		return
	assert_true(reloaded.status in ["OK", "MISSING"])
	assert_eq(reloaded.memory.cells.size(), 1 if reloaded.status == "OK" else 0)


func test_clear_transient_only_resets_ram_without_inspecting_or_deleting_persisted_copies() -> void:
	var witness := _write_witness()
	var witness_before := FileAccess.get_file_as_bytes(witness)
	var io := FakeIO.new()
	io.files[_path("a")] = "inaccessible persisted A"
	io.files[_path("b")] = "inaccessible persisted B"
	var untouched := io.files.duplicate(true)
	io.fail_stage = "exists"
	var store := _store(io)
	store.transient = true
	var neutral := _neutral(store)
	if neutral.is_empty():
		return
	var saved := _save(store, _candidate(neutral), 0)
	assert_eq(saved.get("status"), "OK")
	var result := _cleared(store)
	if result.is_empty():
		return
	assert_eq(result.status, "OK")
	assert_true(result.applied)
	assert_false(result.saved, "No afirmar que se borraron copias inaccesibles")
	assert_eq(result.memory.cells, {})
	assert_eq(result.memory.generation, 0)
	assert_eq(io.calls, [])
	assert_eq(io.files, untouched)
	assert_eq(FileAccess.get_file_as_bytes(witness), witness_before)
	var reloaded := store.load_compatible(_config())
	assert_eq(reloaded.get("memory", {}).get("cells", {"wrong": true}), {})


func test_compatibility_fixtures_never_mutate_authored_wave_entries_or_combat_resources() -> void:
	var sources := _sources()
	var enemy_fields: Array[String] = ["max_health", "move_speed", "melee_damage", "rifle_range",
		"rifle_damage", "rifle_interval", "ammo_drop"]
	for number in range(1, 11):
		var authored: WaveData = load("res://resources/waves/nivel_montecalvo_oleada_%02d.tres" % number)
		var fixture: WaveData = sources.waves[number - 1]
		assert_not_same(fixture, authored)
		for index in authored.spawn_entries.size():
			var original: WaveSpawnEntry = authored.spawn_entries[index]
			var copy: WaveSpawnEntry = fixture.spawn_entries[index]
			assert_not_same(copy, original, "Entradas en Array requieren copia propia")
			assert_not_same(copy.enemy_stats, original.enemy_stats, "Los stats anidados nunca deben ser compartidos")
			var before_count := original.count
			var before_interval := original.spawn_interval
			copy.count += 1
			copy.spawn_interval += 0.1
			assert_eq(original.count, before_count)
			assert_eq(original.spawn_interval, before_interval)
			for field: String in enemy_fields:
				var before: Variant = original.enemy_stats.get(field)
				copy.enemy_stats.set(field, copy.enemy_stats.get(field) + 1)
				assert_eq(original.enemy_stats.get(field), before, "Fixture no altera stat autorado: " + field)
	var soldier: UnitStats = load("res://resources/units/soldado_base_stats.tres")
	var original_damage := soldier.damage_per_shot
	sources.soldier_stats.damage_per_shot += 1
	assert_eq(soldier.damage_per_shot, original_damage)
	var board: LaneBoardConfig = load("res://resources/levels/monte_calvo_board.tres")
	var homes_before := board.home_cells.duplicate()
	var spawns_before := board.spawn_positions.duplicate()
	sources.board.home_cells[0].x += 1
	sources.board.spawn_positions[0].x += 1
	assert_eq(board.home_cells, homes_before)
	assert_eq(board.spawn_positions, spawns_before)
