extends GutTest
## T037: test del autoload `WaveManager` (`autoloads/wave_manager.gd`) — cubre
## "generación de oleadas" de `constitution.md` Principio II, y los
## Acceptance Scenarios de `spec.md` User Story 3:
##   1. una oleada siguiente puede describirse con más/enemigos más fuertes
##      que la anterior (secuencia ordenada, sin saltos ni reordenamientos).
##   2. al derrotar todos los enemigos de todas las oleadas programadas, el
##      jugador recibe una condición de victoria (`all_waves_completed`).
##   3. (cubierto en `test_game_state_manager.gd`/T038: `game_lost` al recibir
##      `reached_defended_position`, no responsabilidad de `WaveManager`.)
##
## FASE RED: `autoloads/wave_manager.gd` **NO EXISTE TODAVÍA** — lo crea T039,
## después de que este archivo esté escrito y auditado. Se carga el script
## con `load()` (no `preload` como const de nivel de script, mismo motivo
## documentado en `test_economy_manager.gd`/`test_game_state_manager.gd`: un
## `preload` roto rompería la carga de TODO este archivo de test en vez de
## fallar de forma controlada test por test). Con el archivo ausente,
## `load(WAVE_MANAGER_SCRIPT_PATH)` retorna `null` y `.new()` sobre `null`
## produce un error en tiempo de ejecución dentro de `before_each()` — eso
## hace fallar TODOS los tests de este archivo de forma controlada, que es
## exactamente el resultado esperado de esta fase (ningún test debe pasar
## "por accidente" contra código inexistente).
##
## `WaveManager` no está registrado todavía como autoload en `project.godot`
## (eso es T040, tarea posterior) — por eso se instancia directamente vía
## `load()+.new()` + `add_child_autofree()`, igual que
## `test_economy_manager.gd`/`test_game_state_manager.gd` con sus autoloads
## respectivos antes de T010.
##
## ---------------------------------------------------------------------------
## CONTRATO PÚBLICO ASUMIDO para `WaveManager` (no fijado por ningún test
## previo — decisión de este archivo, documentada aquí para que T039 tenga
## una API concreta que implementar; corresponde a lo que se infiere de
## `tasks.md` T037/T039, `contracts/signals.md`, `data-model.md` y
## `docs/ARCHITECTURE.md` §4.1/§5):
##
## - `Node` autoload, SIN `class_name` (convención de `ARCHITECTURE.md` §4.1
##   para scripts de autoload: se referencian por su nombre de singleton).
## - Señales (`contracts/signals.md`):
##     - `wave_started(wave_number: int)`
##     - `wave_completed(wave_number: int)`
##     - `all_waves_completed()`
## - `var waves: Array[WaveData]` — la secuencia consumida, fijada por
##   `start_waves()`.
## - `var current_wave_index: int` — `-1` antes de arrancar la secuencia (o
##   tras completarla); índice dentro de `waves` mientras una oleada está
##   activa.
## - `func start_waves(new_waves: Array[WaveData]) -> void`:
##     - Fija `waves = new_waves`, `current_wave_index = 0` y emite
##       `wave_started(waves[0].wave_number)` — SALVO que `new_waves` esté
##       vacío, en cuyo caso emite `all_waves_completed()` directamente sin
##       ningún `wave_started` (edge case: nivel sin oleadas configuradas no
##       debe dejar la partida colgada esperando una oleada que nunca llega).
## - `func notify_enemy_defeated() -> void`: método público que algo externo
##   a `WaveManager` (el `WaveSpawner` de `nivel_monte_calvo.gd`, T042 —
##   quien SÍ instancia enemigos vía `ObjectPool` y escucha su señal
##   `enemy_defeated` de T026) invoca una vez por cada enemigo derrotado que
##   pertenece a la oleada activa. `WaveManager` NO instancia enemigos ni
##   corre el `Timer`/cola de `spawn_interval` — esa temporización de spawn
##   concreta es responsabilidad de `WaveSpawner` en el nivel (T042, según
##   la descripción explícita de esa tarea en `tasks.md`); `WaveManager`
##   solo necesita saber CUÁNTOS enemigos totales componen la oleada activa
##   (calculable de antemano sumando `count` de cada `WaveSpawnEntry` de
##   `spawn_entries`, sin depender de temporización) y CUÁNDO cada uno de
##   esos enemigos fue derrotado, para decidir el avance de la secuencia:
##     - Al llegar el conteo de derrotados de la oleada activa a su total,
##       emite `wave_completed(current_wave.wave_number)`.
##     - Si queda una oleada siguiente en `waves`, avanza
##       `current_wave_index` y emite
##       `wave_started(waves[current_wave_index].wave_number)`.
##     - Si NO queda una oleada siguiente (era la última), emite
##       `all_waves_completed()` en vez de un nuevo `wave_started` (y dado
##       que también era la última, esto ocurre DESPUÉS de su propio
##       `wave_completed`).
##     - Llamadas de más (más allá del total de la oleada activa, ej. por un
##       doble disparo de señal) o llamadas antes de cualquier
##       `start_waves()` no deben re-emitir `wave_completed`/
##       `all_waves_completed` ni causar error — no-op defensivo.
## - `func get_current_wave() -> WaveData`: retorna el `WaveData` activo, o
##   `null` si no hay ninguna oleada en curso (antes de `start_waves()` o
##   tras `all_waves_completed()`).
##
## El payload `wave_number` de `wave_started`/`wave_completed` es el valor
## LITERAL del campo `WaveData.wave_number` (autorado, `data-model.md` lo
## describe como "informativo/depuración") — NO un índice recalculado por
## `WaveManager` — para que el número mostrado en el HUD coincida siempre
## con el que diseño fijó en el `.tres`. Los tests de este archivo usan
## valores de `wave_number` deliberadamente distintos de "índice + 1" (ej.
## 10, 20, 30) para que una implementación que confunda ambos falle de forma
## visible.
## ---------------------------------------------------------------------------

