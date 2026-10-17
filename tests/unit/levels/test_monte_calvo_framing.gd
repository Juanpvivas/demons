extends GutTest
## T033: encuadre observado del nivel real; el fixture NO instala cámara,
## transforma el canvas ni modifica presentación para resolver el requisito.
## push_input recorre nivel y physics picking; no equivale a toque físico.
const LevelScene := preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
const PickupScene := preload("res://scenes/levels/AmmoPickup.tscn")
var _viewport: SubViewport
var _level: Node2D
var _saved_ammo: int
var _saved_state: int
var _saved_waves: Dictionary


func before_each() -> void:
	_saved_ammo = EconomyManager.collected_ammo
	_saved_state = GameStateManager._current_state
	_saved_waves = {}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_waves[key] = WaveManager.get(key)
	EconomyManager.collected_ammo = 0
	GameStateManager._current_state = 0


func after_each() -> void:
	EconomyManager.collected_ammo = _saved_ammo
	GameStateManager._current_state = _saved_state
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


func _fixture(size: Vector2i) -> void:
	_viewport = SubViewport.new()
	_viewport.size = size
	_viewport.world_2d = World2D.new()
	_viewport.physics_object_picking = true
	_viewport.handle_input_locally = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(_viewport)
	_level = LevelScene.instantiate()
	_viewport.add_child(_level)
	_viewport.notify_mouse_entered()
	await wait_physics_frames(3)


func _assert_framing(label: String) -> void:
	var transform := _viewport.canvas_transform
	var axis := transform * Vector2(576, 500)
	assert_almost_eq(axis.x, _viewport.size.x / 2.0, 1.0, label + ": eje 576 centrado")
	assert_almost_eq(transform.origin.y, 0.0, 0.01, label + ": origen vertical efectivo, no posición de cámara")
	assert_almost_eq(transform.x, Vector2.RIGHT, Vector2(0.001, 0.001), label + ": sin zoom/rotación X")
	assert_almost_eq(transform.y, Vector2.DOWN, Vector2(0.001, 0.001), label + ": sin zoom/rotación Y")
	print("T033_FRAMING ", label, " viewport=", _viewport.size, " canvas=", transform, " axis=", axis)


func test_design_aspect_control_keeps_axis_and_vertical_origin() -> void:
	await _fixture(Vector2i(1152, 648))
	_assert_framing("16:9")


func test_ipad_control_preserves_existing_distribution() -> void:
	await _fixture(Vector2i(1152, 864))
	_assert_framing("iPad")


func test_xiaomi_wide_view_centers_combat_without_vertical_drift() -> void:
	await _fixture(Vector2i(1440, 648))
	_assert_framing("Xiaomi")


func test_browser_wide_view_centers_combat_without_vertical_drift() -> void:
	await _fixture(Vector2i(1684, 648))
	_assert_framing("Web móvil")


func test_resize_wide_and_back_to_ipad_does_not_accumulate_offset_or_move_gameplay() -> void:
	await _fixture(Vector2i(1152, 648))
	var soldier: Node2D = _level.get_node("Soldado")
	var board: Node2D = _level.get_node("Tablero")
	var defended: Node2D = _level.get_node("PosicionDefendida")
	var trenches: Node2D = _level.get_node("MonteCalvoVisual/Trincheras")
	for size: Vector2i in [Vector2i(1440, 648), Vector2i(1684, 648), Vector2i(1152, 864), Vector2i(1440, 648), Vector2i(1152, 648)]:
		_viewport.size = size
		await wait_physics_frames(3)
		_assert_framing("resize " + str(size))
		assert_eq(soldier.global_position, Vector2(576, 500))
		assert_eq(board.global_transform, Transform2D.IDENTITY)
		assert_eq(defended.global_position, Vector2(576, 650))
		assert_eq(trenches.global_transform, Transform2D.IDENTITY)
		assert_eq(_level.wave_spawn_position, Vector2(576, 50))


func _source_texture(texture: Texture2D) -> Texture2D:
	while texture is AtlasTexture:
		texture = (texture as AtlasTexture).atlas
	return texture


