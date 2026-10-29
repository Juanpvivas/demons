extends GutTest
## 005/T035: origen/identidad e input por dispatch del Viewport; sin handlers directos.
const LevelScene := preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
const PickupScene := preload("res://scenes/levels/AmmoPickup.tscn")
const HOME := Vector2i(1, 1)
var _viewport: SubViewport
var _level: Node2D
var _board: BoardManager
var _owner: Soldado
var _saved_ammo: int
var _saved_state: int
var _saved_waves: Dictionary


func before_each() -> void:
	_saved_ammo = EconomyManager.collected_ammo
	_saved_state = GameStateManager._current_state
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_waves[key] = WaveManager.get(key)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.world_2d = World2D.new()
	_viewport.physics_object_picking = true
	_viewport.handle_input_locally = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(_viewport)
	_level = LevelScene.instantiate()
	_viewport.add_child(_level)
	_level.get("_wave_spawner").process_mode = Node.PROCESS_MODE_DISABLED
	_board = _level.get("_board_manager")
	_owner = _board.get_occupant(HOME) as Soldado
	EconomyManager.collected_ammo = 100


func after_each() -> void:
	EconomyManager.collected_ammo = _saved_ammo
	GameStateManager._current_state = _saved_state
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _empty_owner() -> void:
	_owner.set("_current_ammo", 0)
	_owner.set("_mode", Soldado.SoldierMode.MELEE)
	_owner.position.x += 120.0
	_owner.reload_state_changed.emit() # 012: notifica el estado que este fixture altera.


func _gesture(world: Vector2, kind: int) -> void:
	# Native touch plus its emulated mouse is one physical gesture.
	var screen := _viewport.canvas_transform * world
	_viewport.notify_mouse_entered()
	if kind == 2:
		var touch := InputEventScreenTouch.new()
		touch.position = screen
		touch.pressed = true
		_viewport.push_input(touch, true)
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	_viewport.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.device = InputEvent.DEVICE_ID_EMULATION if kind > 0 else 0
	click.position = screen
	click.global_position = screen
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	_viewport.push_input(click, true)
	await wait_physics_frames(3)
	click = click.duplicate()
	click.pressed = false
	click.button_mask = 0
	_viewport.push_input(click, true)
	if kind == 2:
		var touch := InputEventScreenTouch.new()
		touch.position = screen
		touch.pressed = false
		_viewport.push_input(touch, true)
	await wait_physics_frames(2)


func _pickup(where: Vector2) -> AmmoPickup:
	var pickup := PickupScene.instantiate() as AmmoPickup
	pickup.amount = 3
	pickup.position = where
	_level.add_child(pickup)
	return pickup


func test_occupied_origin_selects_same_owner_outside_without_cost(
		kind = use_parameters([0, 1, 2])) -> void:
	_empty_owner()
	await wait_physics_frames(3)
	await _gesture(Vector2(144, 144), kind)
	assert_same(_level.get_selected_soldier(), _owner, "Plaza reservada selecciona su dueño lejano")
	assert_eq(EconomyManager.collected_ammo, 100, "Seleccionar no es despliegue ni recarga")
	assert_same(_board.get_occupant(HOME), _owner)


func test_captured_reload_identity_does_not_target_replacement_and_death_frees_origin() -> void:
	_empty_owner()
	assert_true(_level.select_trench(HOME))
	var old_id := _owner.get_instance_id()
	_owner.take_damage(9999)
	assert_true(_board.is_cell_free(HOME), "Libera inmediatamente sin esperar efecto")
	assert_null(_level.get_selected_soldier(), "Muerte invalida selección")
	await wait_physics_frames(2)
	await _gesture(Vector2(144, 144), 0)
	var replacement := _board.get_occupant(HOME) as Soldado
	assert_not_null(replacement, "El gesto despliega reemplazo")
	if replacement == null:
		return
	replacement.set("_current_ammo", 0)
	replacement.set("_mode", Soldado.SoldierMode.MELEE)
	assert_true(_level.select_trench(HOME))
	var before := EconomyManager.collected_ammo
	assert_false(_level.request_selected_reload(old_id), "Intención antigua no se redirige al nuevo dueño")
	assert_eq(EconomyManager.collected_ammo, before)
	assert_eq(replacement.get_reload_state().ammo, 0)
	assert_true(_level.request_selected_reload(replacement.get_instance_id()), "Nueva intención sí funciona")
	assert_eq(EconomyManager.collected_ammo, before - replacement.stats.deploy_ammo_cost)


