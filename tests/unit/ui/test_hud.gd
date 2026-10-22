extends GutTest
## T036: test de `scenes/ui/HUD.tscn` + `scenes/ui/hud.gd` — cubre FR-015
## ("mostrar al jugador la cantidad de munición recolectada disponible") y
## FR-011 ("impedir... e informar al jugador de esta restricción",
## `spec.md` User Story 2 Acceptance Scenario 4), vía `contracts/signals.md`
## (`EconomyManager.ammo_pool_changed` / `deploy_or_reload_rejected`).
##
## EconomyManager es un autoload real (`project.godot`, T010) compartido en
## el mismo proceso GUT entre TODOS los archivos de test — cualquier test que
## mute `collected_ammo` (directamente o vía `add_ammo`/`try_spend_ammo`)
## restaura su valor original al final, mismo patrón que
## `tests/unit/units/test_soldado.gd` y `tests/unit/levels/test_nivel_montecalvo.gd`.
##
## Se accede a los miembros internos con prefijo `_` del HUD (`_ammo_label`,
## `_rejection_label`, `_rejection_message_timer`) directamente desde el
## test, mismo patrón ya usado en el proyecto para verificar estado interno
## de un autoload (`test_game_state_manager.gd` con `_current_state`) — en
## GDScript el guion bajo es solo convención, no impone visibilidad real, y
## no hay una API pública alternativa para leer el texto mostrado en un
## `Label` de una escena concreta (no reutilizable) como esta.
##
## T045 (más abajo): mismas convenciones para las dos responsabilidades que
## agrega esa tarea (`spec.md` User Story 3) — aviso de "oleada por llegar"
## (`WaveManager.wave_started`) y pantalla de victoria/derrota
## (`GameStateManager.game_won`/`game_lost`).
##
## `WaveManager` y `GameStateManager` son también autoloads reales
## compartidos entre archivos de test (`project.godot`, T010/T040). A
## diferencia de `EconomyManager.collected_ammo` (un simple `int` mutado y
## restaurado), aquí se emite la señal DIRECTAMENTE sobre el autoload real
## (`WaveManager.wave_started.emit(n)`, `GameStateManager.game_won.emit()`,
## `GameStateManager.game_lost.emit()`) en vez de pasar por el método que
## dispara la lógica de negocio real (`start_waves()`,
## `report_reached_defended_position()`, `_on_all_waves_completed()`) —
## mismo patrón ya usado más abajo para el segundo rechazo de munición
## (`EconomyManager.deploy_or_reload_rejected.emit(...)`). Esto aísla el
## test del HUD de la lógica de esos otros autoloads (ya cubierta por
## `test_wave_manager.gd`/`test_game_state_manager.gd`) y evita dejar al
## autoload real en un estado mutado que afecte a otros archivos de test:
## emitir la señal a mano no cambia `current_wave_index` ni `_current_state`
## internos, así que no requiere restaurar nada al terminar.

const HUD_SCENE_PATH := "res://scenes/ui/HUD.tscn"

var _hud: Node


func before_each() -> void:
	_hud = null


func _spawn_hud() -> Node:
	_hud = load(HUD_SCENE_PATH).instantiate()
	add_child_autofree(_hud)
	return _hud


## 007/T011: HUD real; los resultados los resuelve GameStateManager,
## sin asignar su enum. La baja WAVE/cruce físico se cubren en GameRoot.
func _result_context(outcome: String) -> Dictionary:
	var context := {"state": GameStateManager._current_state, "ammo": EconomyManager.collected_ammo, "waves": {}}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		context.waves[key] = WaveManager.get(key)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.handle_input_locally = true
	add_child_autofree(viewport)
	viewport.notify_mouse_entered()
	context["viewport"] = viewport
	EconomyManager.collected_ammo = 9
	GameStateManager.start_new_match()
	_hud = load(HUD_SCENE_PATH).instantiate()
	viewport.add_child(_hud)
	if outcome == "won":
		var entry := WaveSpawnEntry.new()
		entry.enemy_stats = EnemyStats.new()
		entry.count = 1
		var wave := WaveData.new()
		wave.spawn_entries = [entry]
		var sequence: Array[WaveData] = [wave]
		WaveManager.start_waves(sequence)
		WaveManager.notify_enemy_defeated()
	else:
		GameStateManager.report_reached_defended_position()
	await wait_process_frames(2)
	return context


