## `WaveSpawner`: instancia los enemigos de la oleada activa vía `ObjectPool`
## y notifica a `WaveManager` cada eliminación (T042, `spec.md` User Story 3
## / FR-012). No decide "cuándo" hay una oleada nueva ni cuenta cuántos
## enemigos la componen (eso es responsabilidad exclusiva de `WaveManager`,
## `docs/ARCHITECTURE.md` §4.1 — "autoload orquestador no instancia ni
## temporiza"): este nodo solo reacciona a `WaveManager.wave_started`,
## consume `WaveManager.get_current_wave().spawn_entries`, y avisa con
## `WaveManager.notify_enemy_defeated()` una vez por cada baja WAVE.
##
## **Por qué vive en `scenes/levels/` y no en `core/`**: a diferencia de
## `ObjectPool`/`BoardManager` (utilidades genéricas reutilizables entre
## features, sin conocimiento de ningún tipo concreto de escena),
## `docs/ARCHITECTURE.md` §5 describe explícitamente a `WaveSpawner` como
## parte de la *composición de escena* de `Nivel_MonteCalvo.tscn` ("nodo
## `Timer` + cola de spawns"), y esta implementación sí conoce
## específicamente el contrato de `Enemigo` (`prepare_for_spawn()`,
## `set_pool()`, `enemy_defeated`) — no es una utilidad agnóstica. Se
## instancia vía código (`WaveSpawner.new()`) desde `nivel_monte_calvo.gd`
## en vez de vivir hardcodeado como nodo en el `.tscn`, mismo patrón ya
## usado ahí para `BoardManager`.
##
## 005/I1: la configuración opcional aporta cinco entradas y un cursor
## continuo entre oleadas. Sin configuración se conserva el spawn recibido.
##
## INITIAL y WAVE se retiran mediante este mismo pool. Solo WAVE notifica
## una baja a WaveManager; el enemigo conserva la recompensa de ambos orígenes.
##
## **Por qué `enemy_defeated` se conecta una sola vez por instancia física,
## no en cada spawn**: `docs/ARCHITECTURE.md` §4.2 exige que toda conexión
## de señal ocurra en `_ready()` (o cableado estructural equivalente), nunca
## en callbacks puntuales repetidos. Como una instancia pooleada se reutiliza
## muchas veces (`acquire()`/`release()` en ciclo, sin volver a pasar por
## `_ready()`), conectar `enemy_defeated` en cada spawn duplicaría la
## conexión en cada ciclo. En su lugar, este nodo escucha
## `ObjectPool.instance_created` (emitida solo la primera vez que el pool
## necesita crear una instancia física nueva) desde su propio `setup()`, y
## conecta `enemy_defeated` exactamente una vez por instancia ahí — esa
## única conexión cubre automáticamente todos los ciclos futuros de
## `acquire()`/`release()` de esa misma instancia.
class_name WaveSpawner
extends Node

## Instancia única de enemigo en espera de ser spawneada: qué `EnemyStats`
## usar y cuánto esperar (segundos) antes del siguiente spawn de la cola.
## Cola aplanada a partir de `WaveData.spawn_entries` (que agrupa por tipo)
## porque cada enemigo individual puede pertenecer a una `WaveSpawnEntry`
## con su propio `spawn_interval` — aplanar evita tener que rastrear en qué
## entrada y en qué repetición de esa entrada va la cola.
class _PendingSpawn:
	var enemy_stats: EnemyStats
	var interval_after: float

	func _init(stats: EnemyStats, interval: float) -> void:
		enemy_stats = stats
		interval_after = interval


## Pool de `Enemigo` de este nivel, creado y poseído por este nodo en
## `setup()` (no recibido como parámetro ya construido) para poder conectar
## `instance_created` ANTES de que `ObjectPool.setup()` pre-popule
## instancias — si el pool se creara y configurara fuera de este nodo,
## existiría una ventana donde las instancias pre-populadas emitirían
## `instance_created` sin que nadie todavía escuchara, y esas instancias
## nunca recibirían `set_pool()`/la conexión de `enemy_defeated`.
var _enemy_pool: ObjectPool

## Spawn recibido por los consumidores sin configuración por carriles.
var _spawn_position: Vector2
var _board_config: LaneBoardConfig
var _next_lane: int = 0
var _closing: bool = false

## Servicio local opcional: registro por creación física, nunca por acquire.
var _combat_visual_effects: CombatVisualEffects
var _combat_audio: CombatAudio

