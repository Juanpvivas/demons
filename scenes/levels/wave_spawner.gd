## `WaveSpawner`: instancia los enemigos de la oleada activa vía `ObjectPool`
## y notifica a `WaveManager` cada eliminación (T042, `spec.md` User Story 3
## / FR-012). No decide "cuándo" hay una oleada nueva ni cuenta cuántos
## enemigos la componen (eso es responsabilidad exclusiva de `WaveManager`,
## `docs/ARCHITECTURE.md` §4.1 — "autoload orquestador no instancia ni
## temporiza"): este nodo solo reacciona a `WaveManager.wave_started`,
## consume `WaveManager.get_current_wave().spawn_entries`, y avisa con
## `WaveManager.notify_enemy_defeated()` una vez por cada enemigo derrotado
## que él mismo instanció.
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
## **Punto de spawn único**: recibe una sola posición de mundo en `setup()`
## y la reutiliza para todos los spawns de todas las oleadas — decisión de
## menor complejidad válida para el MVP de un solo carril recto, mismo
## supuesto ya documentado en la cabecera de `scenes/enemies/enemigo.gd`
## (eje de avance `+Y`, sin diagonales propias del enemigo). Si un nivel
## futuro necesita múltiples carriles, este método puede evolucionar a
## recibir un `Array[Vector2]` sin cambiar el resto del contrato.
##
## **Conflicto `ObjectPool.release()` vs `Enemigo._die()` — resuelto**:
## `Enemigo._die()` originalmente llamaba `queue_free()` de forma
## incondicional al morir, lo cual destruiría cualquier instancia pooleada
## que este nodo creyera todavía disponible para un futuro `acquire()`. Se
## resolvió agregando `Enemigo.set_pool()`/`_pool` (ver cabecera de
## `enemigo.gd`): cuando una instancia pertenece a un pool, `_die()` ya NO
## se autodestruye — este `WaveSpawner` es quien, al recibir la señal
## `enemy_defeated` de esa instancia, llama `_enemy_pool.release()` en su
## lugar. El `Enemigo` colocado a mano en `Nivel_MonteCalvo.tscn` para el
## Independent Test de US1/US2 (T027) nunca pasa por `set_pool()`, así que
## conserva el `queue_free()` original sin cambios de comportamiento.
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

## Punto de mundo donde aparecen todos los enemigos de este nivel (ver
## cabecera — un solo carril recto para el MVP).
var _spawn_position: Vector2

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


## Crea y configura el `ObjectPool` de enemigos de este spawner, y fija el
## punto de spawn único a usar para toda oleada futura. Debe llamarse una
## vez desde el nivel dueño (`nivel_monte_calvo.gd`) antes de que
## `WaveManager.start_waves()` dispare el primer `wave_started` — si se
## llamara después, el primer `wave_started` no encontraría `_enemy_pool`
## listo.
func setup(enemy_scene: PackedScene, initial_pool_size: int, spawn_position: Vector2) -> void:
	_spawn_position = spawn_position
	_enemy_pool = ObjectPool.new()
	add_child(_enemy_pool)
	# Conectado ANTES de `setup()` — ver justificación en la cabecera de
	# `_enemy_pool` arriba.
	_enemy_pool.instance_created.connect(_on_enemy_pool_instance_created)
	_enemy_pool.setup(enemy_scene, initial_pool_size)


## Encolado de la nueva oleada activa (aplana `spawn_entries`) y arranque
## del `Timer` para el primer spawn, que espera `spawn_interval` como
## cualquier otro (ver justificación en `_on_spawn_timer_timeout()` de por
## qué NINGÚN spawn, ni siquiera el primero de la oleada, ocurre de forma
## síncrona/inmediata). Un `WaveData` sin `spawn_entries` (caso degenerado,
## ningún `.tres` de producción lo tiene) deja la cola vacía y no spawnea
## nada — no es responsabilidad de este nodo decidir qué pasa con una
## oleada mal configurada, solo no debe fallar.
func _on_wave_started(_wave_number: int) -> void:
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


## Único punto donde se saca un elemento de la cola y se spawnea — **todo**
## spawn, incluido el primero de la oleada, pasa por el `Timer` (nunca se
## spawnea de forma síncrona/inmediata desde `_on_wave_started()`). Esto no
## es solo una elección de ritmo: como este `WaveSpawner` reutiliza un único
## `wave_spawn_position` (`nivel_monte_calvo.gd`) que coincide a propósito
## con la posición del `Enemigo` colocado a mano para el Independent Test de
## US1/US2 (T027), un primer spawn SIN retraso aparecería en el mismo punto
## y el mismo frame que ese enemigo de prueba — un empate exacto de
## posición/tiempo que haría no determinista a qué enemigo bloquea el
## soldado como objetivo (`Soldado._pick_priority_target()` usa `>` estricto
## entre candidatos, así que un empate se resuelve por el orden en que la
## física reporta `body_entered`, no especificado por Godot). Esperar
## siempre al menos un `spawn_interval` antes de cualquier spawn le da al
## enemigo de T027 una ventaja de avance que rompe el empate de forma
## determinista, preservando el comportamiento ya testeado de ese
## Independent Test sin acoplar este spawner a su existencia.
func _on_spawn_timer_timeout() -> void:
	if _pending_spawns.is_empty():
		return

	var next: _PendingSpawn = _pending_spawns.pop_front()
	var enemy: Enemigo = _enemy_pool.acquire()
	# `ObjectPool.acquire()` no admite argumentos (`docs/ARCHITECTURE.md`
	# §4.5): la instancia devuelta puede conservar el `stats`/salud de un
	# uso anterior (o el default embebido en `EnemigoBase.tscn` en su
	# primera creación), nunca el `EnemyStats` correcto de esta
	# `WaveSpawnEntry`. En vez de depender del hook automático
	# `on_pool_acquired()` (que correría ANTES de que este método pudiera
	# asignar el `stats` correcto — ver orden interno de
	# `ObjectPool.acquire()`), se reasigna todo explícitamente aquí vía
	# `prepare_for_spawn()`, después de `acquire()`.
	enemy.prepare_for_spawn(next.enemy_stats, _spawn_position)

	if not _pending_spawns.is_empty():
		_spawn_timer.start(next.interval_after)


## Se ejecuta una única vez por instancia física nueva del pool (nunca en
## cada `acquire()`/`release()` de una instancia ya existente — ver cabecera
## de esta clase). Registra el pool en la instancia (`Enemigo.set_pool()`,
## resuelve el conflicto `_die()`/`queue_free()` vs `release()`) y conecta
## `enemy_defeated` una sola vez para toda la vida de esa instancia.
func _on_enemy_pool_instance_created(instance: Node) -> void:
	var enemy := instance as Enemigo
	enemy.set_pool(_enemy_pool)
	enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))


## FR-012/T042: por cada enemigo derrotado que este spawner instanció,
## notifica a `WaveManager` (única fuente de verdad de progreso de oleada,
## `docs/ARCHITECTURE.md` §4.1) y recicla la instancia al pool en vez de
## dejar que se autodestruya — ver conflicto documentado en la cabecera de
## esta clase y en `enemigo.gd`.
func _on_enemy_defeated(_ammo_dropped: int, _position: Vector2, enemy: Enemigo) -> void:
	WaveManager.notify_enemy_defeated()
	_enemy_pool.release(enemy)
