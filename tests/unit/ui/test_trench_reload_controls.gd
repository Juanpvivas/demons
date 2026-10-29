extends GutTest
## 012/T003 y T014: contrato GUI real; nueva presentación sobre la propia trinchera.
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const SOLDIER_SCENE := preload("res://scenes/units/Soldado.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/EnemigoBase.tscn")
var _viewport: SubViewport
var _hud: Node
var _saved_state: int
var _saved_ammo: int


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	_saved_ammo = EconomyManager.collected_ammo
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	EconomyManager.collected_ammo = 100
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.world_2d = World2D.new()
	_viewport.handle_input_locally = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(_viewport)
	_hud = HUD_SCENE.instantiate()
	_viewport.add_child(_hud)


func after_each() -> void:
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo


func _home(row: int) -> Vector2i:
	return Vector2i(1, row)


func _anchor(row: int) -> Vector2:
	return Vector2(144, 48 + row * 96)


func _owner(row: int, ammo := 0) -> Soldado:
	var owner := SOLDIER_SCENE.instantiate() as Soldado
	owner.stats = owner.stats.duplicate()
	owner.position = _anchor(row)
	owner.set_grid_cell(_home(row))
	_viewport.add_child(owner)
	owner.set_physics_process(false)
	owner.set("_current_ammo", ammo)
	owner.set("_mode", Soldado.SoldierMode.MELEE if ammo == 0 else Soldado.SoldierMode.RIFLE)
	return owner


func _button(home: Vector2i) -> Button:
	var button: Button = _hud.get_trench_reload_button(home)
	assert_not_null(button, "012: existe un Button real registrado para " + str(home))
	return button


func _state(state: int) -> void:
	GameStateManager._current_state = state
	GameStateManager.game_state_changed.emit(state)


func _funds(amount: int) -> void:
	EconomyManager.collected_ammo = amount
	EconomyManager.ammo_pool_changed.emit(amount)


func _gesture(screen: Vector2, kind: int) -> void:
	_viewport.notify_mouse_entered()
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	_viewport.push_input(motion, true)
	if kind == 2:
		var touch := InputEventScreenTouch.new()
		touch.position = screen
		touch.pressed = true
		_viewport.push_input(touch, true)
	var press := InputEventMouseButton.new()
	press.device = InputEvent.DEVICE_ID_EMULATION if kind > 0 else 0
	press.position = screen
	press.global_position = screen
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	_viewport.push_input(press, true)
	await wait_process_frames(2)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	release.button_mask = 0
	_viewport.push_input(release, true)
	if kind == 2:
		var touch := InputEventScreenTouch.new()
		touch.position = screen
		touch.pressed = false
		_viewport.push_input(touch, true)
	await wait_process_frames(2)


func test_gui_harness_reaches_a_real_button_once(kind = use_parameters([0, 1, 2])) -> void:
	var control := Button.new()
	control.position = Vector2(700, 200)
	control.size = Vector2(112, 48)
	control.text = "Control de dispatch"
	_viewport.add_child(control)
	await wait_process_frames(2)
	watch_signals(control)
	await _gesture(control.get_global_rect().get_center(), kind)
	assert_signal_emit_count(control, "pressed", 1,
		"CONTROL positivo: Viewport entrega un gesto real; no handlers invocados a mano")


func test_last_confirmed_shot_shows_home_control_without_selection() -> void:
	var owner := _owner(1, 1)
	_hud.register_trench_reload(_home(1), owner, _anchor(1))
	var initial: Button = _hud.get_trench_reload_button(_home(1))
	assert_true(initial == null or not initial.is_visible_in_tree(), "Carga positiva no muestra acción")
	var enemy := ENEMY_SCENE.instantiate() as Enemigo
	enemy.position = _anchor(1) + Vector2(240, 0)
	_viewport.add_child(enemy)
	enemy.set_physics_process(false)
	owner.set("_current_target", enemy)
	owner.call("_fire_at_current_target")
	assert_eq(owner.get_reload_state().ammo, 0, "CONTROL: el último disparo real agotó la carga")
	assert_null(_hud.get_selected_soldier())
	var button := _button(_home(1))
	if button == null:
		return
	assert_true(button.is_visible_in_tree())
	assert_false(button.disabled)
	assert_eq(button.text, "", "T014: la acción no pinta el antiguo rótulo")
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		assert_true(button.get_theme_stylebox(state) is StyleBoxEmpty,
			"T014: sin fondo/borde incluso en " + state)
	await wait_process_frames(2)
	assert_gte(button.size.x, 112.0)
	assert_gte(button.size.y, 48.0)