## 017/I2 T032: referencia a la sesión del comandante, inyectable desde
## `setup()` por el nivel dueño. `_on_spawn_timer_timeout()` la consulta para
## decidir el carril de cada WAVE (`choose_lane`/`register_spawn`, contrato
## §4); con `null` (camino legado, usado también por pruebas sin tablero)
## conserva exactamente el cursor `_next_lane` round-robin anterior.
var _commander_session: CommanderSession

## 017/I2 T032: fuente opcional del estado real de los defensores para el
## contexto público del comandante (contrato §1/§2, campo `defenders`). Vive
## en `nivel_monte_calvo.gd` (no en este nodo, que no posee ocupación de
## celdas) — mismo patrón ya usado para `board_config`/`combat_audio`:
## referencia inyectada por el nivel dueño en `setup()`, nunca construida
## aquí. Sin esta referencia (pruebas de este nodo sin tablero completo), los
## cinco carriles se reportan como "empty" — un contexto todavía válido para
## `CommanderSession.choose_lane()`, solo sin información real de defensa.
var _board_manager: BoardManager

## Cola de spawns pendientes de la oleada activa, ya aplanada. Vacía cuando
## no hay ninguna oleada en curso o cuando ya se sacó el último elemento.
var _pending_spawns: Array[_PendingSpawn] = []

## `Timer` interno que mide el `spawn_interval` entre spawns sucesivos.
## Creado por código (este nodo no tiene una escena `.tscn` propia) y
## agregado como hijo en `_ready()`, mismo momento en que se cablean sus
## señales (`docs/ARCHITECTURE.md` §4.2).
@onready var _spawn_timer: Timer = Timer.new()


func _ready() -> void:
	_spawn_timer.one_shot = true
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	WaveManager.wave_started.connect(_on_wave_started)


func close_match() -> void:
	if _closing:
		return
	_closing = true
	_spawn_timer.stop()
	_pending_spawns.clear()
	if _enemy_pool != null:
		for actor: Node in _enemy_pool.get_children():
			if actor is Enemigo:
				(actor as Enemigo).close_match()
	if WaveManager.wave_started.is_connected(_on_wave_started):
		WaveManager.wave_started.disconnect(_on_wave_started)


func _exit_tree() -> void:
	close_match()


## Crea el pool y conserva la configuración compartida de geometría. Debe llamarse una
## vez desde el nivel dueño (`nivel_monte_calvo.gd`) antes de que
## `WaveManager.start_waves()` dispare el primer `wave_started` — si se
## llamara después, el primer `wave_started` no encontraría `_enemy_pool`
## listo.
func setup(enemy_scene: PackedScene, initial_pool_size: int, spawn_position: Vector2,
		combat_visual_effects: CombatVisualEffects = null,
		board_config: LaneBoardConfig = null, combat_audio: CombatAudio = null,
		commander_session: CommanderSession = null, board_manager: BoardManager = null) -> void:
	_spawn_position = spawn_position
	_board_config = board_config
	_next_lane = 0
	_combat_visual_effects = combat_visual_effects
	_combat_audio = combat_audio
	_commander_session = commander_session
	_board_manager = board_manager
	_enemy_pool = ObjectPool.new()
	add_child(_enemy_pool)
	# Conectado ANTES de `setup()` — ver justificación en la cabecera de
	# `_enemy_pool` arriba.
	_enemy_pool.instance_created.connect(_on_enemy_pool_instance_created)
	_enemy_pool.setup(enemy_scene, initial_pool_size)


## Activación inmediata independiente: fila central, sin consumir el cursor.
func spawn_initial_enemy(stats: EnemyStats) -> Enemigo:
	if _closing or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return null
	var lane := 2 if _board_config != null else -1
	return _activate_enemy(stats, lane, Enemigo.SpawnOrigin.INITIAL)


func _activate_enemy(stats: EnemyStats, lane: int, origin: Enemigo.SpawnOrigin) -> Enemigo:
	var enemy := _enemy_pool.acquire() as Enemigo
	var spawn_at := _spawn_position if lane < 0 else _board_config.spawn_positions[lane]
	enemy.prepare_for_spawn(stats, spawn_at, lane, origin)
	return enemy


