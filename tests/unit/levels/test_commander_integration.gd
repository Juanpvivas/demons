extends GutTest
## 017/I2 T030: RED de integración real comandante↔nivel↔spawner. T026–T029
## sólo dejaron superficie neutral (`commander_config`/`commander_store`/
## `commander_seed`/`commander_session` sin instanciar ni conectar) — estas
## pruebas deben fallar hoy por esa integración ausente (contrato §4), no por
## import/sintaxis/API faltante: todas las propiedades/métodos usados aquí ya
## existen (T027/T028/T029 aprobados).
##
## Oráculo: el propio `core/commander_session.gd` aprobado en I1 (no se
## duplica su algoritmo); sólo se observa si el nivel real lo instancia, lo
## conecta al spawner y le pasa un contexto fiel al tablero/oleada vigentes.

const LEVEL_SCENE_PATH := "res://scenes/levels/Nivel_MonteCalvo.tscn"
const BOARD := preload("res://resources/levels/monte_calvo_board.tres")

var _saved_state: int
var _saved_ammo: int
var _saved_waves: Dictionary


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	_saved_ammo = EconomyManager.collected_ammo
	_saved_waves = {}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved_waves[key] = WaveManager.get(key)
	GameStateManager._current_state = GameStateManager.GameState.PLAYING


func after_each() -> void:
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo
	for key: String in _saved_waves:
		WaveManager.set(key, _saved_waves[key])


## Mismo patrón que `tests/unit/levels/test_nivel_montecalvo.gd::_load_level()`:
## detiene el `Timer` real para controlar manualmente cada aparición WAVE.
func _load_level() -> Node:
	var level: Node = load(LEVEL_SCENE_PATH).instantiate()
	add_child_autofree(level)
	(level.get("_wave_spawner") as WaveSpawner)._spawn_timer.stop()
	return level


func _expire_spawn_timer(level: Node) -> void:
	var spawner: WaveSpawner = level.get("_wave_spawner")
	spawner._spawn_timer.stop()
	spawner._spawn_timer.timeout.emit()
	spawner._spawn_timer.stop()


## Carga antes de activar + instanciación real (contrato §4, "Nivel `_ready()`:
## ... usar almacén TRANSIENT sin rutas reales ... Configurar Session tras
## crear defensores y antes del primer WAVE"). Hoy `commander_session` de
## `nivel_monte_calvo.gd` permanece `null` durante todo `_ready()`.
func test_level_ready_instantiates_an_active_commander_session_before_the_first_wave() -> void:
	var level := _load_level()
	var session: CommanderSession = level.commander_session
	assert_not_null(session,
		"`_ready()` debe instanciar una CommanderSession propia (TRANSIENT en escena directa) " +
		"antes de que WaveManager dispare el primer WAVE; hoy `commander_session` permanece null")
	if session == null:
		return
	var diagnostic := session.get_decision_snapshot()
	assert_eq(diagnostic.get("state"), "ACTIVE",
		"La sesión debe quedar ACTIVE tras cargar memoria compatible del Store, antes del primer WAVE")


## El spawner debe recibir exactamente esa misma instancia (contrato §4):
## hoy `WaveSpawner.setup()` se llama en `nivel_monte_calvo.gd::_ready()` sin
## pasar ningún séptimo argumento, así que `_commander_session` del spawner
## queda en null aunque el nivel llegara a crear su propia sesión.
func test_level_wires_its_own_commander_session_instance_into_the_wave_spawner() -> void:
	var level := _load_level()
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: el nivel debe poseer una sesión propia antes de poder conectarla")
	if session == null:
		return
	var spawner: WaveSpawner = level.get("_wave_spawner")
	var wired: CommanderSession = spawner.get("_commander_session")
	assert_same(wired, session,
		"`WaveSpawner.setup()` debe recibir la misma sesión que el nivel instanció, no quedarse en null")


