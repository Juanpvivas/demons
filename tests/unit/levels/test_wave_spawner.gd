extends GutTest
## Test de `scenes/levels/wave_spawner.gd` (T042, `spec.md` User Story 3,
## FR-012: "El sistema DEBE generar oleadas sucesivas de enemigos... vía
## ObjectPool"). `tests/unit/systems/test_wave_manager.gd` ya cubre la
## SECUENCIA entre oleadas (cuándo empieza/termina una oleada) usando una
## instancia local de `WaveManager` sin instanciar un solo enemigo real;
## `tests/unit/systems/test_wave_data_resources.gd` cubre que la dificultad
## de los `.tres` de producción aumenta. Ninguno de los dos ejercita la pieza
## que agrega esta tarea: que `WaveSpawner` efectivamente INSTANCIE esos
## enemigos (composición/cantidad exacta de cada `WaveSpawnEntry`, con sus
## stats y posición correctos) vía `ObjectPool`, y que los recicle en vez de
## destruirlos al morir — cobertura obligatoria de "generación de oleadas"
## (`constitution.md` Principio II) que sin este archivo queda sin probar.
##
## A diferencia de `test_wave_manager.gd` (que crea una instancia LOCAL de
## `WaveManager` vía `load().new()` para no depender del autoload real),
## `WaveSpawner._ready()` se conecta directamente al autoload real
## `WaveManager` (`WaveManager.wave_started.connect(...)`, ver cabecera de
## `wave_spawner.gd`) — no hay forma de inyectar un doble sin cambiar esa
## clase, así que estos tests usan el autoload real, igual que
## `tests/unit/levels/test_nivel_montecalvo.gd` ya hace al cargar el nivel
## completo. Cada test dispara su propio `WaveManager.start_waves([...])`,
## que siempre resetea el estado del autoload de punta a punta (verificado
## en `wave_manager.gd`), así que no hay dependencia de orden entre tests de
## este archivo ni con otros archivos que también usan el autoload real
## (confirmado corriendo la suite completa en ambos órdenes).
##
## Nota de timing: NO se usa `wait_seconds()` para simular el paso del
## `Timer` interno del `spawn_interval` de producción (podría ser lento/poco
## determinista con valores reales de `.tres` de hasta 10s) — en su lugar,
## cada `WaveSpawnEntry` de prueba usa el `spawn_interval` mínimo permitido
## por su `@export_range` (0.05s) y se espera con margen generoso vía
## `wait_seconds()`, igual que la duración de otros tests de esta suite que
## dependen de tiempo real (`test_hud.gd` usa hasta 2.5s reales).

const ENEMY_SCENE_PATH := "res://scenes/enemies/EnemigoBase.tscn"
const SPAWN_POSITION := Vector2(300.0, 20.0)

var _spawner: WaveSpawner


func before_each() -> void:
	_spawner = WaveSpawner.new()
	add_child_autofree(_spawner)
	_spawner.setup(load(ENEMY_SCENE_PATH), 0, SPAWN_POSITION)


## Construye un WaveSpawnEntry de prueba con spawn_interval mínimo (0.05s,
## el piso permitido por su @export_range) para que los tests de este
## archivo no dependan de esperar los intervalos reales (hasta 10s) de los
## `.tres` de producción.
func _build_entry(stats: EnemyStats, count: int) -> WaveSpawnEntry:
	var entry := WaveSpawnEntry.new()
	entry.enemy_stats = stats
	entry.count = count
	entry.spawn_interval = 0.05
	return entry


func _build_wave(wave_number: int, entries: Array[WaveSpawnEntry]) -> WaveData:
	var wave := WaveData.new()
	wave.wave_number = wave_number
	wave.spawn_entries = entries
	return wave


## --- Ningún spawn ocurre de forma síncrona/inmediata (spec.md User Story 3:
## una oleada "llega" progresivamente, no de golpe en el mismo frame) ---