const WAVE_MANAGER_SCRIPT_PATH := "res://autoloads/wave_manager.gd"

var _wave_manager: Node


func before_each() -> void:
	_wave_manager = load(WAVE_MANAGER_SCRIPT_PATH).new()
	add_child_autofree(_wave_manager)


## Construye un WaveData de prueba con una única entrada de spawn cuyo
## `count` es la suma pedida — suficiente para no depender de
## `resources/waves/*.tres` de producción (T041, todavía no creados;
## verificado que `resources/waves/` no existe en este punto del repo).
func _build_wave(wave_number: int, total_enemies: int) -> WaveData:
	var entry := WaveSpawnEntry.new()
	entry.enemy_stats = EnemyStats.new()
	entry.count = total_enemies
	entry.spawn_interval = 0.1
	var wave := WaveData.new()
	wave.wave_number = wave_number
	wave.spawn_entries = [entry]
	return wave


## Variante con varias entradas de spawn dentro de la misma oleada (ej. dos
## tipos de enemigo distintos) — el total de la oleada es la suma de todos
## los `count`.
func _build_wave_multi(wave_number: int, counts: Array) -> WaveData:
	var entries: Array[WaveSpawnEntry] = []
	for c in counts:
		var entry := WaveSpawnEntry.new()
		entry.enemy_stats = EnemyStats.new()
		entry.count = c
		entry.spawn_interval = 0.1
		entries.append(entry)
	var wave := WaveData.new()
	wave.wave_number = wave_number
	wave.spawn_entries = entries
	return wave


## --- Estructura base ---

func test_wave_manager_script_extends_node() -> void:
	# Nota: se usa load() (no preload como const de nivel de script) por el
	# mismo motivo documentado arriba y en test_economy_manager.gd.
	var script := load(WAVE_MANAGER_SCRIPT_PATH)
	assert_eq(
		script.get_instance_base_type(), "Node",
		"WaveManager debe extender Node (autoload de secuencia de oleadas, no Resource)"
	)


func test_wave_manager_instantiates() -> void:
	assert_not_null(_wave_manager, "WaveManager.new() debe instanciar sin error")
	assert_true(_wave_manager is Node, "una instancia de WaveManager debe ser un Node")


func test_wave_manager_declares_expected_signals() -> void:
	assert_true(
		_wave_manager.has_signal("wave_started"),
		"WaveManager debe declarar la señal wave_started (contracts/signals.md)"
	)
	assert_true(
		_wave_manager.has_signal("wave_completed"),
		"WaveManager debe declarar la señal wave_completed (contracts/signals.md)"
	)
	assert_true(
		_wave_manager.has_signal("all_waves_completed"),
		"WaveManager debe declarar la señal all_waves_completed (contracts/signals.md)"
	)