## Contexto público al spawn (contrato §1/§2): wave_number/role/defenders/
## lane_loads deben reflejar la oleada y el tablero reales en el instante de
## la decisión. Hoy nadie construye ese snapshot ni llama `choose_lane` desde
## el flujo real: `_records` de la sesión inyectada permanece vacío.
func test_wave_spawn_context_reflects_current_wave_role_and_live_board_state() -> void:
	var level := _load_level()
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: sin sesión activa no hay contexto público que contrastar")
	if session == null:
		return
	_expire_spawn_timer(level)
	var records: Dictionary = session.get("_records")
	assert_eq(records.size(), 1,
		"La primera aparición WAVE confirmada debe registrarse en la sesión real inyectada por el nivel")
	if records.size() != 1:
		return
	var context: String = records.values()[0].get("context", "")
	var parts: PackedStringArray = context.split("/")
	assert_eq(parts.size(), 5, "El contexto público debe tener la forma fase/rol/carril/defensa/carga (contrato §1)")
	if parts.size() != 5:
		return
	assert_eq(parts[0], "early", "La oleada 1 cae en la fase temprana (phase_end_waves[0]=3)")
	assert_eq(parts[1], "A", "El primer WAVE de la oleada 1 de producción es un asaltante (rifle_range=0)")
	assert_eq(parts[3], "armed", "Los cinco defensores recién desplegados están vivos, con munición y en modo fusil")
	assert_eq(parts[4], "zero", "Nadie ha spawneado todavía: la carga observada por carril debe ser cero")


## FR-005 "Información permitida": excluir próximas órdenes del jugador. La
## categoría de defensa depende sólo del estado real observable del soldado
## (vivo/munición/modo), nunca de que el jugador lo tenga seleccionado — una
## selección de trinchera es intención futura del jugador sobre esa unidad,
## no un dato de combate ya resuelto.
func test_context_defense_category_ignores_currently_selected_trench_not_future_player_intent() -> void:
	var level := _load_level()
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: FR-005 exige contrastar el contexto real, no uno inexistente")
	if session == null:
		return
	assert_true(level.select_trench(BOARD.home_cells[0]),
		"Control: existe una selección real del jugador antes del spawn")
	_expire_spawn_timer(level)
	var records: Dictionary = session.get("_records")
	assert_eq(records.size(), 1)
	if records.size() != 1:
		return
	var context: String = records.values()[0].get("context", "")
	var parts: PackedStringArray = context.split("/")
	assert_eq(parts.size(), 5)
	if parts.size() != 5:
		return
	assert_eq(parts[3], "armed",
		"La categoría de defensa no debe cambiar por tener la trinchera seleccionada en la UI")


## Pausa/cierre (contrato §4, "`close_match()`/`_exit_tree()`: abandonar sólo
## si aún ACTIVE; nunca consolidar"). Hoy no hay sesión que abandonar.
func test_close_match_abandons_an_active_commander_session_without_consolidating_a_result() -> void:
	var level := _load_level()
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: sin sesión activa no hay nada que abandonar")
	if session == null:
		return
	level.close_match()
	var diagnostic := session.get_decision_snapshot()
	assert_eq(diagnostic.get("state"), "ABANDONED",
		"Cerrar el nivel sin WON/LOST debe abandonar la sesión, nunca finalizarla como victoria/derrota")


## ---------------------------------------------------------------------------
## 017/I2 T035: RED de cableado real de resultados (contrato §4, "notificar
## `record_defeat`/`record_breach` antes de `notify_enemy_defeated()`/
## `report_reached_defended_position()`; conectar `finish()` únicamente a
## `game_won`/`game_lost`"). Hoy `_on_enemy_defeated()` de
## `scenes/levels/wave_spawner.gd` sólo llama `WaveManager.notify_enemy_defeated()`
## y `_enemy_pool.release(enemy)`; `_on_posicion_defendida_body_entered()` de
## `nivel_monte_calvo.gd` sólo llama `enemy.notify_reached_defended_position()`
## y `GameStateManager.report_reached_defended_position()`; y
## `_on_commander_game_won()`/`_on_commander_game_lost()` siguen con `pass`
## sin conectar — ninguno de los tres toca `commander_session` todavía.
##
## Oráculo: el propio `core/commander_session.gd` aprobado en I1 (no se
## duplica su algoritmo de recompensa/cierre); sólo se observa si el nivel
## real lo consulta/cierra en el momento correcto del flujo real.