func test_wave_started_does_not_spawn_any_enemy_synchronously() -> void:
	# Given: una oleada con un enemigo pendiente
	var stats := EnemyStats.new()
	var wave := _build_wave(1, [_build_entry(stats, 1)])

	# When: arranca la oleada (dispara wave_started, que WaveSpawner escucha)
	WaveManager.start_waves([wave])

	# Then: en el mismo frame, todavía no se instanció ningún enemigo — el
	# primer spawn también espera su spawn_interval (ver cabecera de
	# `_on_spawn_timer_timeout()` en wave_spawner.gd)
	assert_eq(
		_spawner._enemy_pool.in_use_count(), 0,
		"WaveSpawner no debe instanciar ningún enemigo en el mismo frame en que arranca la oleada"
	)


## --- Composición/cantidad exacta de la oleada (FR-012) ---

func test_wave_spawns_exactly_the_total_enemies_of_all_spawn_entries_combined() -> void:
	# Given: una oleada con DOS entradas de spawn (2 tipos de enemigo
	# distintos), 2 + 3 = 5 enemigos en total
	var stats_a := EnemyStats.new()
	var stats_b := EnemyStats.new()
	var wave := _build_wave(1, [_build_entry(stats_a, 2), _build_entry(stats_b, 3)])

	# When: arranca la oleada y transcurre tiempo real suficiente para que
	# los 5 spawns, espaciados 0.05s cada uno, se completen
	WaveManager.start_waves([wave])
	await wait_seconds(1.0, "tiempo suficiente para los 5 spawns de 0.05s cada uno")

	# Then: se instanciaron exactamente los 5 enemigos de la oleada, ni uno menos ni uno de más
	assert_eq(
		_spawner._enemy_pool.in_use_count(), 5,
		"WaveSpawner debe instanciar exactamente la suma de todos los WaveSpawnEntry.count de la oleada activa"
	)

	# Then: no aparecen enemigos adicionales fantasma tras esperar de más
	await wait_seconds(0.3, "margen adicional para detectar sobre-spawn")
	assert_eq(
		_spawner._enemy_pool.in_use_count(), 5,
		"WaveSpawner no debe seguir spawneando enemigos una vez agotada la cola de la oleada"
	)


## --- Cada enemigo recibe el EnemyStats y la posición de su propia entrada ---

func test_spawned_enemies_receive_the_enemy_stats_of_their_own_spawn_entry() -> void:
	# Given: una oleada con dos tipos de enemigo con stats claramente distintos
	var stats_a := EnemyStats.new()
	stats_a.max_health = 15
	var stats_b := EnemyStats.new()
	stats_b.max_health = 40
	var wave := _build_wave(1, [_build_entry(stats_a, 1), _build_entry(stats_b, 1)])

	# When: se completan ambos spawns
	WaveManager.start_waves([wave])
	await wait_seconds(0.5, "tiempo suficiente para los 2 spawns de 0.05s cada uno")

	# Then: el primer enemigo instanciado (orden de la cola, entrada A antes
	# que B) recibió stats_a, y el segundo recibió stats_b
	var spawned: Array = _spawner._enemy_pool.get_children()
	assert_eq(spawned.size(), 2, "precondición del test: deben existir exactamente 2 instancias físicas")
	var first_enemy: Enemigo = spawned[0]
	var second_enemy: Enemigo = spawned[1]
	assert_eq(
		first_enemy.stats, stats_a,
		"el primer enemigo de la cola debe recibir el EnemyStats de la primera WaveSpawnEntry"
	)
	assert_eq(
		second_enemy.stats, stats_b,
		"el segundo enemigo de la cola debe recibir el EnemyStats de la segunda WaveSpawnEntry"
	)


