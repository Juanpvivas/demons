extends GutTest
## Verificación básica del autoload GameStateManager (`autoloads/game_state_manager.gd`)
## tras T009. No hay una tarea de test GUT dedicada a T009 en tasks.md (la
## tarea de test explícita es T038, que depende de T009 y cubre la lógica de
## victoria/derrota real: escuchar reached_defended_position/all_waves_completed).
##
## En este punto (T009 recién completado) GameStateManager es solo
## estructura: enum GameState, estado inicial PLAYING, y las tres señales
## declaradas en contracts/signals.md, sin lógica de escucha todavía (T044).
## Este archivo cubre esa estructura base; T038 debe agregar aquí (o en este
## mismo archivo) los tests de comportamiento real de game_won/game_lost una
## vez T044 los implemente.
##
## GameStateManager no está registrado todavía como autoload en project.godot
## (T010 pendiente) — se carga el script directamente con load()+.new().

const GAME_STATE_MANAGER_SCRIPT_PATH := "res://autoloads/game_state_manager.gd"

var _game_state_manager: Node


func before_each() -> void:
	_game_state_manager = load(GAME_STATE_MANAGER_SCRIPT_PATH).new()
	add_child_autofree(_game_state_manager)


func test_game_state_manager_script_extends_node() -> void:
	# Nota: se usa load() (no preload como const de nivel de script) porque
	# GDScript trata un `const X := preload(...)` como referencia a "clase"
	# y bloquea llamar métodos de instancia como get_instance_base_type()
	# directamente sobre él ("Make an instance instead") — mismo patrón que
	# test_resource_schemas.gd.
	var script := load(GAME_STATE_MANAGER_SCRIPT_PATH)
	assert_eq(
		script.get_instance_base_type(), "Node",
		"GameStateManager debe extender Node (autoload de estado de partida, no Resource)"
	)


func test_game_state_manager_instantiates() -> void:
	assert_not_null(_game_state_manager, "GameStateManager.new() debe instanciar sin error")


func test_game_state_enum_has_expected_values() -> void:
	# GameState debe declarar exactamente PLAYING, PAUSED, WON, LOST
	# (contracts/signals.md: game_state_changed(new_state: GameState)).
	# Se accede al enum vía la instancia (no vía una const preload de la
	# "clase") por la misma razón documentada arriba.
	assert_has(_game_state_manager.GameState, "PLAYING")
	assert_has(_game_state_manager.GameState, "PAUSED")
	assert_has(_game_state_manager.GameState, "WON")
	assert_has(_game_state_manager.GameState, "LOST")


func test_initial_state_is_playing() -> void:
	# Given/Then: al arrancar la partida, el estado inicial debe ser PLAYING
	# (ninguna condición de victoria/derrota puede cumplirse antes de jugar).
	assert_eq(
		_game_state_manager._current_state, _game_state_manager.GameState.PLAYING,
		"el estado inicial de la partida debe ser PLAYING"
	)


func test_game_won_signal_exists() -> void:
	assert_true(
		_game_state_manager.has_signal("game_won"),
		"GameStateManager debe declarar la señal game_won (contracts/signals.md)"
	)


func test_game_lost_signal_exists() -> void:
	assert_true(
		_game_state_manager.has_signal("game_lost"),
		"GameStateManager debe declarar la señal game_lost (contracts/signals.md)"
	)


func test_game_state_changed_signal_exists() -> void:
	assert_true(
		_game_state_manager.has_signal("game_state_changed"),
		"GameStateManager debe declarar la señal game_state_changed (contracts/signals.md)"
	)


func test_game_state_changed_is_emitted_and_listenable_with_new_state_payload() -> void:
	# Sin lógica de escucha todavía (T044), esta prueba confirma que la señal
	# existe con la firma correcta y es escuchable end-to-end vía emisión
	# manual — no valida todavía que GameStateManager decida transicionar
	# por sí mismo ante reached_defended_position/all_waves_completed
	# (eso es responsabilidad de T038/T044).
	watch_signals(_game_state_manager)

	_game_state_manager.emit_signal("game_state_changed", _game_state_manager.GameState.LOST)

	assert_signal_emitted(_game_state_manager, "game_state_changed")
	assert_signal_emitted_with_parameters(
		_game_state_manager, "game_state_changed", [_game_state_manager.GameState.LOST]
	)


func test_reached_defended_position_listener_does_not_exist_yet_before_t044() -> void:
	# Documenta el estado esperado en este punto del plan: la lógica de
	# escuchar señales externas para decidir game_lost/game_won llega en
	# T044. Si este test falla, actualizar/eliminar junto con T038.
	assert_false(
		_game_state_manager.has_method("_on_reached_defended_position"),
		"el listener de reached_defended_position no debe existir todavía (llega en T044)"
	)
