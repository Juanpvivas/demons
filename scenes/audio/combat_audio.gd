## Presentación local del nivel: observa hechos, nunca decide el combate.
class_name CombatAudio
extends Node

signal cue_started(cue: StringName)

const _BUS: StringName = &"GameplaySFX"

var _profile: CombatAudioProfile
var _voices: Array[AudioStreamPlayer] = []
var _voice_generations: Array[int] = []
var _voice_orders: Array[int] = []
var _finished_callbacks: Array[Callable] = []
var _actors: Dictionary[int, Dictionary] = {}
var _rng := RandomNumberGenerator.new()
var _order: int = 0
var _session_generation: int = 0
var _application_active: bool = true
var _terminal: bool = false
var _closed: bool = false


func setup(profile: Resource) -> void:
	if _closed or _profile != null or not profile is CombatAudioProfile:
		return
	_profile = profile as CombatAudioProfile
	_session_generation += 1
	_rng.randomize() # Instancia cosmética; no consume el RNG global.
	for index in clampi(_profile.combat_voice_count, 1, 32) + 1:
		var player := AudioStreamPlayer.new()
		player.name = "CombatVoice%d" % index
		player.bus = _BUS
		# Sample Web omite AudioEffects y eludiría el limiter de este bus.
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player)
		_voices.append(player)
		_voice_generations.append(0)
		_voice_orders.append(0)
		_finished_callbacks.append(Callable())
	GameStateManager.game_state_changed.connect(_on_game_state_changed)


func register_actor(actor: Node) -> void:
	if _closed or _profile == null or not is_instance_valid(actor) \
			or not (actor is Soldado or actor is Enemigo):
		return
	var id := actor.get_instance_id()
	if _actors.has(id):
		return
	var death := _on_actor_defeated.bind(id, _session_generation)
	var shot := _on_rifle_shot.bind(id, _session_generation)
	var leaving := _on_actor_leaving.bind(id)
	_actors[id] = {"actor": weakref(actor), "death": death, "shot": shot,
		"leaving": leaving, "death_generation": -1, "last_shot": null}
	actor.connect(&"defeat_visual_requested", death)
	if actor is Soldado:
		actor.connect(&"rifle_shot_visual_requested", shot)
	actor.tree_exiting.connect(leaving)


func set_application_active(active: bool) -> void:
	_application_active = active
	if not active:
		_stop_voices()


func close_match() -> void:
	if _closed:
		return
	_closed = true
	_session_generation += 1
	_stop_voices()
	for id: int in _actors.keys():
		_on_actor_leaving(id)
	if GameStateManager.game_state_changed.is_connected(_on_game_state_changed):
		GameStateManager.game_state_changed.disconnect(_on_game_state_changed)


func get_active_voice_count() -> int:
	var count := 0
	for player: AudioStreamPlayer in _voices:
		if player.playing:
			count += 1
	return count


func get_voice_capacity() -> int:
	return _voices.size()


func _exit_tree() -> void:
	close_match()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED,
			NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		set_application_active(false)
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED,
			NOTIFICATION_WM_WINDOW_FOCUS_IN]:
		set_application_active(true)


func _on_actor_leaving(id: int) -> void:
	if not _actors.has(id):
		return
	var record: Dictionary = _actors[id]
	var actor: Node = record.actor.get_ref()
	if is_instance_valid(actor):
		if actor.is_connected(&"defeat_visual_requested", record.death):
			actor.disconnect(&"defeat_visual_requested", record.death)
		if actor is Soldado and actor.is_connected(&"rifle_shot_visual_requested", record.shot):
			actor.disconnect(&"rifle_shot_visual_requested", record.shot)
		if actor.tree_exiting.is_connected(record.leaving):
			actor.tree_exiting.disconnect(record.leaving)
	_actors.erase(id)


func _registered_actor(id: int, session: int) -> Node:
	if _closed or session != _session_generation or not _actors.has(id):
		return null
	return _actors[id].actor.get_ref() as Node


