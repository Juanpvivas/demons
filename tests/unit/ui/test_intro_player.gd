extends GutTest
## 013/T003: comportamiento observable con secuencias y audio breves.
const PLAYER := preload("res://scenes/ui/IntroPlayer.tscn")
const AUTHORED_SEQUENCE := preload("res://resources/narrative/la_carta.tres")
var _player: Control
var _sequence: IntroSequence


func _voice(seconds: float = 0.2) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(int(seconds * stream.mix_rate) * 2)
	stream.data = samples
	return stream


func before_each() -> void:
	_sequence = IntroSequence.new()
	_sequence.transition_duration = 0.0
	for text: String in ["Primera carta", "Segunda carta", "Tercera carta"]:
		var slide := IntroSlide.new()
		slide.subtitle = text
		slide.minimum_duration = 0.5
		slide.narration = _voice()
		_sequence.slides.append(slide)
	_player = PLAYER.instantiate() as Control
	add_child_autofree(_player)
	watch_signals(_player)
	_player.play(_sequence)
	_player.set_process(false) # El reloj público avanza sin esperar tiempo de pared.


func _texts() -> Array[String]:
	var result: Array[String] = []
	for node: Node in _player.find_children("*", "Label", true, false):
		if (node as Label).is_visible_in_tree():
			result.append((node as Label).text)
	return result


func _audio() -> AudioStreamPlayer:
	for node: Node in _player.find_children("*", "AudioStreamPlayer", true, false):
		if (node as AudioStreamPlayer).playing:
			return node as AudioStreamPlayer
	return null


func _complete() -> void:
	for step in 80:
		_player.advance_intro(0.1)


func test_play_presents_first_authored_text_and_voice() -> void:
	assert_almost_eq(_sequence.slides[0].narration.get_length(), 0.2, 0.001, "Control: clip PCM válido")
	assert_eq(_player.get_slide_index(), 0, "La carta empieza por la primera escena")
	assert_has(_texts(), "Primera carta", "El subtítulo corresponde al cuadro en curso")
	var audio := _audio()
	assert_not_null(audio, "La narración usa un reproductor activo")
	if audio != null:
		assert_same(audio.stream, _sequence.slides[0].narration)


func test_clock_preserves_minimum_reading_time_and_scene_order() -> void:
	_player.advance_intro(0.25)
	assert_eq(_player.get_slide_index(), 0, "No adelantar una escena antes de poder leerla")
	var observed: Array[int] = []
	for step in 50:
		var index: int = _player.get_slide_index()
		if index >= 0 and not observed.has(index):
			observed.append(index)
		_player.advance_intro(0.05)
	assert_eq(observed, [0, 1, 2], "La reproducción visita todos los cuadros en orden")


func test_audio_longer_than_nominal_slot_is_not_truncated() -> void:
	_player.close_intro()
	_sequence.slides[0].minimum_duration = 0.05
	_sequence.slides[0].narration = _voice(0.6)
	_player = PLAYER.instantiate() as Control
	add_child_autofree(_player)
	_player.play(_sequence)
	_player.set_process(false)
	_player.advance_intro(0.3)
	assert_eq(_player.get_slide_index(), 0, "El tiempo nominal no corta una frase más larga")
	assert_has(_texts(), "Primera carta")


func test_pause_stops_clock_and_voice_until_explicit_resume() -> void:
	_player.advance_intro(0.1)
	var audio := _audio()
	assert_not_null(audio, "Control: hay una frase que pausar")
	_player.pause_intro()
	var elapsed: float = _player.get_elapsed()
	var index: int = _player.get_slide_index()
	_player.advance_intro(3.0)
	assert_true(_player.is_intro_paused())
	assert_eq(_player.get_elapsed(), elapsed)
	assert_eq(_player.get_slide_index(), index)
	if audio != null:
		assert_true(audio.stream_paused, "La voz también se pausa")
	_player.resume_intro()
	_player.advance_intro(0.1)
	assert_false(_player.is_intro_paused())
	assert_gt(_player.get_elapsed(), elapsed, "Continuar retoma el reloj")
	if audio != null:
		assert_true(audio.playing)
		assert_false(audio.stream_paused)


