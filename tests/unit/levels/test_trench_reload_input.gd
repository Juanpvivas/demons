extends GutTest
## 012/T003: GUI real, autoridad por hogar, identidad y ciclo de intento.
const LEVEL_SCENE := preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
const PICKUP_SCENE := preload("res://scenes/levels/AmmoPickup.tscn")
const ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const RETRY_LEVEL := preload("res://tests/unit/game/fixtures/OneWaveLevel.tscn")
const HOME := Vector2i(1, 1)
var _viewport: SubViewport
var _level: Node
var _saved_state: int
var _saved_ammo: int
var _saved_waves: Dictionary


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	_saved_ammo = EconomyManager.collected_ammo
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_waves[key] = WaveManager.get(key)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.world_2d = World2D.new()
	_viewport.handle_input_locally = true
	_viewport.physics_object_picking = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(_viewport)
	_level = LEVEL_SCENE.instantiate()
	_viewport.add_child(_level)
	_isolate(_level)
	EconomyManager.collected_ammo = 100


func after_each() -> void:
	if is_instance_valid(_level):
		_level.close_match()
	WaveManager.cancel_waves()
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _isolate(level: Node) -> void:
	level.get("_wave_spawner").process_mode = Node.PROCESS_MODE_DISABLED
	for home: Vector2i in level.board_config.home_cells:
		var owner := _owner(home, level)
		if owner != null:
			owner.stats = owner.stats.duplicate()
			owner.set_physics_process(false)


func _owner(home := HOME, level: Node = null) -> Soldado:
	var target := level if level != null else _level
	return (target.get("_board_manager") as BoardManager).get_occupant(home) as Soldado


func _empty(owner: Soldado, outside := false) -> void:
	owner.set("_current_ammo", 0)
	owner.set("_mode", Soldado.SoldierMode.MELEE)
	if outside:
		owner.position.x += 120.0
	owner.reload_state_changed.emit()


func _button(home := HOME) -> Button:
	var button: Button = _level.get_node("HUD").get_trench_reload_button(home)
	assert_not_null(button, "012: botón del hogar debe aparecer sin selección " + str(home))
	return button


func _press(screen: Vector2, kind := 0) -> void:
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
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION if kind > 0 else 0
	event.position = screen
	event.global_position = screen
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	_viewport.push_input(event, true)


func _release(screen: Vector2, kind := 0) -> void:
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION if kind > 0 else 0
	event.position = screen
	event.global_position = screen
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	_viewport.push_input(event, true)
	if kind == 2:
		var touch := InputEventScreenTouch.new()
		touch.position = screen
		touch.pressed = false
		_viewport.push_input(touch, true)


func _gesture(screen: Vector2, kind := 0) -> void:
	_press(screen, kind)
	await wait_physics_frames(2)
	_release(screen, kind)
	await wait_physics_frames(3)


func _pickup_under(screen: Vector2) -> AmmoPickup:
	var pickup := PICKUP_SCENE.instantiate() as AmmoPickup
	pickup.position = _viewport.canvas_transform.affine_inverse() * screen
	pickup.amount = 3
	_level.add_child(pickup)
	return pickup


func test_pickup_dispatch_positive_control_outside_reload_ui() -> void:
	await wait_physics_frames(2)
	var point := _viewport.canvas_transform * Vector2(900, 300)
	var pickup := _pickup_under(point)
	await wait_physics_frames(3)
	await _gesture(point, 1)
	assert_false(is_instance_valid(pickup), "CONTROL: picking real recoge fuera de GUI")
	assert_eq(EconomyManager.collected_ammo, 103)


func test_direct_request_without_selection_preserves_actor_and_physical_return() -> void:
	var owner := _owner()
	_empty(owner, true)
	owner.set("_current_morale", 4.0)
	owner.take_damage(3)
	var before := owner.get_reload_state()
	var start := owner.position
	assert_null(_level.get_selected_soldier())
	assert_true(_level.request_trench_reload(HOME, owner.get_instance_id()), "Nueva orden no exige seleccionar")
	assert_eq(EconomyManager.collected_ammo, 100 - owner.stats.deploy_ammo_cost)
	assert_eq(owner.get_reload_state().ammo, owner.stats.max_ammo)
	assert_eq(owner.get_reload_state().health, before.health)
	assert_eq(owner.get_reload_state().morale, before.morale)
	assert_same(_owner(), owner)
	assert_eq(owner.position, start, "Aceptar no teletransporta")
	assert_eq(owner.get_movement_state(), Soldado.MovementState.RETURNING)
	owner.set_physics_process(true)
	await wait_physics_frames(15)
	assert_lt(owner.position.x, start.x, "Mismo cuerpo vuelve físicamente")
	assert_eq(owner.position.y, start.y)
	assert_false(_level.request_trench_reload(HOME, owner.get_instance_id()))
	assert_eq(EconomyManager.collected_ammo, 100 - owner.stats.deploy_ammo_cost)