func test_current_wave_index_starts_at_minus_one_before_any_start_waves_call() -> void:
	# Given/Then: antes de arrancar la secuencia, no hay ninguna oleada activa.
	assert_eq(
		_wave_manager.current_wave_index, -1,
		"current_wave_index debe ser -1 antes de llamar a start_waves()"
	)


func test_get_current_wave_returns_null_before_start_waves() -> void:
	assert_null(
		_wave_manager.get_current_wave(),
		"get_current_wave() debe retornar null antes de start_waves()"
	)


## --- start_waves(): inicio de la secuencia (Acceptance Scenario 1) ---

func test_start_waves_emits_wave_started_for_first_wave() -> void:
	# Given: una secuencia de 2 oleadas de prueba
	var waves: Array[WaveData] = [_build_wave(10, 2), _build_wave(20, 4)]
	watch_signals(_wave_manager)

	# When: comienza la secuencia
	_wave_manager.start_waves(waves)

	# Then: se emite wave_started con el wave_number de la PRIMERA oleada
	assert_signal_emitted(_wave_manager, "wave_started")
	assert_signal_emitted_with_parameters(_wave_manager, "wave_started", [10])


func test_start_waves_emits_wave_started_exactly_once_for_first_wave() -> void:
	var waves: Array[WaveData] = [_build_wave(10, 2), _build_wave(20, 4)]
	watch_signals(_wave_manager)

	_wave_manager.start_waves(waves)

	assert_signal_emit_count(
		_wave_manager, "wave_started", 1,
		"start_waves() no debe disparar wave_started más de una vez de entrada"
	)


func test_start_waves_sets_current_wave_index_to_zero() -> void:
	var waves: Array[WaveData] = [_build_wave(10, 2), _build_wave(20, 4)]

	_wave_manager.start_waves(waves)

	assert_eq(
		_wave_manager.current_wave_index, 0,
		"tras start_waves(), current_wave_index debe apuntar a la primera oleada (0)"
	)


func test_get_current_wave_returns_first_wave_data_after_start() -> void:
	var first_wave := _build_wave(10, 2)
	var waves: Array[WaveData] = [first_wave, _build_wave(20, 4)]

	_wave_manager.start_waves(waves)

	assert_eq(
		_wave_manager.get_current_wave(), first_wave,
		"get_current_wave() debe retornar la misma instancia de WaveData de la oleada activa"
	)


func test_start_waves_does_not_emit_wave_completed_or_all_waves_completed_immediately() -> void:
	# Given: una oleada con enemigos pendientes de derrotar
	var waves: Array[WaveData] = [_build_wave(10, 3)]
	watch_signals(_wave_manager)

	_wave_manager.start_waves(waves)

	assert_signal_not_emitted(
		_wave_manager, "wave_completed",
		"no debe completarse una oleada que todavía no perdió ningún enemigo"
	)
	assert_signal_not_emitted(
		_wave_manager, "all_waves_completed",
		"no debe terminar la partida mientras la única oleada sigue activa"
	)


## --- notify_enemy_defeated(): avance de una oleada individual ---

func test_wave_completed_not_emitted_before_all_enemies_of_wave_are_defeated() -> void:
	# Given: una oleada con 3 enemigos totales
	var waves: Array[WaveData] = [_build_wave(10, 3)]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	# When: solo 2 de los 3 son derrotados
	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()

	# Then: la oleada todavía no se considera completa
	assert_signal_not_emitted(
		_wave_manager, "wave_completed",
		"wave_completed no debe emitirse hasta que TODOS los enemigos de la oleada mueran"
	)


func test_wave_completed_emitted_when_last_enemy_of_wave_is_defeated() -> void:
	# Given: una oleada con 3 enemigos totales (una sola entrada de spawn)
	var waves: Array[WaveData] = [_build_wave(10, 3), _build_wave(20, 2)]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	# When: se derrotan los 3 enemigos de la oleada activa
	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()

	# Then: se emite wave_completed con el wave_number de la oleada recién terminada
	assert_signal_emitted(_wave_manager, "wave_completed")
	assert_signal_emitted_with_parameters(_wave_manager, "wave_completed", [10])


