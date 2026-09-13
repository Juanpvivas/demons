extends GutTest
## T002: sanity check de que el addon GUT está instalado y operativo
## end-to-end en este proyecto (headless, vía CLI). No prueba lógica de
## gameplay — eso llega con las features que sí tienen código que testear.


func test_gut_runner_executes_a_basic_assertion() -> void:
	assert_eq(2 + 2, 4, "GUT debe poder correr una aserción básica")


func test_project_input_map_has_select_cell_action() -> void:
	assert_true(
		InputMap.has_action("select_cell"),
		"T003: la acción 'select_cell' debe existir en el InputMap del proyecto"
	)


func test_project_input_map_has_collect_pickup_action() -> void:
	assert_true(
		InputMap.has_action("collect_pickup"),
		"T003: la acción 'collect_pickup' debe existir en el InputMap del proyecto"
	)


func test_select_cell_action_is_not_hardcoded_to_keyboard() -> void:
	var events := InputMap.action_get_events("select_cell")
	var has_key_event := false
	for event in events:
		if event is InputEventKey:
			has_key_event = true
	assert_false(
		has_key_event,
		"select_cell no debe depender de una tecla hardcodeada (debe soportar mouse/touch)"
	)
	assert_gt(
		events.size(), 0,
		"select_cell debe tener al menos un evento de input configurado"
	)


func test_collect_pickup_action_is_not_hardcoded_to_keyboard() -> void:
	var events := InputMap.action_get_events("collect_pickup")
	var has_key_event := false
	for event in events:
		if event is InputEventKey:
			has_key_event = true
	assert_false(
		has_key_event,
		"collect_pickup no debe depender de una tecla hardcodeada (debe soportar mouse/touch)"
	)
	assert_gt(
		events.size(), 0,
		"collect_pickup debe tener al menos un evento de input configurado"
	)