const STORE_SCRIPT := preload("res://core/commander_memory_store.gd")


## Doble mínimo de E/S que nunca toca disco real (`user://` o cualquier ruta):
## usado exclusivamente para demostrar que hoy nadie intenta guardar al
## terminar una partida real (contrato §6, "errores de save").
class _FailingIO:
	extends RefCounted
	var write_attempts: int = 0

	func exists(_path: String) -> Dictionary:
		return {"error": OK, "value": false}

	func size(_path: String) -> Dictionary:
		return {"error": OK, "value": 0}

	func read(_path: String, _max_bytes: int) -> Dictionary:
		return {"error": OK, "text": ""}

	func write(_path: String, _text: String) -> Dictionary:
		write_attempts += 1
		return {"error": ERR_FILE_CANT_WRITE, "stage": "write"}

	func remove(_path: String) -> Dictionary:
		return {"error": OK}


## Enemigo débil (muere con un solo `take_damage(max_health)`), sin fusil ni
## daño cuerpo a cuerpo, para producir un WON determinista con una sola baja.
func _weak_wave_stats() -> EnemyStats:
	var stats := EnemyStats.new()
	stats.max_health = 1
	stats.move_speed = 40.0
	stats.melee_damage = 0
	stats.ammo_drop = 0
	return stats


## Enemigo que nunca se detiene a disparar (rifle_range = 0) y avanza mucho
## más rápido que el tiempo de prueba — usado para los escenarios de cruce
## real de "PosicionDefendida" (mismo criterio de velocidad ya validado sin
## obstáculos por `test_nivel_montecalvo.gd`: 600px/s cubre los ~888px reales
## del tablero en ~90 physics frames).
func _unstoppable_wave_stats() -> EnemyStats:
	var stats := EnemyStats.new()
	stats.max_health = 999
	stats.move_speed = 600.0
	stats.melee_damage = 0
	stats.ammo_drop = 0
	return stats


func _single_short_wave(stats: EnemyStats) -> Array[WaveData]:
	var entry := WaveSpawnEntry.new()
	entry.enemy_stats = stats
	entry.count = 1
	entry.spawn_interval = 0.05
	var entries: Array[WaveSpawnEntry] = [entry]
	var wave := WaveData.new()
	wave.wave_number = 1
	wave.spawn_entries = entries
	var waves: Array[WaveData] = [wave]
	return waves


## Mismo patrón ya usado por `test_nivel_montecalvo.gd` (sobreescribir `waves`
## ANTES de `add_child_autofree`, por lo tanto antes de `_ready()`): sustituye
## sólo el CONTENIDO de la única oleada real por una de un solo enemigo
## controlado, conservando intacto el resto del cableado real (Session real,
## WaveManager/WaveSpawner/GameStateManager reales, cinco defensores reales).
func _load_level_with_single_short_wave(stats: EnemyStats, store: CommanderMemoryStore = null) -> Node:
	var level: Node = load(LEVEL_SCENE_PATH).instantiate()
	if store != null:
		level.commander_store = store
	level.waves = _single_short_wave(stats)
	add_child_autofree(level)
	return level


## Retira a los cinco defensores reales (muerte real, `take_damage()`) para
## aislar el cruce/avance del WAVE de prueba de cualquier combate automático
## o bloqueo físico sólido documentado por T043/T044 contra un Soldado vivo
## en el mismo carril — nunca se desactiva colisión ni física a mano.
func _defeat_all_defenders(level: Node) -> void:
	var board: BoardManager = level.get("_board_manager")
	for home: Vector2i in BOARD.home_cells:
		var soldier := board.get_occupant(home) as Soldado
		if soldier != null:
			soldier.take_damage(soldier.stats.max_health)


