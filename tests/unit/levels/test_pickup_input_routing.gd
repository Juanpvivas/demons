extends GutTest
## T015 / 003 FR-003 / W02: dispatch real del motor, sin llamar handlers
## de nivel/pickup. SubViewport con coordenadas locales evita el stretch
## del Window headless descrito en los tests historicos T035.
## Los controles sin nivel prueban que physics picking realmente funciona;
## su fallo seria un problema de fixture/entorno, nunca RED del requisito.
## Se cubren mouse normal y mouse marcado DEVICE_ID_EMULATION. push_input
## no emula touch entre si: no sustituye el toque fisico de Chrome Android.
## API oficial4.7: https://docs.godotengine.org/en/4.7/classes/class_viewport.html#class-viewport-method-push-input

const PICKUP_SCENE := preload("res://scenes/levels/AmmoPickup.tscn")
const LEVEL_SCENE := preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
const PICKUP_POSITION := Vector2(144, 240)
const PICKUP_CELL := Vector2i(1, 2)

var _viewport: SubViewport
var _host: Node2D
var _pickup: AmmoPickup
var _pickup_presses: int = 0
var _pool_changes: Array[int] = []
var _saved_ammo: int
var _saved_game_state: int
var _saved_wave_state: Dictionary


func before_each() -> void:
	_saved_ammo = EconomyManager.collected_ammo
	_saved_game_state = GameStateManager.get("_current_state")
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	_saved_wave_state = {}
	for property: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_wave_state[property] = WaveManager.get(property)
	_pickup_presses = 0
	_pool_changes.clear()
	EconomyManager.ammo_pool_changed.connect(_on_pool_changed)


func after_each() -> void:
	EconomyManager.ammo_pool_changed.disconnect(_on_pool_changed)
	EconomyManager.collected_ammo = _saved_ammo
	GameStateManager.set("_current_state", _saved_game_state)
	for property: String in _saved_wave_state:
		WaveManager.set(property, _saved_wave_state[property])


func _fixture(with_level: bool) -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1152, 648)
	_viewport.world_2d = World2D.new()
	_viewport.physics_object_picking = true
	_viewport.handle_input_locally = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(_viewport)
	_host = LEVEL_SCENE.instantiate() if with_level else Node2D.new()
	_viewport.add_child(_host)
	if with_level:
		var board: BoardManager = _host.get("_board_manager")
		var owner := board.get_occupant(PICKUP_CELL) as Soldado
		if owner != null:
			owner.take_damage(owner.stats.max_health)
			await wait_physics_frames(2)
	_pickup = PICKUP_SCENE.instantiate()
	_pickup.amount = 3
	_pickup.position = PICKUP_POSITION
	_pickup.input_event.connect(_on_pickup_input)
	_host.add_child(_pickup)
	EconomyManager.collected_ammo = 12
	await wait_physics_frames(3)
	_pool_changes.clear() # Excluir la notificación de inicio; el gesto aún no ocurrió.


func _press_and_release(device: int) -> void:
	# Estos son eventos enviados al Viewport, no llamadas a los callbacks
	# ni GutInputSender con un nodo receptor (que los llamaria directamente).
	_viewport.notify_mouse_entered()
	var motion := InputEventMouseMotion.new()
	motion.device = device
	motion.position = PICKUP_POSITION
	motion.global_position = PICKUP_POSITION
	_viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.device = device
	press.position = PICKUP_POSITION
	press.global_position = PICKUP_POSITION
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	_viewport.push_input(press, true)
	await wait_physics_frames(3)
	var release := InputEventMouseButton.new()
	release.device = device
	release.position = PICKUP_POSITION
	release.global_position = PICKUP_POSITION
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	_viewport.push_input(release, true)
	await wait_physics_frames(2)


func _on_pickup_input(_source: Node, event: InputEvent, _shape: int) -> void:
	if event.is_action_pressed("collect_pickup"):
		_pickup_presses += 1


func _on_pool_changed(amount: int) -> void:
	_pool_changes.append(amount)


func _soldier_count() -> int:
	var total := 0
	for child: Node in _host.get_children():
		if child is Soldado:
			total += 1
	return total


func _assert_picking_control(device: int) -> void:
	await _fixture(false)
	await _press_and_release(device)
	assert_eq(_pickup_presses, 1, "CONTROL: physics picking debe entregar un pressed al pickup; si falla, no acredita RED de gameplay")
	assert_false(is_instance_valid(_pickup), "CONTROL: el pickup real debe recogerse por el evento del Viewport")
	assert_eq(EconomyManager.collected_ammo, 15, "CONTROL: un pickup amount3 debe sumar una vez a reserva12")
	assert_eq(_pool_changes, [15], "CONTROL: una sola ganancia, sin consumo ni segunda recoleccion")


