extends GutTest
## 010/T003: modelo visual público, vida breve y pool independiente del combate.
const EffectScene := preload("res://scenes/visuals/RifleShotVisualEffect.tscn")
const DeathFixtures := preload("res://tests/unit/units/visual_test_fixtures.gd")
var _world: Node2D
var _state_before: int
var _paused_before: bool


class RifleOnlyActor:
	extends Node
	signal rifle_shot_visual_requested(snapshot: Dictionary)


func before_each() -> void:
	_state_before = GameStateManager._current_state
	_paused_before = get_tree().paused
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	_world = Node2D.new()
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child_autofree(_world)


func after_each() -> void:
	get_tree().paused = _paused_before
	GameStateManager._current_state = _state_before


func _snapshot(origin := Vector2(194, 301), target := Vector2(294, 336)) -> Dictionary:
	return {"origin_world": origin, "target_world": target}


func _service(size := 1) -> CombatVisualEffects:
	var service := CombatVisualEffects.new()
	_world.add_child(service)
	service.setup(size)
	return service


func _effect() -> RifleShotVisualEffect:
	var effect := EffectScene.instantiate() as RifleShotVisualEffect
	_world.add_child(effect)
	return effect


func _rifles_below(node: Node) -> Array[RifleShotVisualEffect]:
	var result: Array[RifleShotVisualEffect] = []
	for child: Node in node.get_children():
		if child is RifleShotVisualEffect:
			result.append(child as RifleShotVisualEffect)
		result.append_array(_rifles_below(child))
	return result


func _active(service: CombatVisualEffects) -> Array[RifleShotVisualEffect]:
	var result: Array[RifleShotVisualEffect] = []
	for effect: RifleShotVisualEffect in _rifles_below(service):
		if not effect.get_shot_snapshot().is_empty():
			result.append(effect)
	return result


func _state(state: int) -> void:
	# No existe UI/API de pausa: simula exclusivamente su entrada observadora.
	GameStateManager._current_state = state
	GameStateManager.game_state_changed.emit(state)


func test_effect_copies_endpoints_and_exposes_no_mutable_actor_state() -> void:
	var effect := _effect()
	var input := _snapshot()
	var expected := input.duplicate()
	effect.play_snapshot(input)
	assert_true(effect.visible, "play_snapshot activa una presentación")
	assert_eq(effect.get_shot_snapshot(), expected, "Son los endpoints que gobiernan el dibujo")
	input.target_world = Vector2.ZERO
	var readback := effect.get_shot_snapshot()
	readback.origin_world = Vector2.ZERO
	assert_eq(effect.get_shot_snapshot(), expected, "Ni entrada ni getter comparten Dictionary mutable")
	assert_true(effect.get_groups().is_empty())
	assert_true(effect.find_children("*", "CollisionObject2D", true, false).is_empty())
	assert_false(effect.is_processing_input())
	assert_false(effect.is_processing_unhandled_input())


func test_effect_finishes_once_within_two_tenths_active_time() -> void:
	var effect := _effect()
	watch_signals(effect)
	effect.play_snapshot(_snapshot())
	var activation := effect.get_activation_id()
	assert_true(effect.visible)
	# El reloj visual usa idle; una espera física no controla su avance en CI.
	effect.set_process(false)
	effect._process(0.04)
	assert_true(effect.visible, "El flash no es una activación vacía del mismo tick")
	assert_eq(effect.get_shot_snapshot(), _snapshot(), "El modelo permanece activo durante el destello")
	effect._process(0.16)
	assert_false(effect.visible, "No supera0.20s activo ni deja un haz fijo")
	assert_true(effect.get_shot_snapshot().is_empty())
	assert_signal_emit_count(effect, "finished", 1)
	effect.complete_activation(activation)
	assert_signal_emit_count(effect, "finished", 1, "Finalización repetida es inerte")


func test_pool_prewarm_and_double_actor_registration_do_not_duplicate_one_request() -> void:
	var service := _service(2)
	var actor := RifleOnlyActor.new()
	_world.add_child(actor)
	service.register_actor(actor)
	service.register_actor(actor)
	assert_eq(service.get_available_rifle_effect_count(), 2)
	actor.rifle_shot_visual_requested.emit(_snapshot())
	assert_eq(service.get_active_rifle_effect_count(), 1, "Registro idempotente, incluso actor sólo de fusil")
	assert_eq(service.get_available_rifle_effect_count(), 1)
	assert_eq(_active(service).size(), 1)
	assert_eq(service.get_active_effect_count(), 0, "Getter histórico sigue describiendo sólo bajas")


