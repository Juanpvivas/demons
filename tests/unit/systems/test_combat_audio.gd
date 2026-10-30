extends GutTest
## 014/T004–T005: audio observa hechos reales; PCM silencioso sólo es fixture.
const SOLDIER := preload("res://scenes/units/Soldado.tscn")
const ENEMY := preload("res://scenes/enemies/EnemigoBase.tscn")
const TARGET := preload("res://tests/unit/units/enemigo_double.gd")
const INTRO := preload("res://scenes/ui/IntroPlayer.tscn")
var _world: Node2D
var _audio: CombatAudio
var _profile: CombatAudioProfile
var _controllers: Array[CombatAudio] = []
var _events: Array[StringName] = []
var _saved: Dictionary


func _stream(seconds := 4.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var pcm := PackedByteArray()
	pcm.resize(int(seconds * 22050) * 2)
	stream.data = pcm
	return stream


func _controller(events: Array[StringName]) -> CombatAudio:
	var audio := CombatAudio.new()
	_world.add_child(audio)
	audio.cue_started.connect(func(cue: StringName): events.append(cue))
	audio.setup(_profile)
	_controllers.append(audio)
	return audio


func before_each() -> void:
	_saved = {"state": GameStateManager._current_state, "ammo": EconomyManager.collected_ammo, "waves": {}}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved.waves[key] = WaveManager.get(key)
	WaveManager.cancel_waves()
	GameStateManager.start_new_match()
	EconomyManager.collected_ammo = 100
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	_world = Node2D.new()
	viewport.add_child(_world)
	_profile = CombatAudioProfile.new()
	_profile.combat_voice_count = 2 # Configuración pequeña discrimina combate + resultado reservado.
	_profile.rifle = [_stream()]
	_profile.enemy_death = [_stream()]
	_profile.soldier_death = [_stream()]
	_profile.victory = [_stream()]
	_profile.defeat = [_stream()]
	_controllers.clear()
	_events.clear()
	_audio = _controller(_events)


func after_each() -> void:
	for audio: CombatAudio in _controllers:
		if is_instance_valid(audio):
			audio.close_match()
	GameStateManager._current_state = _saved.state
	EconomyManager.collected_ammo = _saved.ammo
	for key: String in _saved.waves:
		WaveManager.set(key, _saved.waves[key])


func _soldier(ammo := 2) -> Soldado:
	var actor := SOLDIER.instantiate() as Soldado
	actor.stats = actor.stats.duplicate()
	actor.stats.max_ammo = ammo
	actor.stats.fire_rate = 1.0
	actor.position = Vector2(144, 336)
	actor.set_grid_cell(Vector2i(1, 3))
	_world.add_child(actor)
	_audio.register_actor(actor)
	return actor


func _enemy(audio: CombatAudio = null) -> Enemigo:
	if audio == null: audio = _audio
	var actor := ENEMY.instantiate() as Enemigo
	actor.stats = actor.stats.duplicate()
	actor.stats.move_speed = 0.0
	actor.stats.max_health = 100
	actor.stats.ammo_drop = 0
	actor.position = Vector2(900, 528)
	_world.add_child(actor)
	audio.register_actor(actor)
	return actor


func _kill(audio: CombatAudio = null) -> void:
	if audio == null: audio = _audio
	var actor := _enemy(audio)
	assert_true(actor.take_damage(9999), "Control positivo: la transacción mata un enemigo real")


func _players(audio: Node = null) -> Array[AudioStreamPlayer]:
	if audio == null: audio = _audio
	var result: Array[AudioStreamPlayer] = []
	for node: Node in audio.find_children("*", "AudioStreamPlayer", true, false):
		result.append(node as AudioStreamPlayer)
	return result


func _playing(audio: Node = null) -> Array[AudioStreamPlayer]:
	return _players(audio).filter(func(player: AudioStreamPlayer): return player.playing)


func _win() -> void:
	var entry := WaveSpawnEntry.new()
	entry.enemy_stats = EnemyStats.new()
	entry.count = 1
	var wave := WaveData.new()
	wave.spawn_entries = [entry]
	WaveManager.start_waves([wave])
	WaveManager.notify_enemy_defeated()


func _callbacks(actor: Node, signal_name: StringName, receiver: Object) -> Array[Callable]:
	var result: Array[Callable] = []
	for entry: Dictionary in actor.get_signal_connection_list(signal_name):
		if entry.callable.get_object() == receiver:
			result.append(entry.callable)
	return result


func test_real_rifle_confirmation_including_last_bullet_is_one_cue(ammo = use_parameters([1, 2])) -> void:
	var actor := _soldier(ammo)
	_audio.register_actor(actor) # Registro repetido no duplica la observación.
	var target := TARGET.new()
	target.position = actor.position + Vector2(150, 0)
	_world.add_child(target)
	var consumed := false
	for frame in 45:
		if actor.get_reload_state().ammo == ammo - 1:
			consumed = true
			break
		await wait_physics_frames(1)
	assert_true(consumed, "Control positivo: física/consumo real, sin emitir la señal manualmente")
	assert_eq(target.damage_received, [actor.stats.damage_per_shot])
	assert_eq(actor.get_reload_state().morale, 0.0)
	assert_eq(_events, [&"rifle"], "Una petición por el hecho confirmado, también la última bala")
	assert_eq(_audio.get_active_voice_count(), 1)


func test_no_sound_for_no_target_rejected_target_or_reload(scenario = use_parameters(["no_target", "behind", "no_ammo", "reload"])) -> void:
	var actor := _soldier()
	if scenario in ["behind", "no_ammo"]:
		var target := TARGET.new()
		target.position = actor.position + Vector2(-150 if scenario == "behind" else 150, 0)
		_world.add_child(target)
	if scenario == "no_ammo":
		actor.set("_current_ammo", 0)
		actor.set("_mode", Soldado.SoldierMode.MELEE)
	if scenario == "reload":
		actor.set("_current_ammo", 0)
		actor.set("_mode", Soldado.SoldierMode.MELEE)
		assert_true(actor.request_reload(), "Control: recarga aceptada por la API jugable")
	await wait_physics_frames(5)
	assert_eq(actor.get_reload_state().ammo, 0 if scenario == "no_ammo" else actor.stats.max_ammo)
	assert_true(_events.is_empty(), "Apuntar/rechazar/recargar no son disparos")
	assert_eq(_audio.get_active_voice_count(), 0)


func test_nonlethal_damage_is_silent_and_each_real_death_sounds_once(side = use_parameters(["enemy", "soldier"])) -> void:
	var actor: Node = _enemy() if side == "enemy" else _soldier()
	_audio.register_actor(actor)
	assert_false(actor.take_damage(1), "Control: daño no letal")
	assert_true(_events.is_empty())
	assert_true(actor.take_damage(9999), "Control: baja confirmada")
	assert_false(actor.take_damage(9999), "El actor ya muerto rechaza otra baja")
	assert_eq(_events, [&"enemy_death"] if side == "enemy" else [&"soldier_death"])
	assert_eq(_audio.get_active_voice_count(), 1)


func test_cleanup_and_pool_release_do_not_invent_death() -> void:
	var actor := _enemy()
	actor.on_pool_released()
	assert_false(actor.is_targetable())
	actor.queue_free()
	var soldier := _soldier()
	soldier.queue_free()
	await wait_process_frames(2)
	assert_true(_events.is_empty())
	assert_eq(_audio.get_active_voice_count(), 0)


func test_recycled_actor_accepts_a_new_death_and_ignores_old_delivery() -> void:
	var pool := ObjectPool.new()
	_world.add_child(pool)
	pool.instance_created.connect(func(node: Node):
		(node as Enemigo).set_pool(pool)
		_audio.register_actor(node))
	pool.setup(ENEMY, 1)
	var enemy := pool.acquire() as Enemigo
	var stats := enemy.stats.duplicate() as EnemyStats
	stats.move_speed = 0.0
	stats.ammo_drop = 0
	enemy.prepare_for_spawn(stats, Vector2(900, 528), 4)
	var old := _callbacks(enemy, &"defeat_visual_requested", _audio)
	var snapshots: Array[Dictionary] = []
	enemy.defeat_visual_requested.connect(func(snapshot: Dictionary): snapshots.append(snapshot))
	enemy.enemy_defeated.connect(func(_amount: int, _at: Vector2): pool.release(enemy))
	assert_true(enemy.take_damage(9999))
	assert_eq(snapshots.size(), 1, "Control: snapshot real de la primera muerte")
	assert_eq(_events, [&"enemy_death"])
	var generation := enemy.activation_generation
	var reused := pool.acquire() as Enemigo
	assert_same(reused, enemy, "Control: mismo nodo físico")
	reused.prepare_for_spawn(stats, Vector2(900, 528), 4)
	assert_gt(reused.activation_generation, generation)
	assert_false(old.is_empty(), "Observador vigente capturable antes del reciclado")
	for callback: Callable in old:
		callback.call(snapshots[0]) # Entrega antigua mientras la nueva activación sigue viva.
	assert_eq(_events, [&"enemy_death"], "El snapshot anterior no representa otra baja")
	assert_true(reused.take_damage(9999))
	assert_eq(_events, [&"enemy_death", &"enemy_death"], "Otra activación sí tiene su baja")


func test_real_result_is_unique_and_menu_does_not_create_a_result(outcome = use_parameters(["won", "lost"])) -> void:
	if outcome == "won":
		_win()
		WaveManager.notify_enemy_defeated()
	else:
		GameStateManager.report_reached_defended_position()
		GameStateManager.report_reached_defended_position()
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON if outcome == "won" else GameStateManager.GameState.LOST)
	assert_eq(_events, [&"victory"] if outcome == "won" else [&"defeat"])
	GameStateManager.enter_menu()
	assert_eq(_audio.get_active_voice_count(), 0)
	assert_eq(_events.size(), 1, "Menú no inventa otro resultado")