func test_application_return_does_not_resume_without_player_intent() -> void:
	_player.set_application_active(false)
	var elapsed: float = _player.get_elapsed()
	_player.set_application_active(true)
	_player.advance_intro(3.0)
	assert_true(_player.is_intro_paused(), "Volver a la app conserva la pausa")
	assert_eq(_player.get_elapsed(), elapsed)
	_player.resume_intro()
	assert_false(_player.is_intro_paused())


func test_skip_emits_once_and_cancels_audio_and_future_progress() -> void:
	_player.skip_intro()
	_player.skip_intro()
	_complete()
	assert_signal_emit_count(_player, "finished", 1)
	assert_signal_emitted_with_parameters(_player, "finished", [true])
	assert_null(_audio(), "Omitir detiene la voz anterior")


func test_close_is_silent_and_late_advance_cannot_complete() -> void:
	_player.close_intro()
	_complete()
	_player.skip_intro()
	assert_true(_player.is_intro_closed())
	assert_signal_not_emitted(_player, "finished", "Cerrar a medias no cuenta como carta leída")
	assert_null(_audio())


func test_natural_end_emits_once_without_skip() -> void:
	_complete()
	_complete()
	_player.skip_intro()
	assert_signal_emit_count(_player, "finished", 1)
	assert_signal_emitted_with_parameters(_player, "finished", [false])
	assert_null(_audio())


func test_companion_follows_narrator_with_its_own_subtitle() -> void:
	_player.close_intro()
	var slide := IntroSlide.new()
	slide.minimum_duration = 1.5
	slide.subtitle = "Nos cuidamos entre todos."
	slide.narration = _voice(0.2)
	slide.companion_subtitle = "Compañero. Ya es hora."
	slide.companion_voice = _voice(0.2)
	var sequence := IntroSequence.new()
	sequence.transition_duration = 0.0
	sequence.slides = [slide]
	_player = PLAYER.instantiate() as Control
	add_child_autofree(_player)
	_player.play(sequence)
	_player.set_process(false)
	assert_has(_texts(), slide.subtitle)
	var companion_seen := false
	for step in 20:
		_player.advance_intro(0.05)
		if _texts().has(slide.companion_subtitle):
			companion_seen = true
			var audio := _audio()
			assert_not_null(audio)
			if audio != null:
				assert_same(audio.stream, slide.companion_voice)
			break
	assert_true(companion_seen, "La segunda voz tiene su propio turno y texto")


func test_missing_audio_keeps_subtitles_and_finish_available() -> void:
	_player.close_intro()
	var sequence := IntroSequence.new()
	var slide := IntroSlide.new()
	slide.subtitle = "La carta sigue disponible sin sonido."
	slide.minimum_duration = 0.2
	sequence.slides = [slide]
	sequence.transition_duration = 0.0
	_player = PLAYER.instantiate() as Control
	add_child_autofree(_player)
	watch_signals(_player)
	_player.play(sequence)
	_player.set_process(false)
	assert_has(_texts(), slide.subtitle)
	_complete()
	assert_signal_emitted(_player, "finished")


func test_start_prompt_waits_for_new_button_activation() -> void:
	_player.skip_intro()
	_player.show_start_prompt()
	await wait_process_frames(2)
	assert_signal_not_emitted(_player, "start_requested")
	var start: Button
	for node: Node in _player.find_children("*", "Button", true, false):
		if (node as Button).text == "Comenzar" and (node as Button).is_visible_in_tree():
			start = node as Button
	assert_not_null(start, "El final ofrece un inicio explícito")
	if start != null:
		start.pressed.emit()
		assert_signal_emit_count(_player, "start_requested", 1)