func test_spawned_enemy_appears_at_the_configured_spawn_position() -> void:
	# Given/When: una oleada de un solo enemigo. Espera el mínimo margen
	# necesario para el único spawn (0.05s de spawn_interval) y no más: el
	# enemigo avanza en +Y por su cuenta apenas existe
	# (`scenes/enemies/enemigo.gd._physics_process()`), así que esperar de
	# más movería su posición y este test dejaría de medir el punto de
	# APARICIÓN para pasar a medir cuánto avanzó, contaminando la aserción.
	var wave := _build_wave(1, [_build_entry(EnemyStats.new(), 1)])
	WaveManager.start_waves([wave])
	await wait_seconds(0.06, "margen mínimo para el único spawn de 0.05s")

	# Then: aparece en la posición de mundo fijada en setup(), con una
	# tolerancia acorde al avance máximo posible en ese margen mínimo
	# (move_speed de producción por defecto: 60px/s * ~0.01s adicional < 1px)
	var enemy: Enemigo = _spawner._enemy_pool.get_children()[0]
	assert_almost_eq(
		enemy.global_position, SPAWN_POSITION, Vector2(2.0, 2.0),
		"todo enemigo de WaveSpawner debe aparecer en el spawn_position configurado en setup()"
	)


## --- Enemigo derrotado: notifica a WaveManager y recicla en vez de destruir ---

func test_defeating_the_spawned_enemy_notifies_wave_manager() -> void:
	# Given: una oleada de un único enemigo, ya spawneado
	var wave := _build_wave(7, [_build_entry(EnemyStats.new(), 1)])
	WaveManager.start_waves([wave])
	await wait_seconds(0.3, "tiempo suficiente para el único spawn de 0.05s")
	var enemy: Enemigo = _spawner._enemy_pool.get_children()[0]
	watch_signals(WaveManager)

	# When: el enemigo instanciado por WaveSpawner es derrotado
	enemy.take_damage(9999)

	# Then: WaveManager fue notificado y, al ser el único enemigo de la
	# única oleada, la considera completa (generación de oleadas, cobertura
	# obligatoria de constitution.md Principio II)
	assert_signal_emitted_with_parameters(WaveManager, "wave_completed", [7])


func test_defeating_the_spawned_enemy_recycles_it_into_the_pool_instead_of_destroying_it() -> void:
	# Given: una oleada de un único enemigo, ya spawneado
	var wave := _build_wave(1, [_build_entry(EnemyStats.new(), 1)])
	WaveManager.start_waves([wave])
	await wait_seconds(0.3, "tiempo suficiente para el único spawn de 0.05s")
	var enemy: Enemigo = _spawner._enemy_pool.get_children()[0]

	# When: el enemigo es derrotado
	enemy.take_damage(9999)

	# Then: a diferencia del Enemigo colocado a mano en Nivel_MonteCalvo.tscn
	# (sin pool, T027), esta instancia NO se autodestruye — sigue siendo un
	# nodo válido, devuelto al pool para un futuro acquire() (optimización de
	# rendimiento, constitution.md Principio IV)
	assert_true(
		is_instance_valid(enemy),
		"un enemigo instanciado por WaveSpawner (con pool asignado) no debe ser destruido al morir"
	)
	assert_eq(
		_spawner._enemy_pool.in_use_count(), 0,
		"el enemigo derrotado ya no debe contar como 'en uso' del pool"
	)
	assert_eq(
		_spawner._enemy_pool.available_count(), 1,
		"el enemigo derrotado debe quedar disponible en el pool para un futuro acquire()"
	)


## --- Edge case: oleada sin ninguna WaveSpawnEntry (WaveManager ya cubre el
## caso de secuencia vacía; este es el caso de una oleada individual mal
## configurada, documentado explícitamente en la cabecera de
## `_on_wave_started()` de wave_spawner.gd) ---

func test_wave_with_no_spawn_entries_spawns_nothing_and_does_not_error() -> void:
	# Given/When: una oleada sin ninguna WaveSpawnEntry
	var empty_wave := _build_wave(1, [])
	WaveManager.start_waves([empty_wave])
	await wait_seconds(0.3, "margen para confirmar que nada se instancia con el tiempo")

	# Then: no se instancia ningún enemigo, y no se produjo ningún error
	# (verificado implícitamente por GUT: un error no capturado marca el test
	# como fallido)
	assert_eq(
		_spawner._enemy_pool.in_use_count(), 0,
		"una WaveData sin spawn_entries no debe instanciar ningún enemigo"
	)