## Encolado de la nueva oleada activa (aplana `spawn_entries`) y arranque
## del `Timer` para el primer spawn, que espera `spawn_interval` como
## cualquier otro (ver justificación en `_on_spawn_timer_timeout()` de por
## qué NINGÚN spawn, ni siquiera el primero de la oleada, ocurre de forma
## síncrona/inmediata). Un `WaveData` sin `spawn_entries` (caso degenerado,
## ningún `.tres` de producción lo tiene) deja la cola vacía y no spawnea
## nada — no es responsabilidad de este nodo decidir qué pasa con una
## oleada mal configurada, solo no debe fallar.
func _on_wave_started(_wave_number: int) -> void:
	if _closing:
		return
	_spawn_timer.stop()
	_pending_spawns.clear()

	var wave: WaveData = WaveManager.get_current_wave()
	if wave == null:
		return

	for entry: WaveSpawnEntry in wave.spawn_entries:
		for i in entry.count:
			_pending_spawns.append(_PendingSpawn.new(entry.enemy_stats, entry.spawn_interval))

	if not _pending_spawns.is_empty():
		_spawn_timer.start(_pending_spawns[0].interval_after)


## Todo WAVE, incluido el primero, espera el intervalo autorado. El inicial
## es independiente y no reinicia ni consume el cursor de las oleadas.
##
## 017/I2 T032 (contrato §4, "Sustituir sólo la selección de lane; registrar
## token+actor/generación después de la activación exitosa. El contexto y
## elección se calculan antes de añadir ese nuevo enemigo a la carga
## observada"): con `_commander_session` inyectada, el contexto público
## (`_commander_snapshot()`) se construye y se consulta `choose_lane()` ANTES
## de `_activate_enemy()` — el nuevo enemigo todavía no existe y por tanto no
## se cuenta a sí mismo en `lane_loads`. Sin sesión (camino legado, también
## usado por pruebas sin tablero), o si la sesión no propone carril (sin
## pendientes/sesión no ACTIVE), se conserva el cursor `_next_lane`
## round-robin anterior sin ningún cambio de comportamiento.
func _on_spawn_timer_timeout() -> void:
	if _closing or _pending_spawns.is_empty() \
			or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return

	var next: _PendingSpawn = _pending_spawns.pop_front()
	var lane := _next_lane if _board_config != null else -1
	var decision: Dictionary = {}
	if _commander_session != null and _board_config != null:
		decision = _commander_session.choose_lane(_commander_snapshot())
		if not decision.is_empty():
			lane = int(decision.lane)

	# `ObjectPool.acquire()` no admite argumentos (`docs/ARCHITECTURE.md`
	# §4.5): la instancia devuelta puede conservar el `stats`/salud de un
	# uso anterior (o el default embebido en `EnemigoBase.tscn` en su
	# primera creación), nunca el `EnemyStats` correcto de esta
	# `WaveSpawnEntry`. En vez de depender del hook automático
	# `on_pool_acquired()` (que correría ANTES de que este método pudiera
	# asignar el `stats` correcto — ver orden interno de
	# `ObjectPool.acquire()`), se reasigna todo explícitamente aquí vía
	# `prepare_for_spawn()`, después de `acquire()`.
	var enemy := _activate_enemy(next.enemy_stats, lane, Enemigo.SpawnOrigin.WAVE)

	if not decision.is_empty():
		var spawn_x: float = _board_config.spawn_positions[lane].x
		var defended_right: float = _board_config.defended_rect.position.x \
			+ _board_config.defended_rect.size.x
		var registered := _commander_session.register_spawn(decision, enemy.get_instance_id(),
			enemy.activation_generation, spawn_x, defended_right)
		if not registered:
			# Activación real sin registro válido: defecto de integración
			# (contrato §2, "no es una razón para omitirla silenciosamente").
			# Cancelar explícitamente libera la propuesta pendiente en vez de
			# dejar la sesión bloqueada sobre ese carril para el resto de la
			# partida; el spawn visible ya ocurrió y no se revierte.
			push_warning("CommanderSession.register_spawn() rechazó una activación WAVE real; " +
				"se cancela la propuesta pendiente (contrato §2).")
			_commander_session.cancel_proposal(decision.token)

	if _board_config != null:
		_next_lane = (_next_lane + 1) % _board_config.home_cells.size()

	if not _pending_spawns.is_empty():
		_spawn_timer.start(next.interval_after)