func test_wave_completed_counts_enemies_across_multiple_spawn_entries() -> void:
	# Given: una oleada con DOS entradas de spawn (ej. 2 tipos de enemigo
	# distintos), 2 + 3 = 5 enemigos en total.
	var waves: Array[WaveData] = [_build_wave_multi(10, [2, 3])]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	# When: se derrotan 4 de los 5 (todavía no completa)
	for i in 4:
		_wave_manager.notify_enemy_defeated()
	assert_signal_not_emitted(
		_wave_manager, "wave_completed",
		"con 4/5 derrotados (contando ambas entradas) la oleada no debe darse por completa"
	)

	# When: se derrota el 5to y último
	_wave_manager.notify_enemy_defeated()

	# Then: recién ahí se completa, contando el total combinado de ambas entradas
	assert_signal_emitted(_wave_manager, "wave_completed")
	assert_signal_emitted_with_parameters(_wave_manager, "wave_completed", [10])


## --- Secuencia entre oleadas (Acceptance Scenario 1) ---

func test_completing_a_wave_starts_the_next_one() -> void:
	# Given: 2 oleadas, la primera con 2 enemigos
	var waves: Array[WaveData] = [_build_wave(10, 2), _build_wave(20, 4)]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	# When: se completa la primera oleada
	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()

	# Then: arranca automáticamente la segunda oleada
	assert_signal_emitted(_wave_manager, "wave_started")
	assert_signal_emitted_with_parameters(_wave_manager, "wave_started", [20])
	assert_eq(
		_wave_manager.current_wave_index, 1,
		"tras completar la oleada 0, current_wave_index debe avanzar a 1"
	)


func test_wave_started_for_second_wave_fires_after_wave_completed_of_first() -> void:
	# Orden observable de eventos: primero se cierra la oleada anterior,
	# recién después arranca la siguiente (no al revés, no simultáneo).
	var waves: Array[WaveData] = [_build_wave(10, 1), _build_wave(20, 1)]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	_wave_manager.notify_enemy_defeated()

	var wave_completed_params = get_signal_parameters(_wave_manager, "wave_completed", 0)
	var wave_started_params = get_signal_parameters(_wave_manager, "wave_started", 0)
	# La emisión de wave_started en este punto es la de la SEGUNDA oleada
	# (índice 0 dentro de las emisiones capturadas DESPUÉS de watch_signals,
	# que se llamó luego del wave_started inicial de start_waves()).
	assert_eq(wave_completed_params, [10], "wave_completed debe reportar la oleada recién cerrada (10)")
	assert_eq(wave_started_params, [20], "wave_started debe reportar la oleada recién abierta (20)")


func test_full_three_wave_sequence_fires_wave_started_and_completed_in_order() -> void:
	# Given: 3 oleadas de dificultad creciente (más enemigos en cada una),
	# reflejando el Acceptance Scenario 1 de spec.md ("la siguiente oleada
	# contiene más enemigos... que la anterior").
	var waves: Array[WaveData] = [
		_build_wave(1, 2),
		_build_wave(2, 4),
		_build_wave(3, 6),
	]
	watch_signals(_wave_manager)

	_wave_manager.start_waves(waves)
	for i in 2:
		_wave_manager.notify_enemy_defeated()
	for i in 4:
		_wave_manager.notify_enemy_defeated()
	for i in 6:
		_wave_manager.notify_enemy_defeated()

	assert_signal_emit_count(
		_wave_manager, "wave_started", 3,
		"deben iniciarse exactamente las 3 oleadas configuradas, en orden"
	)
	assert_signal_emit_count(
		_wave_manager, "wave_completed", 3,
		"deben completarse exactamente las 3 oleadas configuradas"
	)
	assert_eq(get_signal_parameters(_wave_manager, "wave_started", 0), [1])
	assert_eq(get_signal_parameters(_wave_manager, "wave_started", 1), [2])
	assert_eq(get_signal_parameters(_wave_manager, "wave_started", 2), [3])
	assert_eq(get_signal_parameters(_wave_manager, "wave_completed", 0), [1])
	assert_eq(get_signal_parameters(_wave_manager, "wave_completed", 1), [2])
	assert_eq(get_signal_parameters(_wave_manager, "wave_completed", 2), [3])


## --- all_waves_completed (Acceptance Scenario 2, condición de victoria) ---

func test_all_waves_completed_not_emitted_while_waves_remain() -> void:
	var waves: Array[WaveData] = [_build_wave(10, 1), _build_wave(20, 1)]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	# When: se completa solo la primera de dos oleadas
	_wave_manager.notify_enemy_defeated()

	assert_signal_not_emitted(
		_wave_manager, "all_waves_completed",
		"no debe declararse victoria mientras quede al menos una oleada programada sin completar"
	)