func _can_play_combat() -> bool:
	return not _closed and not _terminal and _application_active \
		and GameStateManager._current_state == GameStateManager.GameState.PLAYING


func _on_rifle_shot(snapshot: Dictionary, id: int, session: int) -> void:
	var actor := _registered_actor(id, session) as Soldado
	if actor == null or not actor.get_reload_state().alive:
		return
	if not snapshot.get("origin_world") is Vector2 or not snapshot.get("target_world") is Vector2:
		return
	if not (snapshot.origin_world as Vector2).is_finite() \
			or not (snapshot.target_world as Vector2).is_finite():
		return
	if is_same(_actors[id].last_shot, snapshot):
		return
	_actors[id].last_shot = snapshot
	if _can_play_combat():
		_play_cue(&"rifle", false)


func _on_actor_defeated(_snapshot: Dictionary, id: int, session: int) -> void:
	var actor := _registered_actor(id, session)
	if actor == null:
		return
	var generation := 0
	var cue: StringName = &"soldier_death"
	if actor is Enemigo:
		var enemy := actor as Enemigo
		# La baja ya desactivó el actor; el snapshot viejo no mata su nueva activación.
		if enemy.is_targetable():
			return
		generation = enemy.activation_generation
		cue = &"enemy_death"
	elif (actor as Soldado).get_reload_state().alive:
		return
	if _actors[id].death_generation == generation:
		return
	# Consumir también durante pausa/foco: nunca queda una petición atrasada.
	_actors[id].death_generation = generation
	if _can_play_combat():
		_play_cue(cue, false)


func _on_game_state_changed(state: int) -> void:
	if _closed:
		return
	if state == GameStateManager.GameState.MENU:
		close_match()
	elif state == GameStateManager.GameState.PAUSED:
		_stop_voices()
	elif state in [GameStateManager.GameState.WON, GameStateManager.GameState.LOST] and not _terminal:
		_terminal = true
		if _application_active:
			_play_cue(&"victory" if state == GameStateManager.GameState.WON else &"defeat", true)


func _play_cue(cue: StringName, terminal: bool) -> void:
	var streams: Array[AudioStream] = _profile.get(cue)
	if streams.is_empty():
		return
	var stream := streams[_rng.randi_range(0, streams.size() - 1)]
	if stream == null:
		return
	var index := _voices.size() - 1 if terminal else _combat_voice_index()
	_retire_voice(index)
	var player := _voices[index]
	_order += 1
	_voice_orders[index] = _order
	player.stream = stream
	player.volume_db = _profile.volume_db.get(cue, 0.0)
	player.pitch_scale = 1.0
	if not terminal:
		player.volume_db += _rng.randf_range(-_profile.volume_variation_db, _profile.volume_variation_db)
		player.pitch_scale = _rng.randf_range(_profile.pitch_range.x, _profile.pitch_range.y)
	var callback := _on_voice_finished.bind(index, _voice_generations[index], _session_generation)
	_finished_callbacks[index] = callback
	player.finished.connect(callback)
	player.play()
	cue_started.emit(cue)


func _combat_voice_index() -> int:
	var oldest := 0
	for index in _voices.size() - 1:
		if not _voices[index].playing:
			return index
		if _voice_orders[index] < _voice_orders[oldest]:
			oldest = index
	return oldest


func _on_voice_finished(index: int, generation: int, session: int) -> void:
	if not _closed and session == _session_generation and generation == _voice_generations[index]:
		_retire_voice(index)


func _retire_voice(index: int) -> void:
	var player := _voices[index]
	var callback := _finished_callbacks[index]
	if callback.is_valid() and player.finished.is_connected(callback):
		player.finished.disconnect(callback)
	_finished_callbacks[index] = Callable()
	_voice_generations[index] += 1
	player.stop()
	player.stream = null


func _stop_voices() -> void:
	for index in _voices.size():
		_retire_voice(index)
