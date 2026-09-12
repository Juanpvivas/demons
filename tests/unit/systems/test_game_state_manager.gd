extends GutTest
## Verificación del autoload GameStateManager (`autoloads/game_state_manager.gd`).
##
## Primera sección (T009): estructura base — enum GameState, estado inicial
## PLAYING, y las tres señales declaradas en contracts/signals.md.
##
## Segunda sección (T038, más abajo): comportamiento real de condiciones de
## victoria/derrota — `constitution.md` Principio II exige cobertura
## obligatoria de "condiciones de victoria/derrota". Reemplaza al test
## centinela `test_reached_defended_position_listener_does_not_exist_yet_before_t044`
## de T013, que documentaba la AUSENCIA de esta lógica; ahora que T038 fue
## encargado, ese centinela ya no aplica — esta sección documenta y prueba
## la lógica que T044 debe implementar.
##
## FASE TDD RED (T038): al momento de escribir esta sección, T044 (que
## implementa la lógica real en game_state_manager.gd) todavía NO existe.
## Los tests de la segunda sección DEBEN fallar ahora — eso es lo esperado.
##
## --- Contrato de API pública asumido para GameStateManager (a implementar
## --- por T044) ---
##
## `reached_defended_position` es una señal de INSTANCIA de cada `Enemigo`
## (`scenes/enemies/enemigo.gd`), no de un autoload — no existe todavía en
## ese script (la agrega T043). Por `docs/ARCHITECTURE.md` §4.2 ("ninguna
## conexión de señal fuera de `_ready()`, ni en callbacks puntuales"),
## `GameStateManager` (autoload, `_ready()` corre una sola vez al arrancar)
## NO puede conectarse directamente a cada instancia dinámica de `Enemigo`
## que todavía no existe cuando el autoload arranca. Este mismo problema ya
## está documentado y resuelto en el codebase para un caso análogo:
## `EconomyManager.notify_pickup_spawned()` (`autoloads/economy_manager.gd`)
## es un MÉTODO PÚBLICO que `Enemigo._spawn_ammo_pickup()` llama
## directamente, en vez de que `EconomyManager` escuche una señal de esa
## instancia. Se asume el mismo patrón aquí:
##
## - `GameStateManager.report_reached_defended_position() -> void`: método
##   público que otro nodo (el `Area2D` de "posición defendida" en
##   `Nivel_MonteCalvo.tscn`, T043) llama directamente al detectar
##   `body_entered` de un `Enemigo` — en vez de que `GameStateManager`
##   escuche `reached_defended_position` de cada instancia. Si el estado
##   actual es `PLAYING`, transiciona a `LOST`, emite `game_lost` y
##   `game_state_changed(LOST)`. Si el estado ya es `WON`/`LOST`, no hace
##   nada (decisión propia, conservadora — ver Edge Case más abajo).
##
## `all_waves_completed` SÍ es una señal de `WaveManager`, que T039/T040
## registran como autoload — conexión autoload-a-autoload en `_ready()` SÍ
## está permitida por `docs/ARCHITECTURE.md` §4.2. Se asume:
##
## - `GameStateManager._ready()` hace
##   `WaveManager.all_waves_completed.connect(_on_all_waves_completed)`.
## - `GameStateManager._on_all_waves_completed() -> void`: handler privado,
##   mismo criterio que `report_reached_defended_position()` (transiciona
##   PLAYING→WON, emite `game_won`/`game_state_changed(WON)`, no hace nada
##   si el estado ya es terminal).
##
## Como `WaveManager` (T039) todavía no existe como autoload en este punto
## del plan, estos tests no pueden verificar el cableado real de `.connect()`
## en `_ready()` — eso requeriría una prueba de integración con el autoload
## real registrado (fuera del alcance de T038). En su lugar, se prueba el
## comportamiento del handler `_on_all_waves_completed()` llamándolo
## directamente sobre la instancia, que es lo que T044 debe implementar y lo
## que sí es responsabilidad de un test unitario aislado.
##
## Edge Case (decisión propia, no verificable línea por línea contra
## spec.md): una vez que el estado ya es `WON`/`LOST`, eventos adicionales
## (ej. otro enemigo alcanzando la posición después de ya haber perdido) no
## deberían volver a emitir señales para una transición que ya ocurrió. El
## spec no lo especifica explícitamente; se usa el criterio más
## conservador.
##
## GameStateManager no está registrado todavía como autoload en project.godot
## (T010 ya lo registra según tasks.md, pero este archivo sigue usando
## load()+.new() para aislar el test de ese registro global).

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


# --- T038: comportamiento real de victoria/derrota (FASE RED — T044 aún no
# --- implementa esta lógica; estos tests deben fallar hasta que T044 se
# --- complete). Reemplaza al test centinela de T013
# --- (`test_reached_defended_position_listener_does_not_exist_yet_before_t044`),
# --- que documentaba la ausencia de este comportamiento y ya no aplica.