func test_all_waves_completed_emitted_once_after_last_wave_fully_defeated() -> void:
	# Given: 2 oleadas
	var waves: Array[WaveData] = [_build_wave(10, 1), _build_wave(20, 2)]
	_wave_manager.start_waves(waves)

	# When: se completa la primera
	_wave_manager.notify_enemy_defeated()
	watch_signals(_wave_manager)

	# Y se completa la última (2 enemigos)
	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()

	# Then: se emite la condición de victoria, exactamente una vez
	assert_signal_emit_count(
		_wave_manager, "all_waves_completed", 1,
		"all_waves_completed debe emitirse exactamente una vez al terminar la última oleada"
	)


func test_all_waves_completed_does_not_emit_a_further_wave_started() -> void:
	# Given/When: se completa la única oleada configurada
	var waves: Array[WaveData] = [_build_wave(10, 1)]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	_wave_manager.notify_enemy_defeated()

	# Then: no hay una "oleada 2" fantasma — wave_started no vuelve a dispararse
	assert_signal_not_emitted(
		_wave_manager, "wave_started",
		"tras la última oleada no debe iniciarse una oleada nueva inexistente"
	)


func test_single_wave_sequence_emits_wave_completed_and_all_waves_completed() -> void:
	# Given: una secuencia de una sola oleada (caso mínimo válido)
	var waves: Array[WaveData] = [_build_wave(1, 2)]
	watch_signals(_wave_manager)

	_wave_manager.start_waves(waves)
	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()

	assert_signal_emitted_with_parameters(_wave_manager, "wave_completed", [1])
	assert_signal_emit_count(_wave_manager, "all_waves_completed", 1)


func test_get_current_wave_returns_null_after_all_waves_completed() -> void:
	var waves: Array[WaveData] = [_build_wave(10, 1)]
	_wave_manager.start_waves(waves)

	_wave_manager.notify_enemy_defeated()

	assert_null(
		_wave_manager.get_current_wave(),
		"no debe quedar ninguna oleada 'activa' una vez completada la secuencia entera"
	)


## --- Edge Cases ---

func test_start_waves_with_empty_array_emits_all_waves_completed_immediately() -> void:
	# Edge case (no explícito en spec.md, pero necesario para no dejar la
	# partida colgada): un nivel configurado sin ninguna oleada debe
	# resolverse como victoria inmediata, no como un estado de espera eterno.
	var empty_waves: Array[WaveData] = []
	watch_signals(_wave_manager)

	_wave_manager.start_waves(empty_waves)

	assert_signal_emit_count(
		_wave_manager, "all_waves_completed", 1,
		"una secuencia vacía de oleadas debe resolverse como completada de inmediato"
	)


func test_start_waves_with_empty_array_does_not_emit_wave_started() -> void:
	var empty_waves: Array[WaveData] = []
	watch_signals(_wave_manager)

	_wave_manager.start_waves(empty_waves)

	assert_signal_not_emitted(
		_wave_manager, "wave_started",
		"sin ninguna oleada configurada, jamás debe iniciarse una oleada"
	)


func test_notify_enemy_defeated_before_start_waves_does_not_error_or_emit_signals() -> void:
	# Edge case defensivo: si algo llamara notify_enemy_defeated() antes de
	# que exista una secuencia activa (ej. orden de inicialización de
	# escena inesperado), no debe romper ni emitir señales fantasma.
	watch_signals(_wave_manager)

	_wave_manager.notify_enemy_defeated()

	assert_signal_not_emitted(_wave_manager, "wave_completed")
	assert_signal_not_emitted(_wave_manager, "all_waves_completed")


func test_notify_enemy_defeated_beyond_wave_total_does_not_emit_duplicate_wave_completed() -> void:
	# Edge case defensivo: una señal de enemigo derrotado duplicada (ej. por
	# doble conexión accidental) no debe hacer que la misma oleada se
	# complete dos veces.
	var waves: Array[WaveData] = [_build_wave(10, 1)]
	_wave_manager.start_waves(waves)
	watch_signals(_wave_manager)

	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()
	_wave_manager.notify_enemy_defeated()

	assert_signal_emit_count(
		_wave_manager, "wave_completed", 1,
		"llamadas de más a notify_enemy_defeated() no deben re-emitir wave_completed"
	)
	assert_signal_emit_count(
		_wave_manager, "all_waves_completed", 1,
		"llamadas de más a notify_enemy_defeated() no deben re-emitir all_waves_completed"
	)