func test_final_lethal_shot_death_and_victory_are_all_admitted_before_terminal() -> void:
	var soldier := _soldier(1)
	var enemy := _enemy()
	enemy.global_position = soldier.global_position + Vector2(150, 0)
	enemy.set("_current_health", soldier.stats.damage_per_shot)
	var entry := WaveSpawnEntry.new()
	entry.enemy_stats = enemy.stats
	entry.count = 1
	var wave := WaveData.new()
	wave.spawn_entries = [entry]
	WaveManager.start_waves([wave])
	enemy.enemy_defeated.connect(func(_amount: int, _at: Vector2): WaveManager.notify_enemy_defeated())
	for frame in 45:
		if GameStateManager._current_state == GameStateManager.GameState.WON:
			break
		await wait_physics_frames(1)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON, "Control: última baja completa oleada real")
	assert_eq(soldier.get_reload_state().ammo, 0)
	assert_eq(soldier.get_reload_state().morale, soldier.stats.moral_per_kill)
	assert_eq(_events, [&"rifle", &"enemy_death", &"victory"])
	assert_eq(_audio.get_active_voice_count(), 3, "Resultado no corta tiro y baja ya admitidos")


func test_burst_reuses_fixed_capacity_and_keeps_result_reserved() -> void:
	_audio.close_match()
	_profile.enemy_death = [_stream(0.06)]
	_audio = _controller(_events)
	assert_eq(_audio.get_voice_capacity(), _profile.combat_voice_count + 1, "Capacidad TOTAL incluye terminal")
	var initial_ids: Array[int] = []
	for player: AudioStreamPlayer in _players(): initial_ids.append(player.get_instance_id())
	for event in 15: _kill()
	assert_eq(_events.size(), 15, "Saturar sustituye al más antiguo; no encola ni pierde el hecho aceptado")
	assert_eq(_playing().size(), _profile.combat_voice_count)
	await wait_seconds(0.3) # Los dos clips de60ms terminan; una cola de15 seguiría sonando.
	assert_eq(_audio.get_active_voice_count(), 0, "No reproducir una cola atrasada al liberarse voces")
	assert_eq(_events.size(), 15)
	for event in 2: _kill()
	_win()
	assert_eq(_playing().size(), _profile.combat_voice_count + 1)
	var terminal: AudioStreamPlayer
	for player: AudioStreamPlayer in _playing():
		if player.stream == _profile.victory[0]: terminal = player
	assert_not_null(terminal, "Resultado conserva un reproductor propio")
	for event in 8: _kill()
	assert_eq(_events.size(), 18, "Fuera de PLAYING no se aceptan nuevos combates")
	if terminal != null: assert_true(terminal.playing)
	var final_ids: Array[int] = []
	for player: AudioStreamPlayer in _players(): final_ids.append(player.get_instance_id())
	assert_eq(final_ids, initial_ids, "No crece el número de nodos bajo ráfagas")


