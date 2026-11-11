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