func _single_wave_enemy(level: Node) -> Enemigo:
	var spawner: WaveSpawner = level.get("_wave_spawner")
	for actor: Node in (spawner.get("_enemy_pool") as Node).get_children():
		var enemy := actor as Enemigo
		if enemy != null and enemy.is_targetable() and enemy.spawn_origin == Enemigo.SpawnOrigin.WAVE:
			return enemy
	return null


## 1) Orden real de la baja (contrato §4, "registrar antes de notificar"):
## el registro WAVE de esta única baja debe quedar `DEFEATED` ANTES de que
## `game_won` se emita (la emisión ocurre de forma síncrona, anidada dentro
## de la misma llamada a `WaveManager.notify_enemy_defeated()` que hace
## `_on_enemy_defeated()`) — comprobación de orden sin duplicar el algoritmo
## de `CommanderSession`, sólo observando su estado público en el instante
## exacto en que el resultado real se vuelve visible.
func test_last_wave_kill_closes_its_commander_record_as_defeated_before_the_victory_signal_fires() -> void:
	var level := _load_level_with_single_short_wave(_weak_wave_stats())
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: sin sesión activa no hay nada que cerrar")
	if session == null:
		return
	_defeat_all_defenders(level)
	await wait_seconds(0.3, "tiempo suficiente para el único spawn WAVE de la oleada de prueba")
	var enemy := _single_wave_enemy(level)
	assert_not_null(enemy, "Control: la oleada de prueba produjo su único WAVE real")
	if enemy == null:
		return
	var key := "%d:%d" % [enemy.get_instance_id(), enemy.activation_generation]
	var records_before: Dictionary = session.get("_records")
	assert_true(records_before.has(key), "Control: el spawn real quedó registrado por el comandante (T032)")
	if not records_before.has(key):
		return
	var statuses_at_victory: Array[String] = []
	var observe := func():
		statuses_at_victory.append(String((session.get("_records") as Dictionary)[key].get("status", "")))
	GameStateManager.game_won.connect(observe)
	enemy.take_damage(enemy.stats.max_health)
	if GameStateManager.game_won.is_connected(observe):
		GameStateManager.game_won.disconnect(observe)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON,
		"Control: el único WAVE real, ya sin defensores, completa la oleada de prueba")
	if GameStateManager._current_state != GameStateManager.GameState.WON:
		return
	assert_eq(statuses_at_victory, ["DEFEATED"],
		"`record_defeat()` debe cerrar el registro de esta baja ANTES de `game_won`/`notify_enemy_defeated()`/" +
		"`release()` (contrato §4); hoy el estado sigue 'OPEN' porque `_on_enemy_defeated()` " +
		"(scenes/levels/wave_spawner.gd) nunca llama `record_defeat()`")