func test_old_finished_callback_cannot_retire_a_reused_voice() -> void:
	# Un solo slot de combate hace observable su reutilización sin depender de IDs privados.
	_audio.close_match()
	_profile.combat_voice_count = 1
	_audio = _controller(_events)
	_kill()
	var voices := _playing()
	assert_eq(voices.size(), 1)
	if voices.size() != 1: return
	var voice := voices[0]
	var previous := _callbacks(voice, &"finished", _audio)
	assert_false(previous.is_empty(), "Control: fin de la voz está observado")
	_kill()
	for callback: Callable in previous: callback.call()
	assert_true(voice.playing, "Entrega vieja no detiene la voz que sustituyó la anterior")
	assert_eq(_audio.get_active_voice_count(), 1)


func test_pause_or_lost_focus_discards_old_one_shots_without_a_backlog(reason = use_parameters(["pause", "focus"])) -> void:
	_kill()
	assert_eq(_events.size(), 1)
	assert_eq(_audio.get_active_voice_count(), 1)
	if reason == "pause":
		GameStateManager._current_state = GameStateManager.GameState.PAUSED # No existe API pública de pausa.
		GameStateManager.game_state_changed.emit(GameStateManager._current_state)
	else:
		_audio.set_application_active(false)
	assert_eq(_audio.get_active_voice_count(), 0)
	_kill()
	assert_eq(_events.size(), 1)
	if reason == "pause":
		GameStateManager._current_state = GameStateManager.GameState.PLAYING
		GameStateManager.game_state_changed.emit(GameStateManager._current_state)
	else:
		_audio.set_application_active(true)
	await wait_process_frames(2)
	assert_eq(_events.size(), 1, "Regresar no reproduce las peticiones descartadas")
	assert_eq(_audio.get_active_voice_count(), 0)
	_kill()
	assert_eq(_events.size(), 2, "Sólo vuelve a aceptar hechos nuevos")