## spec.md User Story 3, Acceptance Scenario 3: "Given una partida en curso,
## When un enemigo alcanza la posición defendida, Then la partida termina en
## derrota". FR-013. Cubre "condiciones de victoria/derrota"
## (constitution.md Principio II, cobertura obligatoria).
func test_report_reached_defended_position_from_playing_transitions_state_to_lost() -> void:
	assert_eq(
		_game_state_manager._current_state, _game_state_manager.GameState.PLAYING,
		"precondición: el estado debe arrancar en PLAYING"
	)

	_game_state_manager.report_reached_defended_position()

	assert_eq(
		_game_state_manager._current_state, _game_state_manager.GameState.LOST,
		"un enemigo alcanzando la posición defendida debe terminar la partida en derrota (FR-013)"
	)


func test_report_reached_defended_position_from_playing_emits_game_lost() -> void:
	watch_signals(_game_state_manager)

	_game_state_manager.report_reached_defended_position()

	assert_signal_emitted(
		_game_state_manager, "game_lost",
		"debe emitirse game_lost cuando un enemigo alcanza la posición defendida (contracts/signals.md)"
	)


func test_report_reached_defended_position_from_playing_emits_game_state_changed_with_lost() -> void:
	watch_signals(_game_state_manager)

	_game_state_manager.report_reached_defended_position()

	assert_signal_emitted_with_parameters(
		_game_state_manager, "game_state_changed", [_game_state_manager.GameState.LOST],
		"game_state_changed debe emitirse con el nuevo estado LOST (contracts/signals.md)"
	)


## Edge case (decisión propia, conservadora — no especificada explícitamente
## en spec.md): una vez que la partida ya terminó en derrota, un segundo
## reporte (ej. otro enemigo llegando después) no debe re-emitir señales
## para una transición que ya ocurrió.
func test_report_reached_defended_position_is_ignored_once_already_lost() -> void:
	_game_state_manager.report_reached_defended_position()
	watch_signals(_game_state_manager)

	_game_state_manager.report_reached_defended_position()

	assert_signal_not_emitted(
		_game_state_manager, "game_lost",
		"un segundo reporte tras ya estar LOST no debe volver a emitir game_lost"
	)
	assert_signal_not_emitted(
		_game_state_manager, "game_state_changed",
		"un segundo reporte tras ya estar LOST no debe volver a emitir game_state_changed"
	)


## spec.md User Story 3, Acceptance Scenario 2: "Given una partida en curso,
## When todos los enemigos de todas las oleadas programadas son derrotados,
## Then el jugador recibe una condición de victoria". Cubre "condiciones de
## victoria/derrota" (constitution.md Principio II, cobertura obligatoria).
##
## Se llama `_on_all_waves_completed()` directamente sobre la instancia (en
## vez de emitir la señal real desde un `WaveManager`, que todavía no existe
## como autoload — T039/T040 pendientes) para probar el comportamiento del
## handler de forma aislada, que es lo que T044 debe implementar.
func test_on_all_waves_completed_from_playing_transitions_state_to_won() -> void:
	assert_eq(
		_game_state_manager._current_state, _game_state_manager.GameState.PLAYING,
		"precondición: el estado debe arrancar en PLAYING"
	)

	_game_state_manager._on_all_waves_completed()

	assert_eq(
		_game_state_manager._current_state, _game_state_manager.GameState.WON,
		"derrotar todas las oleadas programadas debe otorgar la victoria (spec.md US3 AS2)"
	)


func test_on_all_waves_completed_from_playing_emits_game_won() -> void:
	watch_signals(_game_state_manager)

	_game_state_manager._on_all_waves_completed()

	assert_signal_emitted(
		_game_state_manager, "game_won",
		"debe emitirse game_won cuando se completan todas las oleadas (contracts/signals.md)"
	)


func test_on_all_waves_completed_from_playing_emits_game_state_changed_with_won() -> void:
	watch_signals(_game_state_manager)

	_game_state_manager._on_all_waves_completed()

	assert_signal_emitted_with_parameters(
		_game_state_manager, "game_state_changed", [_game_state_manager.GameState.WON],
		"game_state_changed debe emitirse con el nuevo estado WON (contracts/signals.md)"
	)


## Edge case (decisión propia, conservadora, simétrica a la de game_lost):
## una vez que la partida ya se ganó, un segundo aviso de oleadas
## completadas no debe re-emitir señales para una transición que ya ocurrió.
func test_on_all_waves_completed_is_ignored_once_already_won() -> void:
	_game_state_manager._on_all_waves_completed()
	watch_signals(_game_state_manager)

	_game_state_manager._on_all_waves_completed()

	assert_signal_not_emitted(
		_game_state_manager, "game_won",
		"un segundo aviso tras ya estar WON no debe volver a emitir game_won"
	)
	assert_signal_not_emitted(
		_game_state_manager, "game_state_changed",
		"un segundo aviso tras ya estar WON no debe volver a emitir game_state_changed"
	)