## 013/T016 R2: los recursos existentes permiten RED sin medios nuevos.
func _play_authored() -> void:
	_player.close_intro()
	_player = PLAYER.instantiate() as Control
	add_child_autofree(_player)
	_player.play(AUTHORED_SEQUENCE)
	_player.set_process(false)


func _playing_channels() -> Array[AudioStreamPlayer]:
	var result: Array[AudioStreamPlayer] = []
	for node: Node in _player.find_children("*", "AudioStreamPlayer", true, false):
		if (node as AudioStreamPlayer).playing:
			result.append(node as AudioStreamPlayer)
	return result


func test_r2_seven_images_show_only_voice_subtitles_without_header_labels() -> void:
	_play_authored()
	for index in AUTHORED_SEQUENCE.slides.size():
		assert_eq(_player.get_slide_index(), index, "Control: escena autorada vigente")
		var visible_text := _texts().filter(func(text: String): return not text.is_empty())
		assert_eq(visible_text, [AUTHORED_SEQUENCE.slides[index].subtitle],
			"Sólo el subtítulo hablado acompaña la imagen; sin contador, caption o aviso")
		for step in 200:
			_player.advance_intro(0.1)
			if _player.is_intro_closed() or _player.get_slide_index() != index:
				break


func test_r2_ambience_has_its_own_quiet_channel_and_shares_pause_and_focus() -> void:
	_play_authored()
	var channels := _playing_channels()
	assert_eq(channels.size(), 2, "Voz y ambiente reproducen en canales separados")
	if channels.size() != 2:
		return
	var voice: AudioStreamPlayer
	var ambience: AudioStreamPlayer
	for channel: AudioStreamPlayer in channels:
		if channel.stream == AUTHORED_SEQUENCE.slides[0].narration:
			voice = channel
		else:
			ambience = channel
	assert_not_null(voice)
	assert_not_null(ambience)
	if voice == null or ambience == null:
		return
	assert_lt(ambience.volume_db, voice.volume_db, "El fondo no domina la narración")
	var ambience_stream := ambience.stream
	_player.pause_intro()
	for channel: AudioStreamPlayer in channels:
		assert_true(channel.stream_paused)
	_player.set_application_active(false)
	_player.resume_intro()
	assert_true(_player.is_intro_paused(), "No continuar mientras la app está inactiva")
	_player.set_application_active(true)
	assert_true(_player.is_intro_paused(), "Recuperar foco no reanuda automáticamente")
	_player.resume_intro()
	for channel: AudioStreamPlayer in channels:
		assert_false(channel.stream_paused)
	var first: IntroSlide = AUTHORED_SEQUENCE.slides[0]
	_player.advance_intro(maxf(first.minimum_duration, first.narration.get_length()) + 1.0)
	assert_eq(_player.get_slide_index(), 1)
	assert_true(ambience.playing)
	assert_same(ambience.stream, ambience_stream, "El fondo continúa entre imágenes")


func test_r2_all_exit_paths_silence_both_channels_before_next_opening(
		exit_mode = use_parameters(["skip", "close", "finish"])) -> void:
	_play_authored()
	var previous_channels := _playing_channels()
	assert_eq(previous_channels.size(), 2, "Control: ambos canales estaban activos")
	if previous_channels.size() != 2:
		return
	if exit_mode == "skip":
		_player.skip_intro()
	elif exit_mode == "close":
		_player.close_intro()
	else:
		for slide: IntroSlide in AUTHORED_SEQUENCE.slides:
			_player.advance_intro(slide.minimum_duration + slide.narration.get_length() + 10.0)
	for channel: AudioStreamPlayer in previous_channels:
		assert_false(channel.playing, "Salida silencia voz y ambiente")
	_play_authored()
	assert_eq(_playing_channels().size(), 2)
	for channel: AudioStreamPlayer in previous_channels:
		assert_false(channel.playing, "Reabrir no revive canales del intento anterior")