func test_completing_rifle_effect_keeps_death_pool_active() -> void:
	var service := _service(1)
	service.request_defeat(DeathFixtures.snapshot())
	service.request_rifle_shot(_snapshot())
	assert_eq(service.get_active_effect_count(), 1)
	assert_eq(service.get_active_rifle_effect_count(), 1)
	var effects := _active(service)
	assert_eq(effects.size(), 1)
	if effects.size() != 1:
		return
	effects[0].complete_activation(effects[0].get_activation_id())
	assert_eq(service.get_active_rifle_effect_count(), 0)
	assert_eq(service.get_available_rifle_effect_count(), 1)
	assert_eq(service.get_active_effect_count(), 1, "Terminar el tiro no libera el efecto de baja")


func test_reuse_resets_presentation_and_stale_completion_cannot_finish_next_activation() -> void:
	var service := _service(1)
	var original_nodes := _rifles_below(service)
	assert_eq(original_nodes.size(), 1, "Pool precalentado antes del primer tiro")
	service.request_rifle_shot(_snapshot())
	var active := _active(service)
	assert_eq(active.size(), 1)
	if active.size() != 1:
		return
	var effect := active[0]
	var first_id := effect.get_activation_id()
	watch_signals(effect)
	effect.rotation = 0.7
	effect.scale = Vector2(2, 3)
	effect.modulate = Color(0.2, 0.3, 0.4, 0.1)
	effect.self_modulate = Color.RED
	effect.complete_activation(first_id)
	assert_eq(service.get_active_rifle_effect_count(), 0)
	assert_false(effect.visible)
	var second := _snapshot(Vector2(320, 180), Vector2(510, 260))
	service.request_rifle_shot(second)
	assert_same(_rifles_below(service)[0], effect, "Reutiliza el mismo efecto sin instantiate/free por tiro")
	assert_ne(effect.get_activation_id(), first_id)
	assert_eq(effect.get_shot_snapshot(), second)
	assert_eq(effect.rotation, 0.0)
	assert_eq(effect.scale, Vector2.ONE)
	assert_eq(effect.modulate, Color.WHITE)
	assert_eq(effect.self_modulate, Color.WHITE)
	effect.complete_activation(first_id)
	assert_eq(service.get_active_rifle_effect_count(), 1)
	assert_true(effect.visible, "Callback obsoleto no oculta el nuevo uso")
	assert_signal_emit_count(effect, "finished", 1)
	await wait_seconds(0.20)
	assert_eq(service.get_active_rifle_effect_count(), 0)
	assert_signal_emit_count(effect, "finished", 2)


func test_release_is_safe_before_ready_and_invalidates_old_activation() -> void:
	var effect := EffectScene.instantiate() as RifleShotVisualEffect
	effect.on_pool_released() # ObjectPool lo hace durante prewarm.
	assert_false(effect.visible)
	_world.add_child(effect)
	effect.on_pool_acquired()
	effect.play_snapshot(_snapshot())
	var old_id := effect.get_activation_id()
	effect.on_pool_released()
	assert_false(effect.visible)
	assert_true(effect.get_shot_snapshot().is_empty())
	effect.on_pool_acquired()
	effect.play_snapshot(_snapshot(Vector2(600, 140), Vector2(720, 240)))
	effect.complete_activation(old_id)
	assert_true(effect.visible)
	assert_eq(effect.get_shot_snapshot().get("target_world"), Vector2(720, 240))


func test_simultaneous_shots_preserve_distinct_models_and_finish_independently() -> void:
	var service := _service(1)
	var first := _snapshot()
	var second := _snapshot(Vector2(194, 397), Vector2(300, 432))
	service.request_rifle_shot(first)
	service.request_rifle_shot(second)
	assert_eq(service.get_active_rifle_effect_count(), 2, "Crece sin sobrescribir otro disparo activo")
	var effects := _active(service)
	assert_eq(effects.size(), 2)
	if effects.size() != 2:
		return
	var models: Array[Dictionary] = []
	for effect: RifleShotVisualEffect in effects:
		models.append(effect.get_shot_snapshot())
	assert_has(models, first)
	assert_has(models, second)
	var survivor := effects[1].get_shot_snapshot()
	effects[0].complete_activation(effects[0].get_activation_id())
	assert_eq(service.get_active_rifle_effect_count(), 1)
	assert_eq(effects[1].get_shot_snapshot(), survivor)
	assert_true(effects[1].visible)