func test_terminal_focus_return_does_not_replay_the_result() -> void:
	GameStateManager.report_reached_defended_position()
	assert_eq(_events, [&"defeat"])
	_audio.set_application_active(false)
	assert_eq(_audio.get_active_voice_count(), 0)
	_audio.set_application_active(true)
	GameStateManager.report_reached_defended_position()
	await wait_process_frames(2)
	assert_eq(_audio.get_active_voice_count(), 0)
	assert_eq(_events, [&"defeat"])


func test_close_invalidates_actor_callbacks_and_does_not_reopen_the_session() -> void:
	var actor := _enemy()
	var old := _callbacks(actor, &"defeat_visual_requested", _audio)
	assert_false(old.is_empty(), "Registro tiene un observador real")
	var snapshot: Dictionary = actor.get_node("AnimatedSprite2D").capture_defeat_snapshot(actor.global_position)
	_audio.close_match()
	_audio.close_match()
	for callback: Callable in old: callback.call(snapshot)
	actor.take_damage(9999)
	_audio.register_actor(_enemy())
	_audio.set_application_active(true)
	GameStateManager.report_reached_defended_position()
	assert_true(_events.is_empty())
	assert_eq(_audio.get_active_voice_count(), 0)
	assert_true(_callbacks(actor, &"defeat_visual_requested", _audio).is_empty(), "Cierre desconecta actores")