func test_gui_reload_targets_home_owner_independently_of_selection_and_consumes_gesture(
		scenario = use_parameters([[0, false], [1, false], [2, false], [0, true]])) -> void:
	var owner := _owner()
	var other := _owner(Vector2i(1, 2))
	_empty(owner)
	_empty(other)
	if scenario[1]:
		_level.select_trench(Vector2i(1, 2))
	var selection: Soldado = _level.get_selected_soldier()
	var button := _button()
	if button == null:
		return
	await wait_process_frames(2)
	var point := button.get_global_rect().get_center()
	var pickup := _pickup_under(point)
	await wait_physics_frames(3)
	watch_signals(EconomyManager)
	watch_signals(_level.get_node("HUD"))
	await _gesture(point, scenario[0])
	assert_signal_emit_count(_level.get_node("HUD"), "trench_reload_requested", 1)
	assert_signal_emit_count(EconomyManager, "ammo_pool_changed", 1)
	assert_eq(EconomyManager.collected_ammo, 100 - owner.stats.deploy_ammo_cost)
	assert_eq(owner.get_reload_state().ammo, owner.stats.max_ammo)
	assert_eq(other.get_reload_state().ammo, 0)
	assert_same(_level.get_selected_soldier(), selection, "GUI no selecciona el tablero")
	assert_same(_owner(), owner)
	assert_true(is_instance_valid(pickup), "UI prevalece sobre pickup debajo")
	assert_true(not is_instance_valid(button) or not button.is_visible_in_tree(), "Recarga oculta sin espera añadida")


func test_disabled_reload_consumes_click_and_touch_without_pickup_or_selection(
		kind = use_parameters([0, 2])) -> void:
	var owner := _owner()
	_empty(owner)
	EconomyManager.collected_ammo = 0
	EconomyManager.ammo_pool_changed.emit(0)
	var button := _button()
	if button == null:
		return
	assert_true(button.disabled)
	await wait_process_frames(2)
	var point := button.get_global_rect().get_center()
	var pickup := _pickup_under(point)
	await wait_physics_frames(3)
	await _gesture(point, kind)
	assert_true(is_instance_valid(pickup))
	assert_eq(EconomyManager.collected_ammo, 0)
	assert_eq(owner.get_reload_state().ammo, 0)
	assert_null(_level.get_selected_soldier())
	assert_same(_owner(), owner)


func test_two_home_orders_are_independent_and_only_remaining_balance_disables_others() -> void:
	var owners: Array[Soldado] = []
	for home: Vector2i in _level.board_config.home_cells:
		var owner := _owner(home)
		_empty(owner)
		owners.append(owner)
		if _button(home) == null:
			return
	EconomyManager.collected_ammo = owners[0].stats.deploy_ammo_cost * 2
	EconomyManager.ammo_pool_changed.emit(EconomyManager.collected_ammo)
	assert_true(_level.request_trench_reload(HOME, owners[0].get_instance_id()))
	assert_true(_level.request_trench_reload(Vector2i(1, 2), owners[1].get_instance_id()))
	assert_eq(EconomyManager.collected_ammo, 0)
	for index in range(2, 5):
		var button := _button(Vector2i(1, index + 1))
		assert_true(button.is_visible_in_tree())
		assert_true(button.disabled, "Otros dueños siguen vacíos; solo cambia elegibilidad económica")
		assert_eq(owners[index].get_reload_state().ammo, 0)


func test_synchronous_spend_callback_cannot_reenter_direct_order() -> void:
	var owner := _owner()
	_empty(owner, true)
	var nested: Array[bool] = []
	var listener := func(_amount: int) -> void:
		nested.append(_level.request_trench_reload(HOME, owner.get_instance_id()))
	EconomyManager.ammo_pool_changed.connect(listener)
	var accepted: bool = _level.request_trench_reload(HOME, owner.get_instance_id())
	EconomyManager.ammo_pool_changed.disconnect(listener)
	assert_true(accepted)
	assert_eq(nested, [false], "Actor ya bloqueado antes del callback económico")
	assert_eq(EconomyManager.collected_ammo, 100 - owner.stats.deploy_ammo_cost)