func test_death_during_return_frees_remote_home_and_invalidates_order() -> void:
	_empty_owner()
	assert_true(_level.select_trench(HOME))
	var identity := _owner.get_instance_id()
	assert_true(_level.request_selected_reload(identity))
	assert_eq(_owner.get_movement_state(), Soldado.MovementState.RETURNING)
	await wait_physics_frames(8)
	_owner.take_damage(9999)
	assert_true(_board.is_cell_free(HOME))
	assert_null(_level.get_selected_soldier())
	assert_false(_level.request_selected_reload(identity))
	assert_eq(EconomyManager.collected_ammo, 100 - _owner.stats.deploy_ammo_cost)


func test_pickup_precedes_selection_or_deploy_on_free_occupied_and_actor(
		location = use_parameters(["free", "occupied", "actor", "overlap"])) -> void:
	_empty_owner()
	var where := Vector2(144, 144)
	if location == "free":
		_owner.take_damage(9999)
		await wait_physics_frames(2)
	elif location == "actor":
		where = _owner.position
	var first := _pickup(where)
	var second: AmmoPickup = _pickup(where) if location == "overlap" else null
	await wait_physics_frames(3)
	await _gesture(where, 1)
	assert_null(_level.get_selected_soldier(), "Gesto de caja no selecciona ni recarga")
	assert_eq(EconomyManager.collected_ammo, 106 if location == "overlap" else 103, "Picking vigente recoge las cajas solapadas; cero gastos")
	assert_false(is_instance_valid(first) and (second == null or is_instance_valid(second)), "Recogida real mediante picking")
	if location == "free":
		assert_true(_board.is_cell_free(HOME), "Recoger no despliega")
	else:
		assert_same(_board.get_occupant(HOME), _owner)
		assert_eq(_owner.get_reload_state().ammo, 0)


func test_terminal_rejects_selection_and_captured_reload_without_spend() -> void:
	_empty_owner()
	_level.select_trench(HOME)
	GameStateManager.report_reached_defended_position()
	assert_false(_level.select_trench(HOME))
	assert_false(_level.request_selected_reload(_owner.get_instance_id()))
	await _gesture(Vector2(144, 144), 2)
	assert_eq(EconomyManager.collected_ammo, 100)
	assert_eq(_owner.get_reload_state().ammo, 0)


func test_gui_reload_gesture_is_consumed_and_emits_one_order_without_board_action(
		kind = use_parameters([0, 1, 2])) -> void:
	_empty_owner()
	_level.select_trench(HOME)
	var hud: Node
	for node: Node in _level.get_children():
		if node is CanvasLayer and node.has_signal("reload_requested"):
			hud = node
	assert_not_null(hud, "HUD observador integrado")
	if hud == null:
		return
	# 012 sustituye la acción del panel por la del hogar, sin retirar selección.
	var button: Button = hud.get_trench_reload_button(HOME)
	assert_not_null(button, "Control Recargar del hogar integrado para consumir el gesto")
	if button == null:
		return
	await wait_physics_frames(3)
	watch_signals(hud)
	var center := button.get_global_rect().get_center()
	await _gesture(_viewport.canvas_transform.affine_inverse() * center, kind)
	assert_signal_emit_count(hud, "trench_reload_requested", 1, "Toque más mouse emulado no duplica intención")
	assert_eq(EconomyManager.collected_ammo, 100 - _owner.stats.deploy_ammo_cost)
	assert_eq(_owner.get_reload_state().ammo, _owner.stats.max_ammo)
	assert_same(_level.get_selected_soldier(), _owner, "GUI no transmite acción al tablero")
	assert_same(_board.get_occupant(HOME), _owner)