func test_paused_state_freezes_remaining_life_and_playing_resumes_it() -> void:
	var service := _service()
	service.request_rifle_shot(_snapshot())
	var effects := _active(service)
	assert_eq(effects.size(), 1)
	if effects.size() != 1:
		return
	var effect := effects[0]
	effect.set_process(false)
	effect._process(0.04)
	_state(GameStateManager.GameState.PAUSED)
	effect._process(0.24)
	assert_eq(service.get_active_rifle_effect_count(), 1, "Tiempo pausado no consume la vida del flash")
	assert_eq(_active(service).size(), 1)
	service.request_rifle_shot(_snapshot())
	assert_eq(service.get_active_rifle_effect_count(), 1, "No acepta tiros nuevos en pausa")
	_state(GameStateManager.GameState.PLAYING)
	effect._process(0.04)
	assert_eq(service.get_active_rifle_effect_count(), 1, "Reanuda con el tiempo restante")
	effect._process(0.16)
	assert_eq(service.get_active_rifle_effect_count(), 0)


func test_tree_pause_freezes_effect_and_resumes_without_an_extra_completion() -> void:
	var service := _service()
	service.request_rifle_shot(_snapshot())
	get_tree().paused = true
	await get_tree().create_timer(0.24, true).timeout
	assert_eq(service.get_active_rifle_effect_count(), 1)
	get_tree().paused = false
	await get_tree().create_timer(0.20, true).timeout
	assert_eq(service.get_active_rifle_effect_count(), 0)
	assert_eq(service.get_available_rifle_effect_count(), 1)


func test_terminal_state_rejects_new_requests_but_confirmed_shot_finishes(
		outcome = use_parameters(["won", "lost"])) -> void:
	var service := _service()
	service.request_rifle_shot(_snapshot())
	if outcome == "won":
		WaveManager.all_waves_completed.emit()
	else:
		GameStateManager.report_reached_defended_position()
	var expected := GameStateManager.GameState.WON if outcome == "won" else GameStateManager.GameState.LOST
	assert_eq(GameStateManager._current_state, expected, "Control: transición terminal del manager real")
	assert_eq(service.get_active_rifle_effect_count(), 1, "El resultado conserva el tiro ya confirmado")
	service.request_rifle_shot(_snapshot(Vector2(400, 240), Vector2(500, 240)))
	assert_eq(service.get_active_rifle_effect_count(), 1, "Terminal no acepta otra activación")
	await wait_seconds(0.20)
	assert_eq(service.get_active_rifle_effect_count(), 0)
	assert_eq(service.get_available_rifle_effect_count(), 1)
	assert_eq(GameStateManager._current_state, expected, "El fade no gobierna la condición de victoria/derrota")


func test_close_or_menu_cleans_synchronously_and_never_reopens_old_service(
		destination = use_parameters(["close", "menu"])) -> void:
	var service := _service()
	var actor := RifleOnlyActor.new()
	_world.add_child(actor)
	service.register_actor(actor)
	service.request_rifle_shot(_snapshot())
	assert_eq(service.get_active_rifle_effect_count(), 1)
	var old_effects := _active(service)
	_state(GameStateManager.GameState.PAUSED)
	if destination == "menu":
		GameStateManager.enter_menu()
	else:
		service.close_match()
	service.close_match()
	assert_eq(service.get_active_rifle_effect_count(), 0, "Cierre inmediato incluso durante pausa")
	for effect: RifleShotVisualEffect in old_effects:
		assert_false(effect.visible)
		assert_true(effect.get_shot_snapshot().is_empty())
	GameStateManager.start_new_match()
	service.register_actor(actor)
	actor.rifle_shot_visual_requested.emit(_snapshot())
	service.request_rifle_shot(_snapshot())
	assert_eq(service.get_active_rifle_effect_count(), 0, "PLAYING de otro intento no resucita este servicio")