func test_invalid_home_wrong_identity_and_nonplaying_are_rejected_without_mutation(
		scenario = use_parameters(["invalid_home", "identity", "actor_home", "paused", "won", "lost", "returning", "funds"])) -> void:
	var owner := _owner()
	_empty(owner)
	var home := HOME
	var identity := owner.get_instance_id()
	match scenario:
		"invalid_home": home = Vector2i(4, 4)
		"identity": identity += 99999
		"actor_home": owner.set_grid_cell(Vector2i(1, 2))
		"paused": GameStateManager._current_state = GameStateManager.GameState.PAUSED
		"won": GameStateManager._current_state = GameStateManager.GameState.WON
		"lost": GameStateManager._current_state = GameStateManager.GameState.LOST
		"returning": owner.set("_movement_state", Soldado.MovementState.RETURNING)
		"funds": EconomyManager.collected_ammo = 0
	var balance := EconomyManager.collected_ammo
	var before := owner.get_reload_state()
	assert_false(_level.request_trench_reload(home, identity))
	assert_eq(EconomyManager.collected_ammo, balance)
	assert_eq(owner.get_reload_state(), before)


func test_old_identity_after_death_or_replacement_does_not_target_successor() -> void:
	var owner := _owner()
	_empty(owner)
	var identity := owner.get_instance_id()
	owner.take_damage(owner.stats.max_health)
	assert_false(_level.request_trench_reload(HOME, identity))
	_level.call("_try_deploy_soldado", HOME)
	var replacement := _owner()
	assert_not_null(replacement, "CONTROL: el despliegue vigente creó un sucesor real")
	if replacement == null:
		return
	_empty(replacement)
	var before := EconomyManager.collected_ammo
	assert_false(_level.request_trench_reload(HOME, identity))
	assert_eq(replacement.get_reload_state().ammo, 0)
	assert_eq(EconomyManager.collected_ammo, before)


func test_press_owner_a_then_death_replacement_b_then_release_never_reloads_b() -> void:
	var owner := _owner()
	_empty(owner)
	var button := _button()
	if button == null:
		return
	await wait_process_frames(2)
	var point := button.get_global_rect().get_center()
	_press(point)
	await wait_process_frames(1)
	owner.take_damage(owner.stats.max_health)
	_level.call("_try_deploy_soldado", HOME)
	var replacement := _owner()
	assert_not_null(replacement)
	if replacement == null:
		return
	_empty(replacement)
	var balance := EconomyManager.collected_ammo
	await wait_process_frames(2)
	_release(point)
	await wait_physics_frames(3)
	assert_eq(replacement.get_reload_state().ammo, 0, "Release del dueño A no es orden de B")
	assert_eq(EconomyManager.collected_ammo, balance)


func test_home_controls_follow_applied_canvas_after_each_resize_not_the_actor() -> void:
	for home: Vector2i in _level.board_config.home_cells:
		_empty(_owner(home), true)
	for size: Vector2i in [Vector2i(960, 540), Vector2i(1440, 648), Vector2i(1152, 864), Vector2i(1152, 648)]:
		_viewport.size = size
		await wait_process_frames(3)
		var rects: Array[Rect2] = []
		for home: Vector2i in _level.board_config.home_cells:
			var owner := _owner(home)
			var button := _button(home)
			if button == null:
				return
			var rect := button.get_global_rect()
			assert_true(Rect2(Vector2.ZERO, Vector2(size)).encloses(rect), "Acción dentro de viewport " + str(size))
			assert_gte(rect.size.x, 112.0)
			assert_gte(rect.size.y, 48.0)
			var projected_home := _viewport.canvas_transform * owner.get_home_position()
			assert_true(rect.position.x <= projected_home.x and projected_home.x <= rect.end.x,
				"Anclada sobre hogar proyectado; admite ajuste al borde seguro")
			assert_lte(rect.end.y, projected_home.y, "Encima del hogar; no sigue al actor lejano")
			assert_gte(rect.end.y, projected_home.y - 96.0, "No se desplaza a otra fila")
			for previous: Rect2 in rects:
				assert_false(previous.intersects(rect), "Hogares vecinos no comparten área de gesto")
			rects.append(rect)
			assert_false(rect.intersects((_level.get_node("HUD").get("_ammo_label") as Label).get_global_rect()))