func test_local_cosmetic_randomness_does_not_consume_gameplay_rng() -> void:
	var actor := _enemy()
	seed(14005)
	var expected := randi()
	seed(14005)
	var events: Array[StringName] = []
	var other := _controller(events)
	other.register_actor(actor)
	actor.take_damage(9999)
	assert_eq(randi(), expected, "Setup, selección/pitch/volumen no consumen RNG global")
	randomize() # No dejar una semilla fija de fixture a otros archivos.
	assert_eq(events, [&"enemy_death"], "Control: hubo una petición cosmética real")


func _bus_snapshot() -> Array:
	var result: Array = []
	for index in AudioServer.bus_count:
		var effects: Array[int] = []
		for effect in AudioServer.get_bus_effect_count(index): effects.append(AudioServer.get_bus_effect(index, effect).get_instance_id())
		result.append([AudioServer.get_bus_name(index), AudioServer.get_bus_send(index), AudioServer.get_bus_volume_db(index), AudioServer.is_bus_mute(index), effects])
	return result


func test_gameplay_players_use_the_isolated_effects_route_and_stream_playback() -> void:
	assert_gte(AudioServer.get_bus_index(&"GameplaySFX"), 0, "Ruta estática que permite limitar sólo combate")
	var players := _players()
	assert_eq(players.size(), _profile.combat_voice_count + 1)
	for player: AudioStreamPlayer in players:
		assert_eq(player.bus, &"GameplaySFX", "Ninguna voz de combate elude su mezcla")
		assert_eq(player.playback_type, AudioServer.PLAYBACK_TYPE_STREAM, "Web Sample no aplica AudioEffects; Stream es necesario en estas voces")


func test_closing_one_controller_preserves_another_and_the_intro_mix() -> void:
	var other_events: Array[StringName] = []
	var other := _controller(other_events)
	var intro := INTRO.instantiate()
	_world.add_child(intro)
	var sequence := IntroSequence.new()
	var slide := IntroSlide.new()
	slide.subtitle = "Narración de fixture ajena al combate"
	slide.minimum_duration = 10.0
	slide.narration = _stream()
	sequence.slides = [slide]
	sequence.ambience = _stream()
	intro.play(sequence)
	intro.set_process(false)
	var intro_channels: Array[AudioStreamPlayer] = []
	for node: Node in intro.find_children("*", "AudioStreamPlayer", true, false): intro_channels.append(node as AudioStreamPlayer)
	assert_eq(intro_channels.size(), 2, "Control positivo: intro tiene voz y ambiente independientes")
	var intro_routes: Array = []
	for player: AudioStreamPlayer in intro_channels:
		assert_true(player.playing)
		intro_routes.append([player.bus, player.playback_type])
	_kill()
	_kill(other)
	assert_eq(_events, [&"enemy_death"])
	assert_eq(other_events, [&"enemy_death"])
	var buses := _bus_snapshot()
	_audio.close_match()
	assert_eq(_audio.get_active_voice_count(), 0)
	assert_eq(other.get_active_voice_count(), 1, "Cierre local no silencia otra sesión del mismo bus")
	assert_eq(_bus_snapshot(), buses, "No mutar Master ni el bus compartido durante cierre")
	for index in intro_channels.size():
		assert_true(intro_channels[index].playing, "Ni voz ni ambiente013 son propiedad de este controller")
		assert_eq([intro_channels[index].bus, intro_channels[index].playback_type], intro_routes[index])
	intro.close_intro()