func _restore_result_context(context: Dictionary) -> void:
	GameStateManager._current_state = context.state
	EconomyManager.collected_ammo = context.ammo
	for key: String in context.waves:
		WaveManager.set(key, context.waves[key])


func _result_action(text: String) -> Button:
	for node: Node in _hud.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node as Button
	return null


func _click_result(viewport: SubViewport, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	viewport.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.global_position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		viewport.push_input(event, true)


func test_real_results_show_both_actions_and_focus_retry(
		outcome = use_parameters(["won", "lost"])) -> void:
	var context: Dictionary = await _result_context(outcome)
	var retry := _result_action("Volver a jugar")
	var menu := _result_action("Menú principal")
	assert_not_null(retry)
	assert_not_null(menu)
	assert_eq(_hud._game_over_label.text, "VICTORIA" if outcome == "won" else "DERROTA")
	if retry != null and menu != null:
		assert_true(retry.is_visible_in_tree())
		assert_true(menu.is_visible_in_tree())
		assert_same(context.viewport.gui_get_focus_owner(), retry, "El resultado permite activar retry con teclado")
	_restore_result_context(context)


func test_result_button_only_emits_its_intent_without_mutating_the_match(
		scenario = use_parameters(["won/retry", "lost/retry", "won/menu", "lost/menu"])) -> void:
	var parts: PackedStringArray = scenario.split("/")
	var context: Dictionary = await _result_context(parts[0])
	var signal_name := "retry_requested" if parts[1] == "retry" else "menu_requested"
	var other_signal := "menu_requested" if parts[1] == "retry" else "retry_requested"
	var button := _result_action("Volver a jugar" if parts[1] == "retry" else "Menú principal")
	assert_not_null(button)
	if button != null:
		var native: Array[bool] = []
		button.pressed.connect(func(): native.append(true))
		watch_signals(_hud)
		var state: int = GameStateManager._current_state
		var index: int = WaveManager.current_wave_index
		_click_result(context.viewport, button.get_global_rect().get_center())
		assert_eq(native.size(), 1, "Control positivo: el Viewport activó el Button real")
		assert_signal_emit_count(_hud, signal_name, 1)
		assert_signal_not_emitted(_hud, other_signal)
		assert_eq(GameStateManager._current_state, state, "HUD no navega ni reinicia Managers")
		assert_eq(WaveManager.current_wave_index, index)
		assert_eq(EconomyManager.collected_ammo, 9)
	_restore_result_context(context)


## --- Contador de munición al instanciar (FR-015) ---

func test_ammo_label_reflects_already_collected_ammo_immediately_on_ready() -> void:
	# Given: el pool global ya tiene munición recolectada ANTES de que el HUD
	# se instancie (ej. el HUD entra al árbol después de una recolección
	# previa; `ammo_pool_changed` solo se emite ante cambios posteriores, no
	# al conectar, así que el HUD debe leer el valor actual explícitamente)
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 17

	# When: se instancia el HUD y entra al árbol
	_spawn_hud()

	# Then: el contador de munición refleja ese valor ya existente sin
	# esperar ningún cambio posterior
	assert_string_contains(
		_hud._ammo_label.text, "17",
		"el Label de munición debe reflejar collected_ammo ya existente al instanciar el HUD (FR-015)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- Actualización del contador ante ammo_pool_changed (FR-015) ---

func test_ammo_label_updates_when_ammo_pool_changed_is_emitted() -> void:
	# Given: un HUD ya instanciado con un valor inicial conocido
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 2
	_spawn_hud()

	# When: el pool global cambia (ej. el jugador recolecta munición de un enemigo derrotado)
	EconomyManager.add_ammo(3)

	# Then: el contador refleja el nuevo total (2 + 3 = 5), no el valor inicial
	assert_string_contains(
		_hud._ammo_label.text, "5",
		"el Label de munición debe actualizarse al nuevo total tras ammo_pool_changed (FR-015)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- Mensaje de rechazo por munición insuficiente (FR-011, US2 Scenario 4) ---

func test_rejection_message_becomes_visible_with_reason_on_insufficient_funds() -> void:
	# Given: un HUD ya instanciado, con el pool global sin fondos suficientes
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 0
	_spawn_hud()
	assert_false(
		_hud._rejection_label.visible,
		"precondición del test: el mensaje de rechazo debe empezar oculto"
	)

	# When: el jugador intenta recargar o desplegar sin munición recolectada suficiente
	EconomyManager.try_spend_ammo(999)

	# Then: el sistema le informa de la restricción (FR-011) con un mensaje visible
	assert_true(
		_hud._rejection_label.visible,
		"el mensaje de rechazo debe volverse visible al recibir deploy_or_reload_rejected"
	)
	assert_eq(
		_hud._rejection_label.text, "Munición insuficiente",
		"el mensaje de rechazo debe mostrar el motivo (reason) recibido en la señal"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


func test_ammo_label_is_unaffected_by_a_rejected_spend() -> void:
	# Given: un HUD con un valor de munición conocido y sin fondos suficientes
	# para el próximo gasto
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 3
	_spawn_hud()

	# When: se rechaza un intento de gasto (EconomyManager no muta collected_ammo)
	EconomyManager.try_spend_ammo(999)

	# Then: el contador de munición sigue mostrando el mismo valor, sin cambios
	assert_string_contains(
		_hud._ammo_label.text, "3",
		"un gasto rechazado no debe alterar el contador de munición mostrado (no se emite ammo_pool_changed)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- Ocultamiento automático del mensaje de rechazo ---
##
## `hud.gd` documenta que el mensaje se oculta al expirar
## `RejectionMessageTimer` (`one_shot`, 2.5s, `HUD.tscn`). En vez de esperar
## 2.5s reales de wall-clock (lento y potencialmente frágil en CI), se
## emite directamente la señal `timeout` del propio `Timer` del HUD ya
## instanciado — ejercita el handler real conectado en `_ready()`
## (`_on_rejection_message_timer_timeout`), sin depender de temporización
## real ni de un mecanismo de "fast-forward" de `Timer` (Godot no expone
## uno; `Timer.time_left` es de solo lectura).

func test_rejection_message_hides_when_rejection_timer_times_out() -> void:
	# Given: un HUD con el mensaje de rechazo ya visible
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 0
	_spawn_hud()
	EconomyManager.try_spend_ammo(999)
	assert_true(
		_hud._rejection_label.visible,
		"precondición del test: el mensaje de rechazo debe estar visible antes del timeout"
	)

	# When: el temporizador de ocultamiento expira
	_hud._rejection_message_timer.emit_signal("timeout")

	# Then: el mensaje de rechazo se oculta automáticamente
	assert_false(
		_hud._rejection_label.visible,
		"el mensaje de rechazo debe ocultarse cuando RejectionMessageTimer emite timeout"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## Nota sobre "un nuevo rechazo reinicia el temporizador completo" (descrito
## en el reporte de `dev-godot` sobre `hud.gd`): verificar el reinicio
## *desde un valor parcial* requeriría dejar transcurrir tiempo real de
## wall-clock antes del segundo rechazo (`Timer.time_left` es de solo
## lectura y no hay forma de fast-forward/simular su conteo interno de
## forma determinista en GUT) — el mismo tipo de dependencia frágil que
## `test_nivel_montecalvo.gd` documenta evitar deliberadamente para T035.
## Se omite esa verificación específica; el test siguiente sí cubre, sin
## depender de tiempo real, que un segundo rechazo mientras el mensaje
## anterior sigue visible no lo oculta y reemplaza su texto (el
## comportamiento observable que importa para FR-011).
func test_new_rejection_while_previous_message_still_visible_keeps_it_visible_and_replaces_text() -> void:
	# Given: un HUD con un primer mensaje de rechazo ya visible
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 0
	_spawn_hud()
	EconomyManager.try_spend_ammo(999)
	assert_true(
		_hud._rejection_label.visible,
		"precondición del test: el primer mensaje de rechazo debe estar visible"
	)

	# When: ocurre un segundo rechazo antes de que el primer mensaje se oculte
	EconomyManager.deploy_or_reload_rejected.emit("Otro motivo de rechazo")

	# Then: el mensaje sigue visible (no se oculta a mitad de camino) y su
	# texto se reemplaza por el del rechazo más reciente
	assert_true(
		_hud._rejection_label.visible,
		"el mensaje de rechazo debe seguir visible tras un segundo rechazo mientras el anterior no expiró"
	)
	assert_eq(
		_hud._rejection_label.text, "Otro motivo de rechazo",
		"un nuevo rechazo debe reemplazar el texto del mensaje anterior"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- T045: estado inicial oculto (spec.md US3, Principio III de
## --- constitution.md — ningún aviso debe aparecer antes de que ocurra el
## --- evento que lo dispara) ---

func test_wave_label_starts_hidden_on_ready() -> void:
	_spawn_hud()

	assert_false(
		_hud._wave_label.visible,
		"el aviso de oleada por llegar debe empezar oculto en _ready()"
	)


func test_game_over_screen_starts_hidden_on_ready() -> void:
	_spawn_hud()

	assert_false(
		_hud._game_over_screen.visible,
		"la pantalla de victoria/derrota debe empezar oculta en _ready()"
	)


## --- T045: aviso de "oleada por llegar" (WaveManager.wave_started,
## --- contracts/signals.md, Principio III de constitution.md) ---

func test_wave_label_becomes_visible_with_wave_number_on_wave_started() -> void:
	# Given: un HUD ya instanciado, con el aviso de oleada oculto
	_spawn_hud()
	assert_false(
		_hud._wave_label.visible,
		"precondición del test: el aviso de oleada debe empezar oculto"
	)

	# When: WaveManager anuncia el comienzo de una nueva oleada
	WaveManager.wave_started.emit(3)

	# Then: el aviso se hace visible con el número de oleada (Principio III:
	# ninguna oleada nueva debe ser una transición silenciosa)
	assert_true(
		_hud._wave_label.visible,
		"el aviso de oleada debe volverse visible al recibir wave_started"
	)
	assert_string_contains(
		_hud._wave_label.text, "3",
		"el aviso de oleada debe mostrar el número de la oleada que comienza"
	)


func test_wave_label_hides_when_wave_message_timer_times_out() -> void:
	# Given: un HUD con el aviso de oleada ya visible
	_spawn_hud()
	WaveManager.wave_started.emit(1)
	assert_true(
		_hud._wave_label.visible,
		"precondición del test: el aviso de oleada debe estar visible antes del timeout"
	)

	# When: el temporizador de ocultamiento expira (mismo patrón que
	# RejectionMessageTimer: se emite `timeout` directamente sobre el propio
	# Timer del HUD ya instanciado, sin depender de tiempo real de wall-clock)
	_hud._wave_message_timer.emit_signal("timeout")

	# Then: el aviso se oculta automáticamente
	assert_false(
		_hud._wave_label.visible,
		"el aviso de oleada debe ocultarse cuando WaveMessageTimer emite timeout"
	)


## Mismo patrón discriminante que
## `test_new_rejection_while_previous_message_still_visible_keeps_it_visible_and_replaces_text`
## (T036): en vez de depender de tiempo real de wall-clock para verificar que
## el temporizador se reinicia desde un valor parcial (`Timer.time_left` es
## de solo lectura, sin forma determinista de fast-forward), se verifica el
## comportamiento observable que importa: un segundo `wave_started` mientras
## el aviso anterior sigue visible no lo oculta a mitad de camino, y
## reemplaza su texto por el de la oleada más reciente.
func test_new_wave_started_while_previous_message_still_visible_keeps_it_visible_and_replaces_text() -> void:
	# Given: un HUD con un primer aviso de oleada ya visible
	_spawn_hud()
	WaveManager.wave_started.emit(1)
	assert_true(
		_hud._wave_label.visible,
		"precondición del test: el primer aviso de oleada debe estar visible"
	)

	# When: comienza otra oleada antes de que el primer aviso se oculte
	WaveManager.wave_started.emit(2)

	# Then: el aviso sigue visible (no se oculta a mitad de camino) y su
	# texto se reemplaza por el de la oleada más reciente
	assert_true(
		_hud._wave_label.visible,
		"el aviso de oleada debe seguir visible tras un segundo wave_started mientras el anterior no expiró"
	)
	assert_string_contains(
		_hud._wave_label.text, "2",
		"un nuevo wave_started debe reemplazar el texto del aviso anterior con el número de oleada más reciente"
	)


## --- T045: pantallas de victoria/derrota (GameStateManager.game_won /
## --- game_lost, contracts/signals.md, spec.md US3 Acceptance Scenarios 2 y
## --- 3) ---

func test_game_over_screen_shows_victoria_on_game_won() -> void:
	# Given: un HUD ya instanciado, con la pantalla de fin de partida oculta
	_spawn_hud()
	assert_false(
		_hud._game_over_screen.visible,
		"precondición del test: la pantalla de fin de partida debe empezar oculta"
	)

	# When: GameStateManager anuncia la condición de victoria (spec.md US3
	# Acceptance Scenario 2: "todos los enemigos de todas las oleadas
	# programadas son derrotados... el jugador recibe una condición de
	# victoria")
	GameStateManager.game_won.emit()

	# Then: la pantalla de fin de partida se hace visible con el texto de
	# victoria
	assert_true(
		_hud._game_over_screen.visible,
		"la pantalla de fin de partida debe volverse visible al recibir game_won"
	)
	assert_eq(
		_hud._game_over_label.text, "VICTORIA",
		"la pantalla de fin de partida debe mostrar el mensaje de victoria"
	)


func test_game_over_screen_shows_derrota_on_game_lost() -> void:
	# Given: un HUD ya instanciado, con la pantalla de fin de partida oculta
	_spawn_hud()
	assert_false(
		_hud._game_over_screen.visible,
		"precondición del test: la pantalla de fin de partida debe empezar oculta"
	)

	# When: GameStateManager anuncia la condición de derrota (spec.md US3
	# Acceptance Scenario 3: "un enemigo alcanza la posición defendida... la
	# partida termina en derrota para el jugador")
	GameStateManager.game_lost.emit()

	# Then: la pantalla de fin de partida se hace visible con el texto de
	# derrota
	assert_true(
		_hud._game_over_screen.visible,
		"la pantalla de fin de partida debe volverse visible al recibir game_lost"
	)
	assert_eq(
		_hud._game_over_label.text, "DERROTA",
		"la pantalla de fin de partida debe mostrar el mensaje de derrota"
	)


## 005/T035: panel observador, intención con identidad y controles visibles.
func _reload_button() -> Button:
	for node: Node in _hud.find_children("*", "Button", true, false):
		if "Recargar" in (node as Button).text:
			return node as Button
	return null


## 005/T048: geometría utilizable; no certifica tipografía/arte ni toque de SO.
func test_i4_selected_hud_stays_contained_after_each_supported_resize() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	var soldier := preload("res://scenes/units/Soldado.tscn").instantiate() as Soldado
	viewport.add_child(soldier)
	_hud = load(HUD_SCENE_PATH).instantiate()
	viewport.add_child(_hud)
	_hud.set_selected_soldier(soldier)
	for size: Vector2i in [Vector2i(960, 540), Vector2i(1440, 648), Vector2i(1152, 864), Vector2i(1152, 648)]:
		viewport.size = size
		await wait_process_frames(3)
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		var button := _reload_button()
		assert_not_null(button)
		if button == null:
			continue
		assert_true(bounds.encloses(button.get_global_rect()), "Recargar visible tras resize " + str(size))
		assert_gte(button.size.y, 48.0, "Área de gesto conserva tamaño útil")
		for label: Label in [_hud._selection_label, _hud._individual_ammo_label, _hud._morale_label]:
			assert_true(bounds.encloses(label.get_global_rect()), "Lectura individual dentro de vista")
			assert_false(button.get_global_rect().intersects(label.get_global_rect()), "Botón no tapa datos individuales")
		assert_false(button.get_global_rect().intersects(_hud._ammo_label.get_global_rect()), "Reserva y control independientes")


func _individual_labels() -> String:
	# El panel de selección se identifica por su función, sin imponer un nombre exacto.
	for panel: Node in _hud.find_children("*", "Control", true, false):
		var title := str(panel.name).to_lower()
		if not ("selection" in title or "selected" in title or "seleccion" in title):
			continue
		var text := ""
		for node: Node in panel.find_children("*", "Label", true, false):
			if node.is_visible_in_tree():
				text += (node as Label).text + "\n"
		return text
	return ""


func _assert_panel_value(text: String, pattern: String, message: String) -> void:
	var regex := RegEx.new()
	regex.compile(pattern)
	assert_not_null(regex.search(text), message + ": " + text)


func test_i3_selected_panel_observes_individual_ammo_morale_and_reload_eligibility() -> void:
	var saved_state: int = GameStateManager._current_state
	var saved_ammo: int = EconomyManager.collected_ammo
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	EconomyManager.collected_ammo = 0
	var soldier := preload("res://scenes/units/Soldado.tscn").instantiate() as Soldado
	soldier.set_grid_cell(Vector2i(1, 5))
	add_child_autofree(soldier)
	soldier.set("_current_ammo", 0)
	soldier.set("_current_morale", 7.0)
	_spawn_hud()
	_hud.set_selected_soldier(soldier)
	assert_same(_hud.get_selected_soldier(), soldier)
	var panel := _individual_labels()
	_assert_panel_value(panel, "(?i)fila[^0-9]*5(?:[^0-9]|$)", "Fila individual 5")
	_assert_panel_value(panel, "(?i)(munici.n|carga)[^0-9]*0[ ]*/[ ]*10(?:[^0-9]|$)", "Carga/capacidad individual 0/10")
	_assert_panel_value(panel, "(?i)moral[^0-9]*7(?:[^0-9]|$)", "Moral individual 7")
	var button := _reload_button()
	assert_not_null(button, "Existe botón visible Recargar, sin depender de un nombre de nodo")
	if button != null:
		assert_true(button.is_visible_in_tree())
		assert_true(button.disabled, "Sin fondos se deshabilita")
		EconomyManager.add_ammo(soldier.stats.deploy_ammo_cost)
		assert_false(button.disabled, "La señal económica actualiza elegibilidad sin nueva selección")

		watch_signals(_hud)
		_hud.request_selected_reload()
		assert_signal_emitted_with_parameters(_hud, "reload_requested", [soldier.get_instance_id()])
		assert_eq(EconomyManager.collected_ammo, soldier.stats.deploy_ammo_cost, "HUD solo emite intención, no cobra")
		assert_eq(soldier.get_reload_state().ammo, 0)
		assert_true(soldier.request_reload())
		assert_true(button.disabled, "Aceptación deshabilita botón inmediatamente")
	GameStateManager._current_state = saved_state
	EconomyManager.collected_ammo = saved_ammo


func test_i3_empty_selection_and_dead_owner_do_not_emit_reload_intent() -> void:
	_spawn_hud()
	watch_signals(_hud)
	_hud.request_selected_reload()
	assert_signal_not_emitted(_hud, "reload_requested")
	var soldier := preload("res://scenes/units/Soldado.tscn").instantiate() as Soldado
	add_child_autofree(soldier)
	_hud.set_selected_soldier(soldier)
	soldier.take_damage(9999)
	_hud.request_selected_reload()
	assert_null(_hud.get_selected_soldier())
	assert_signal_not_emitted(_hud, "reload_requested")
	var button := _reload_button()
	assert_not_null(button)
	if button != null:
		assert_true(button.disabled)


func test_i3_ineligible_selected_owner_disables_control_and_rejects_direct_intent(
		scenario = use_parameters(["partial", "full", "returning", "terminal"])) -> void:
	var saved_state: int = GameStateManager._current_state
	var saved_ammo: int = EconomyManager.collected_ammo
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	EconomyManager.collected_ammo = 100
	var soldier := preload("res://scenes/units/Soldado.tscn").instantiate() as Soldado
	add_child_autofree(soldier)
	soldier.set("_current_ammo", 1 if scenario == "partial" else 10)
	if scenario == "returning":
		soldier.set("_movement_state", Soldado.MovementState.RETURNING)
	if scenario == "terminal":
		GameStateManager.report_reached_defended_position()
	_spawn_hud()
	_hud.set_selected_soldier(soldier)
	watch_signals(_hud)
	var button := _reload_button()
	assert_not_null(button)
	if button != null:
		assert_true(button.disabled)
	_hud.request_selected_reload()
	assert_signal_not_emitted(_hud, "reload_requested", "La invocación directa también revalida")
	assert_eq(EconomyManager.collected_ammo, 100)
	GameStateManager._current_state = saved_state
	EconomyManager.collected_ammo = saved_ammo