func test_close_invalidates_direct_orders_and_previous_button_callbacks() -> void:
	var owner := _owner()
	_empty(owner)
	var identity := owner.get_instance_id()
	var button := _button()
	if button == null:
		return
	var callbacks := button.pressed.get_connections()
	_level.close_match()
	for connection: Dictionary in callbacks:
		var callback: Callable = connection.callable
		if callback.is_valid():
			callback.call() # Callback antiguo; no se presenta como dispatch GUI.
	assert_false(_level.request_trench_reload(HOME, identity))
	assert_eq(EconomyManager.collected_ammo, 100)
	assert_eq(owner.get_reload_state().ammo, 0)
	assert_true(not is_instance_valid(button) or not button.is_visible_in_tree())


## Cobertura suplementaria en GREEN; no forma parte del RED histórico de T003.
func test_visible_wave_and_rejection_information_stays_inside_without_covering_home_controls() -> void:
	for home: Vector2i in _level.board_config.home_cells:
		_empty(_owner(home))
	var hud := _level.get_node("HUD")
	for size: Vector2i in [Vector2i(960, 540), Vector2i(1440, 648), Vector2i(1152, 864), Vector2i(1152, 648)]:
		_viewport.size = size
		WaveManager.wave_started.emit(9)
		EconomyManager.deploy_or_reload_rejected.emit("Munición insuficiente")
		await wait_process_frames(3)
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		var labels: Array[Label] = [hud.get("_ammo_label"), hud.get("_rejection_label"), hud.get("_wave_label")]
		for label: Label in labels:
			assert_true(label.is_visible_in_tree(), "CONTROL: aviso/contador realmente visible")
			assert_true(bounds.encloses(label.get_global_rect()), "Información dentro de viewport " + str(size))
			for home: Vector2i in _level.board_config.home_cells:
				var button := _button(home)
				if button == null:
					return
				assert_true(bounds.encloses(button.get_global_rect()))
				assert_false(label.get_global_rect().intersects(button.get_global_rect()),
					"Avisos visibles no tapan controles de hogar " + str(size))


## Suplementaria: distingue queue_free pendiente de controles filtrados por cierre.
func test_supplemental_all_home_controls_are_freed_after_close_or_tree_teardown(
		mode = use_parameters(["explicit_close", "tree_teardown"])) -> void:
	var controls: Array[WeakRef] = []
	for home: Vector2i in _level.board_config.home_cells:
		var button := _button(home)
		if button == null:
			return
		controls.append(weakref(button))
	if mode == "explicit_close":
		_level.close_match()
	else:
		_level.queue_free()
	await wait_process_frames(3)
	for reference: WeakRef in controls:
		assert_null(reference.get_ref(), "Cero controles del intento después del flush de borrado")


func test_retry_or_menu_releases_old_controls_and_new_attempt_has_fresh_bindings(
		destination = use_parameters(["retry", "menu"])) -> void:
	_level.close_match()
	_level.queue_free()
	await wait_process_frames(2)
	var app := ROOT_SCENE.instantiate()
	app.level_scene = RETRY_LEVEL
	_viewport.add_child(app)
	app.request_start()
	for frame in 12:
		await wait_process_frames(1)
		if app.get_current_level() != null:
			break
	_level = app.get_current_level()
	assert_not_null(_level, "CONTROL: raíz montó el intento reducido real")
	if _level == null:
		return
	_isolate(_level)
	var owner := _owner()
	_empty(owner)
	var button := _button()
	if button == null:
		return
	var old_button: WeakRef = weakref(button)
	var old_order := Callable(_level, "request_trench_reload").bind(HOME, owner.get_instance_id())
	GameStateManager.report_reached_defended_position()
	if destination == "retry":
		app.request_retry()
	else:
		app.request_menu()
	assert_false(old_order.call(), "El cierre invalida orden antes de retirar el árbol")
	for frame in 15:
		await wait_process_frames(1)
		if old_button.get_ref() == null:
			break
	assert_null(old_button.get_ref())
	assert_false(old_order.is_valid(), "No sobrevive callable hacia intento retirado")
	if destination == "menu":
		assert_null(app.get_current_level())
		app.request_start()
	for frame in 15:
		await wait_process_frames(1)
		if app.get_current_level() != null:
			break
	_level = app.get_current_level()
	assert_not_null(_level)
	if _level == null:
		return
	_isolate(_level)
	var fresh := _owner()
	assert_eq(fresh.get_reload_state().ammo, fresh.stats.max_ammo)
	_empty(fresh)
	var fresh_button := _button()
	if fresh_button != null:
		assert_true(fresh_button.is_visible_in_tree())
		assert_eq(fresh_button.disabled, EconomyManager.collected_ammo < fresh.stats.deploy_ammo_cost)