func test_five_empty_owners_have_independent_idempotent_controls() -> void:
	var controls: Array[Button] = []
	for row in range(1, 6):
		var owner := _owner(row)
		_hud.register_trench_reload(_home(row), owner, _anchor(row))
		var button := _button(_home(row))
		if button == null:
			return
		assert_true(button.is_visible_in_tree())
		assert_false(controls.has(button), "Cada hogar tiene un control individual")
		controls.append(button)
		_hud.register_trench_reload(_home(row), owner, _anchor(row))
		assert_same(_hud.get_trench_reload_button(_home(row)), button,
			"Registrar de nuevo no duplica ni sustituye el control de ese dueño")
	var buttons := _hud.find_children("*", "Button", true, false).filter(
		func(node: Node) -> bool: return node.name.begins_with("ReloadHome"))
	assert_eq(buttons.size(), 5, "Cinco zonas individuales y ningún control antiguo adicional")
	for button: Button in buttons:
		assert_eq(button.text, "", "T014: ninguno de los hogares tiene cartel")


func test_no_funds_is_visible_disabled_and_funding_refreshes_without_selection() -> void:
	_funds(0)
	var owner := _owner(3)
	_hud.register_trench_reload(_home(3), owner, _anchor(3))
	var button := _button(_home(3))
	if button == null:
		return
	assert_true(button.is_visible_in_tree())
	assert_true(button.disabled)
	_funds(owner.stats.deploy_ammo_cost)
	assert_false(button.disabled, "La señal económica habilita sin seleccionar")
	assert_null(_hud.get_selected_soldier())


func test_nonplaying_or_zero_ammo_returning_keeps_action_disabled(
		scenario = use_parameters(["paused", "won", "lost", "returning"])) -> void:
	var owner := _owner(2)
	_hud.register_trench_reload(_home(2), owner, _anchor(2))
	var button := _button(_home(2))
	if button == null:
		return
	if scenario == "returning":
		owner.set("_movement_state", Soldado.MovementState.RETURNING)
		owner.reload_state_changed.emit()
	else:
		_state({"paused": GameStateManager.GameState.PAUSED,
			"won": GameStateManager.GameState.WON, "lost": GameStateManager.GameState.LOST}[scenario])
	assert_true(button.is_visible_in_tree(), "Vivo/carga cero sigue visible")
	assert_true(button.disabled)
	watch_signals(_hud)
	await _gesture(button.get_global_rect().get_center(), 2)
	assert_signal_not_emitted(_hud, "trench_reload_requested")
	assert_eq(EconomyManager.collected_ammo, 100)
	if scenario == "paused":
		_state(GameStateManager.GameState.PLAYING)
		assert_false(button.disabled, "Reanudar restaura elegibilidad sin seleccionar")


func test_refill_death_unregister_and_close_remove_usable_action(
		scenario = use_parameters(["refill", "death", "unregister", "close"])) -> void:
	var owner := _owner(4)
	_hud.register_trench_reload(_home(4), owner, _anchor(4))
	var button := _button(_home(4))
	if button == null:
		return
	match scenario:
		"refill":
			assert_true(owner.request_reload(), "CONTROL: la transacción vigente acepta")
		"death":
			owner.take_damage(owner.stats.max_health)
		"unregister":
			_hud.unregister_trench_reload(_home(4))
		"close":
			_hud.close_match()
	var current: Button = _hud.get_trench_reload_button(_home(4))
	assert_true(current == null or not current.is_visible_in_tree(), "Acción retirada inmediatamente")
	watch_signals(_hud)
	if is_instance_valid(button):
		button.pressed.emit() # Callback retirado, no acredita input GUI.
	assert_signal_not_emitted(_hud, "trench_reload_requested")


func test_control_emits_captured_home_and_owner_once_without_charging(
		kind = use_parameters([0, 1, 2])) -> void:
	var owner := _owner(5)
	_hud.register_trench_reload(_home(5), owner, _anchor(5))
	var button := _button(_home(5))
	if button == null:
		return
	await wait_process_frames(2)
	watch_signals(_hud)
	await _gesture(button.get_global_rect().get_center(), kind)
	assert_signal_emit_count(_hud, "trench_reload_requested", 1)
	assert_signal_emitted_with_parameters(_hud, "trench_reload_requested", [_home(5), owner.get_instance_id()])
	assert_eq(EconomyManager.collected_ammo, 100, "HUD expresa intención; el nivel/actor cobra")
	assert_eq(owner.get_reload_state().ammo, 0)


func test_moving_actor_does_not_move_home_control_or_mutate_health_and_morale() -> void:
	var owner := _owner(3)
	owner.set("_current_morale", 7.0)
	owner.take_damage(3)
	_hud.register_trench_reload(_home(3), owner, _anchor(3))
	var button := _button(_home(3))
	if button == null:
		return
	await wait_process_frames(2)
	var rect := button.get_global_rect()
	assert_false(rect.intersects((owner.get_node("HealthBar") as Control).get_global_rect()),
		"Acción del hogar no tapa la barra de vida del dueño en HOME")
	assert_false(rect.intersects((_hud.get("_ammo_label") as Label).get_global_rect()))
	var snapshot := owner.get_reload_state()
	owner.position += Vector2(180, 0)
	owner.reload_state_changed.emit()
	await wait_process_frames(2)
	assert_eq(button.get_global_rect(), rect, "La acción sigue al hogar, no al cuerpo")
	assert_eq(owner.get_reload_state().health, snapshot.health)
	assert_eq(owner.get_reload_state().morale, snapshot.morale)