## Contexto público del comandante para el WAVE que se está a punto de
## activar (contrato §1/§2): oleada/rol vigentes y estado real del tablero,
## calculados antes de que el nuevo enemigo exista.
func _commander_snapshot() -> Dictionary:
	var wave: WaveData = WaveManager.get_current_wave()
	var wave_number: int = wave.wave_number if wave != null else 0
	var role := "A"
	if wave != null and not wave.spawn_entries.is_empty():
		var first_stats: EnemyStats = wave.spawn_entries[0].enemy_stats
		# Mismo criterio canónico que `CommanderMemoryStore._fingerprint()`
		# (`core/commander_memory_store.gd`): un asaltante sin fusil
		# funcional es "A", cualquier otro perfil con fusil real es "R".
		if first_stats != null and first_stats.rifle_range > 0.0 \
				and first_stats.rifle_damage > 0 and first_stats.rifle_interval > 0.0:
			role = "R"
	var lane_count: int = _board_config.home_cells.size()
	return {
		"wave_number": wave_number, "role": role,
		"defenders": _commander_defenders(lane_count),
		"lane_loads": _commander_lane_loads(lane_count),
	}


## Estado real observable de cada defensor (contrato §1, "procedentes del
## estado público del actor") — reutiliza `Soldado.get_reload_state()` (ya
## expone exactamente `lane_id`/`alive`/`movement_state`/`ammo`/`mode`, sin
## selección de trinchera del jugador, FR-005) para cada celda hogar ocupada.
## Sin `_board_manager` inyectado (pruebas de este nodo sin tablero) o celda
## libre, reporta un defensor "empty" (`alive = false`) en esa posición.
func _commander_defenders(lane_count: int) -> Array:
	var defenders: Array = []
	for lane: int in range(lane_count):
		var occupant: Node = null
		if _board_manager != null:
			occupant = _board_manager.get_occupant(_board_config.home_cells[lane])
		if occupant is Soldado:
			var state: Dictionary = (occupant as Soldado).get_reload_state()
			defenders.append({
				"lane_id": lane, "alive": state.alive,
				"movement_state": state.movement_state,
				"ammo": state.ammo, "mode": state.mode,
			})
		else:
			defenders.append({
				"lane_id": lane, "alive": false,
				"movement_state": Soldado.MovementState.DEAD,
				"ammo": 0, "mode": Soldado.SoldierMode.RIFLE,
			})
	return defenders


## Carga observada por carril (contrato §1, campo `lane_loads`): cuenta de
## enemigos WAVE activos de este mismo pool, excluyendo explícitamente el
## INITIAL (independiente del comandante, FR-001) y cualquier instancia ya
## retirada (`Enemigo.is_targetable()`), antes de añadir el nuevo enemigo de
## este spawn a esa cuenta.
func _commander_lane_loads(lane_count: int) -> Array:
	var counts: Array = []
	counts.resize(lane_count)
	counts.fill(0)
	for actor: Node in _enemy_pool.get_children():
		var enemy := actor as Enemigo
		if enemy == null or not enemy.is_targetable() or enemy.spawn_origin != Enemigo.SpawnOrigin.WAVE:
			continue
		if enemy.lane_id >= 0 and enemy.lane_id < lane_count:
			counts[enemy.lane_id] += 1
	return counts


## Se ejecuta una única vez por instancia física nueva del pool (nunca en
## cada `acquire()`/`release()` de una instancia ya existente — ver cabecera
## de esta clase). Registra el pool en la instancia (`Enemigo.set_pool()`,
## resuelve el conflicto `_die()`/`queue_free()` vs `release()`) y conecta
## `enemy_defeated` una sola vez para toda la vida de esa instancia.
func _on_enemy_pool_instance_created(instance: Node) -> void:
	var enemy := instance as Enemigo
	if _board_config != null:
		enemy.board_config = _board_config
	enemy.set_pool(_enemy_pool)
	enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))
	if _combat_visual_effects != null:
		_combat_visual_effects.register_actor(enemy)
	if _combat_audio != null:
		_combat_audio.register_actor(enemy)


## FR-012/T042: por cada enemigo derrotado que este spawner instanció,
## notifica a `WaveManager` (única fuente de verdad de progreso de oleada,
## `docs/ARCHITECTURE.md` §4.1) y recicla la instancia al pool en vez de
## dejar que se autodestruya — ver conflicto documentado en la cabecera de
## esta clase y en `enemigo.gd`.
func _on_enemy_defeated(_ammo_dropped: int, _position: Vector2, enemy: Enemigo) -> void:
	if _closing:
		return
	var origin := enemy.get_defeat_origin()
	if origin == Enemigo.SpawnOrigin.WAVE:
		WaveManager.notify_enemy_defeated()
	_enemy_pool.release(enemy)