## 2) Orden real del cruce (contrato §4) y única consolidación por terminal
## real (requisito 6, lado LOST): un WAVE real registrado que alcanza
## "PosicionDefendida" debe cerrar su propio registro como `BREACHED` ANTES
## de que `game_lost` se emita, y la sesión debe terminar `FINALIZED` (nunca
## seguir `ACTIVE`) cuando la derrota es real.
func test_wave_breach_closes_its_commander_record_as_breached_before_the_defeat_signal_fires() -> void:
	var level := _load_level_with_single_short_wave(_unstoppable_wave_stats())
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: sin sesión activa no hay nada que cerrar")
	if session == null:
		return
	_defeat_all_defenders(level)
	await wait_seconds(0.3, "tiempo suficiente para el único spawn WAVE de la oleada de prueba")
	var enemy := _single_wave_enemy(level)
	assert_not_null(enemy, "Control: la oleada de prueba produjo su único WAVE real, sin oposición")
	if enemy == null:
		return
	var key := "%d:%d" % [enemy.get_instance_id(), enemy.activation_generation]
	assert_true((session.get("_records") as Dictionary).has(key),
		"Control: el spawn real quedó registrado por el comandante (T032)")
	if not (session.get("_records") as Dictionary).has(key):
		return
	var statuses_at_defeat: Array[String] = []
	var observe := func():
		statuses_at_defeat.append(String((session.get("_records") as Dictionary)[key].get("status", "")))
	GameStateManager.game_lost.connect(observe)
	for frame in 150:
		if GameStateManager._current_state != GameStateManager.GameState.PLAYING:
			break
		await wait_physics_frames(1)
	if GameStateManager.game_lost.is_connected(observe):
		GameStateManager.game_lost.disconnect(observe)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.LOST,
		"Control: el WAVE real, ya sin defensores, alcanza físicamente PosicionDefendida")
	if GameStateManager._current_state != GameStateManager.GameState.LOST:
		return
	assert_eq(statuses_at_defeat, ["BREACHED"],
		"`record_breach()` debe cerrar el registro de este cruce ANTES de `game_lost`/" +
		"`report_reached_defended_position()` (contrato §4); hoy el estado sigue 'OPEN' porque " +
		"`_on_posicion_defendida_body_entered()` (nivel_monte_calvo.gd) nunca llama `record_breach()`")
	assert_eq(session.get_decision_snapshot().get("state"), "FINALIZED",
		"Una derrota real (`game_lost`) debe consolidar la sesión llamando `finish()` (requisito 6); " +
		"hoy `_on_commander_game_lost()` sigue sin conectar (cuerpo `pass`, T027), así que la sesión " +
		"permanece 'ACTIVE' para siempre tras terminar la partida")


## 3) Candado/regresión (NO RED — ver guía de la tarea): el INITIAL nunca
## pasa por `register_spawn()` (FR-001, excluido explícitamente del bloque
## global), así que aunque cause LOST real, no debe abrir ni cerrar ningún
## registro de la sesión. Esto YA es cierto hoy porque nadie llama
## `record_breach()` en absoluto todavía (mismo criterio que T030 documentó
## para el INITIAL del spawner) — no cuenta como parte del RED de esta tarea;
## se conserva como candado para que la integración de T037 no empiece a
## registrar también al INITIAL por error.
func test_initial_enemy_breach_causes_defeat_without_opening_or_closing_any_commander_record() -> void:
	var level := _load_level()
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: sin sesión activa no hay nada que contrastar")
	if session == null:
		return
	var initial: Enemigo = null
	for actor: Node in (level.get("_wave_spawner") as WaveSpawner).get("_enemy_pool").get_children():
		var enemy := actor as Enemigo
		if enemy != null and enemy.spawn_origin == Enemigo.SpawnOrigin.INITIAL:
			initial = enemy
			break
	assert_not_null(initial, "Control: el nivel real activa su atacante inicial independiente")
	if initial == null:
		return
	_defeat_all_defenders(level)
	initial.stats = initial.stats.duplicate() as EnemyStats
	initial.stats.move_speed = 600.0
	initial.stats.rifle_range = 0.0
	initial.stats.melee_damage = 0
	for frame in 150:
		if GameStateManager._current_state != GameStateManager.GameState.PLAYING:
			break
		await wait_physics_frames(1)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.LOST,
		"Control: el INITIAL real, ya sin defensores, alcanza físicamente PosicionDefendida")
	if GameStateManager._current_state != GameStateManager.GameState.LOST:
		return
	assert_true((session.get("_records") as Dictionary).is_empty(),
		"El INITIAL nunca pasa por `register_spawn()`; su cruce real no debe abrir ni cerrar ningún " +
		"registro de la sesión (candado de regresión, ya GREEN hoy por ausencia total de integración)")