func _assert_decorative_coverage(size: Vector2i) -> void:
	await _fixture(size)
	var required_left := 576.0 - size.x / 2.0
	var required_right := 576.0 + size.x / 2.0
	var visual := _level.get_node("MonteCalvoVisual")
	# Acepta extensiones/copias con la misma textura; no exige un único sprite
	# gigante. Verifica geometría, no alfa/color ni la estética del horizonte.
	for path: String in ["Suelo/Terreno", "FondoMontanas/Cielo", "FondoMontanas/Panorama"]:
		var original: Sprite2D = visual.get_node(path)
		var intervals: Array[Vector2] = []
		for node: Node in visual.find_children("*", "Sprite2D", true, false):
			var sprite := node as Sprite2D
			if not sprite.is_visible_in_tree() or sprite.texture == null:
				continue
			if _source_texture(sprite.texture) != _source_texture(original.texture):
				continue
			var rect: Rect2 = sprite.global_transform * sprite.get_rect()
			intervals.append(Vector2(rect.position.x, rect.end.x))
		intervals.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
		var covered_until := required_left
		for interval in intervals:
			if interval.x <= covered_until + 1.0:
				covered_until = maxf(covered_until, interval.y)
		assert_gte(covered_until, required_right - 1.0, path + ": cobertura continua del encuadre requerido, incluido mundo negativo")
		print("T033_COVERAGE ", path, " required=", Vector2(required_left, required_right), " intervals=", intervals, " covered_until=", covered_until)


func test_design_aspect_control_has_existing_decorative_coverage() -> void:
	await _assert_decorative_coverage(Vector2i(1152, 648))


func test_wide_framing_has_continuous_sky_panorama_and_ground_coverage() -> void:
	await _assert_decorative_coverage(Vector2i(1684, 648))


func _press_world(world: Vector2, device: int) -> void:
	var screen := _viewport.canvas_transform * world
	assert_almost_eq(_level._screen_to_world(screen), world, Vector2(0.01, 0.01), "Ruta real inversa conserva mundo")
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	motion.device = device
	_viewport.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.device = device
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = screen
	event.global_position = screen
	event.pressed = true
	_viewport.push_input(event, true)
	await wait_physics_frames(3)
	event = event.duplicate()
	event.pressed = false
	event.button_mask = 0
	_viewport.push_input(event, true)
	await wait_physics_frames(2)


func _soldier_count() -> int:
	return _level.get_children().filter(func(node): return node is Soldado).size()


func _assert_four_economy_results(device: int, resize: bool) -> void:
	await _fixture(Vector2i(1152, 648) if resize else Vector2i(1440, 648))
	if resize:
		_viewport.size = Vector2i(1684, 648)
		await wait_physics_frames(3)
	_assert_framing("economía device=" + str(device))
	var world := Vector2(240, 240)
	var cell := Vector2i(2, 2)
	var board: BoardManager = _level._board_manager
	assert_true(board.is_cell_free(cell))
	var initial_count := _soldier_count()
	watch_signals(EconomyManager)
	await _press_world(world, device)
	assert_eq(EconomyManager.collected_ammo, 0, "Sin fondos no gasta")
	assert_eq(_soldier_count(), initial_count, "Sin fondos no despliega")
	assert_true(board.is_cell_free(cell))
	assert_signal_emit_count(EconomyManager, "deploy_or_reload_rejected", 1)
	EconomyManager.add_ammo(12)
	var pickup := PickupScene.instantiate() as AmmoPickup
	pickup.amount = 3
	pickup.position = world
	_level.add_child(pickup)
	await wait_physics_frames(3)
	await _press_world(world, device)
	assert_false(is_instance_valid(pickup), "Physics picking recoge el área real")
	assert_eq(EconomyManager.collected_ammo, 15, "Recoge3 una vez, sin gasto")
	assert_eq(_soldier_count(), initial_count, "Recoger no crea unidad")
	assert_true(board.is_cell_free(cell))
	await _press_world(world, device)
	assert_eq(EconomyManager.collected_ammo, 5, "Libre cobra10 una vez")
	assert_eq(_soldier_count(), initial_count + 1)
	var deployed := board.get_occupant(cell) as Soldado
	assert_not_null(deployed)
	if deployed != null:
		assert_eq(deployed.global_position, Vector2(240, 240))
	EconomyManager.add_ammo(10)
	await _press_world(world, device)
	assert_eq(EconomyManager.collected_ammo, 15, "Ocupada con fondos no gasta")
	assert_eq(_soldier_count(), initial_count + 1)
	assert_same(board.get_occupant(cell), deployed)


func test_four_mouse_economy_results_stay_aligned_under_wide_framing() -> void:
	await _assert_four_economy_results(0, false)


func test_four_emulated_mouse_economy_results_stay_aligned_after_resize() -> void:
	await _assert_four_economy_results(InputEvent.DEVICE_ID_EMULATION, true)