func _assert_pickup_does_not_deploy(device: int) -> void:
	await _fixture(true)
	var board: BoardManager = _host.get("_board_manager")
	var soldiers_before := _soldier_count()
	assert_true(board.is_cell_free(PICKUP_CELL), "Precondicion: celda del unico pickup libre")
	assert_eq(EconomyManager.collected_ammo, 12, "Precondicion: fondos suficientes para que un despliegue accidental sea observable")
	await _press_and_release(device)
	print("T015_EVENT device=", device, " pickup_presses=", _pickup_presses, " ammo=", EconomyManager.collected_ammo, " changes=", _pool_changes, " soldiers_before=", soldiers_before, " soldiers_after=", _soldier_count(), " cell_free=", board.is_cell_free(PICKUP_CELL))
	assert_false(is_instance_valid(_pickup), "FR-003: el unico pickup debe recogerse mediante dispatch real")
	assert_eq(EconomyManager.collected_ammo, 15, "FR-003: reserva12 + pickup3, sin gasto de10 en el mismo gesto")
	assert_eq(_pool_changes, [15], "FR-003: exactamente una ganancia, sin gasto/despliegue asociado")
	assert_eq(_soldier_count(), soldiers_before, "FR-003: recoger no debe crear un soldado adicional")
	assert_true(board.is_cell_free(PICKUP_CELL), "FR-003: la celda del pickup debe seguir libre")


func test_mouse_control_reaches_real_pickup_through_viewport_physics_picking() -> void:
	await _assert_picking_control(0)


func test_emulated_mouse_control_reaches_real_pickup_through_viewport_physics_picking() -> void:
	await _assert_picking_control(InputEvent.DEVICE_ID_EMULATION)


func test_mouse_pickup_with_enough_ammo_does_not_spend_or_deploy() -> void:
	await _assert_pickup_does_not_deploy(0)


func test_emulated_mouse_pickup_with_enough_ammo_does_not_spend_or_deploy() -> void:
	await _assert_pickup_does_not_deploy(InputEvent.DEVICE_ID_EMULATION)


## T017: regresion adicional de W03. Conserva las cuatro pruebas T015 y
## prueba la celda libre SIN pickup, para no aceptar una guarda que arregla
## recoleccion a costa de bloquear el despliegue por mouse emulado.
func _assert_free_cell_without_pickup_deploys_once(device: int) -> void:
	await _fixture(true)
	_pickup.queue_free()
	await wait_physics_frames(2)
	var board: BoardManager = _host.get("_board_manager")
	var soldiers_before := _soldier_count()
	var deploy_cost: int = _host.soldado_deploy_stats.deploy_ammo_cost
	assert_false(is_instance_valid(_pickup), "Precondicion W03: no hay pickup bajo el gesto")
	assert_true(board.is_cell_free(PICKUP_CELL), "Precondicion W03: celda libre")
	assert_gte(EconomyManager.collected_ammo, deploy_cost, "Precondicion W03: saldo suficiente")
	await _press_and_release(device)
	print("T017_W03 device=", device, " ammo=", EconomyManager.collected_ammo, " changes=", _pool_changes, " soldiers_before=", soldiers_before, " soldiers_after=", _soldier_count(), " cell_free=", board.is_cell_free(PICKUP_CELL))
	assert_eq(EconomyManager.collected_ammo, 12 - deploy_cost, "FR-003/W03: un despliegue explicito debe cobrar el costo una vez")
	assert_eq(_pool_changes, [12 - deploy_cost], "FR-003/W03: exactamente un gasto")
	assert_eq(_soldier_count(), soldiers_before + 1, "FR-003/W03: exactamente un soldado nuevo")
	assert_false(board.is_cell_free(PICKUP_CELL), "FR-003/W03: el nuevo soldado ocupa la celda")


func test_normal_mouse_on_free_cell_without_pickup_deploys_and_spends_once() -> void:
	await _assert_free_cell_without_pickup_deploys_once(0)


func test_emulated_mouse_on_free_cell_without_pickup_deploys_and_spends_once() -> void:
	await _assert_free_cell_without_pickup_deploys_once(InputEvent.DEVICE_ID_EMULATION)