## 4) Única consolidación por terminal real (requisito 6, lado WON): una
## victoria real debe dejar la sesión `FINALIZED`, nunca `ACTIVE` para
## siempre.
func test_real_victory_finalizes_the_active_commander_session_instead_of_leaving_it_active_forever() -> void:
	var level := _load_level_with_single_short_wave(_weak_wave_stats())
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: sin sesión activa no hay nada que consolidar")
	if session == null:
		return
	_defeat_all_defenders(level)
	await wait_seconds(0.3, "tiempo suficiente para el único spawn WAVE de la oleada de prueba")
	var enemy := _single_wave_enemy(level)
	assert_not_null(enemy, "Control: la oleada de prueba produjo su único WAVE real")
	if enemy == null:
		return
	enemy.take_damage(enemy.stats.max_health)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON,
		"Control: el único WAVE real, ya sin defensores, completa la oleada de prueba")
	if GameStateManager._current_state != GameStateManager.GameState.WON:
		return
	assert_eq(session.get_decision_snapshot().get("state"), "FINALIZED",
		"Una victoria real (`game_won`) debe consolidar la sesión del comandante llamando `finish()`; " +
		"hoy `_on_commander_game_won()` sigue sin conectar (cuerpo `pass`, T027), así que la sesión " +
		"permanece 'ACTIVE' para siempre tras terminar la partida")


## 5) Errores de save (requisito 8): un fallo real de `commander_store.save()`
## debe reportarse (`commander_save_feedback`, contrato §6) y no debe dejar
## el almacén ni la siguiente partida contaminados/bloqueados. `_FailingIO`
## nunca toca `user://` ni ninguna ruta real — todas sus respuestas son
## simuladas en memoria (mismo criterio de aislamiento que
## `tests/unit/systems/test_commander_memory_store.gd`).
func test_failed_save_after_a_real_victory_reports_feedback_and_leaves_the_next_match_unaffected() -> void:
	var io := _FailingIO.new()
	var store := STORE_SCRIPT.new()
	store.storage_base_path = "/nonexistent/commander-017-t035-%d" % Time.get_ticks_usec()
	store.io_backend = io
	var level := _load_level_with_single_short_wave(_weak_wave_stats(), store)
	var session: CommanderSession = level.commander_session
	assert_not_null(session, "Precondición: sin sesión activa no hay nada que guardar")
	if session == null:
		return
	_defeat_all_defenders(level)
	watch_signals(level)
	await wait_seconds(0.3, "tiempo suficiente para el único spawn WAVE de la oleada de prueba")
	var enemy := _single_wave_enemy(level)
	assert_not_null(enemy, "Control: la oleada de prueba produjo su único WAVE real")
	if enemy == null:
		return
	enemy.take_damage(enemy.stats.max_health)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON,
		"Control: el único WAVE real, ya sin defensores, completa la oleada de prueba")
	if GameStateManager._current_state != GameStateManager.GameState.WON:
		return
	assert_gt(io.write_attempts, 0,
		"Una victoria real con al menos una muestra aprendida debe intentar `commander_store.save()`; " +
		"hoy nadie llama `save()` en todo el flujo real (T037 pendiente), así que ningún `write()` del " +
		"almacén se intenta jamás")
	assert_signal_emitted(level, "commander_save_feedback",
		"Un fallo de guardado terminal debe reportarse por `commander_save_feedback` (contrato §6); la " +
		"señal está declarada desde T027 pero hoy nunca se emite")
	# Control: el fallo de guardado no debe dejar el almacén compartido ni la
	# siguiente partida bloqueados o corrompidos (mismo almacén reutilizado,
	# igual que `game_root.gd::_start_match()` reutiliza su `commander_store`
	# entre intentos).
	var next_level: Node = load(LEVEL_SCENE_PATH).instantiate()
	next_level.commander_store = store
	add_child_autofree(next_level)
	var next_session: CommanderSession = next_level.commander_session
	assert_not_null(next_session, "Un fallo de guardado anterior no debe impedir instanciar la siguiente sesión")
	if next_session != null:
		assert_eq(next_session.get_decision_snapshot().get("state"), "ACTIVE",
			"La siguiente partida debe arrancar con una sesión ACTIVE normal, sin heredar el error de " +
			"guardado del intento anterior")
