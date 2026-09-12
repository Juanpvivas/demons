## Script del nivel `Nivel_MonteCalvo.tscn` (`docs/ARCHITECTURE.md` §5).
##
## T035 (`spec.md` User Story 2, Acceptance Scenario 3 / FR-001 / FR-010):
## interacción de despliegue de un soldado NUEVO en una celda vacía del
## tablero a partir de un click/tap del jugador. Flujo:
##
##   1. El jugador hace click/tap sobre "Tablero" — acción `select_cell` del
##      `InputMap` (mouse + touch, sin tecla hardcodeada, ya configurada en
##      T003; `docs/ARCHITECTURE.md` §7).
##   2. La posición de pantalla del evento se convierte a coordenada de celda
##      vía `Tablero.local_to_map()`.
##   3. Si la celda NO está libre (`BoardManager.is_cell_free()` → `false`),
##      no se hace nada — otra interacción (ej. recolectar una `AmmoPickup`
##      encima de esa celda) ya consumió su propio click por separado, ver
##      nota en `_unhandled_input()`.
##   4. Si está libre, se intenta gastar
##      `EconomyManager.try_spend_ammo(soldado_deploy_stats.deploy_ammo_cost)`
##      (mismo costo que una recarga completa — `data-model.md`, `spec.md`
##      Assumptions). Si no hay fondos suficientes, `EconomyManager` ya
##      emitió `deploy_or_reload_rejected` (FR-011); no hay feedback visual
##      todavía porque el HUD (T036) no existe — no se hace nada más aquí.
##   5. Si el gasto tiene éxito, se instancia `Soldado.tscn` centrado en esa
##      celda (`Tablero.map_to_local()`) y se registra como ocupante en
##      `BoardManager` (FR-001).
##
## Nota sobre el conflicto con `AmmoPickup` (`scenes/levels/ammo_pickup.gd`):
## las pickups son `Area2D` con `input_event` conectado, que Godot resuelve
## mediante "physics picking" ANTES de que el evento llegue a
## `_unhandled_input()` de este nivel. Cuando el picking encuentra un
## `CollisionObject2D` que recibe el evento, el motor lo marca como
## manejado automáticamente — por eso un click sobre una pickup nunca
## dispara además la lógica de despliegue de abajo, aunque `select_cell` y
## `collect_pickup` compartan el mismo evento físico (mismo botón/touch) en
## el `InputMap`. No se requiere ninguna guarda adicional en este script.
##
## No declara `class_name`: es un nivel concreto (una única instancia
## jugable), no un tipo reutilizable — a diferencia de `AmmoPickup`
## (`scenes/levels/ammo_pickup.gd`), que sí lo declara por ser una escena
## instanciada muchas veces desde otro script (`enemigo.gd`).
##
## T042 (`spec.md` User Story 3, FR-012): este nivel arranca su propia
## secuencia de oleadas en `_ready()` (`WaveManager.start_waves(waves)`) y
## crea un `WaveSpawner` (`scenes/levels/wave_spawner.gd`) que reacciona a
## `WaveManager.wave_started` instanciando los enemigos de cada oleada vía
## `ObjectPool` — ver la cabecera de `wave_spawner.gd` para el diseño
## completo (incluye la resolución del conflicto entre `Enemigo._die()` y
## el reciclado de `ObjectPool.release()`).
extends Node2D

## Escena a instanciar por cada nuevo despliegue (FR-001/FR-010).
## Exportado (no hardcodeado en la lógica) para que diseño pueda apuntar a
## una variante distinta de soldado sin tocar este script.
@export var soldado_scene: PackedScene = preload("res://scenes/units/Soldado.tscn")

## `UnitStats` del "soldado desplegable estándar" (T017): fuente única de
## verdad tanto para el costo de despliegue (`deploy_ammo_cost`) que se
## valida ANTES de instanciar, como para los stats que se asignan a la
## instancia nueva — evita que ambos puedan quedar desincronizados si en el
## futuro `Soldado.tscn` cambia su `stats` embebido por defecto.
@export var soldado_deploy_stats: UnitStats = preload("res://resources/units/soldado_base_stats.tres")

## T042: secuencia de oleadas de este nivel, en orden — fuente única de
## verdad pasada a `WaveManager.start_waves()`. Exportado (no hardcodeado,
## `constitution.md` Principio I: el balance vive en `Resource`) para que
## diseño pueda reordenar/sustituir oleadas sin tocar este script,
## precargando por defecto los 10 `WaveData` de producción de este nivel
## (`resources/waves/nivel_montecalvo_oleada_0N.tres`, T041) — mismo patrón
## que `soldado_scene`/`soldado_deploy_stats` arriba (`preload()` como
## default editable).
@export var waves: Array[WaveData] = [
	preload("res://resources/waves/nivel_montecalvo_oleada_01.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_02.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_03.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_04.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_05.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_06.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_07.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_08.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_09.tres"),
	preload("res://resources/waves/nivel_montecalvo_oleada_10.tres"),
]

## T042: escena de enemigo que recicla el `ObjectPool` interno de
## `WaveSpawner` (`docs/ARCHITECTURE.md` §4.5). Todas las oleadas de este
## nivel instancian el mismo tipo de nodo (`EnemigoBase.tscn`) — el
## `EnemyStats` concreto de cada enemigo lo decide cada `WaveSpawnEntry` de
## la oleada activa, no la escena en sí.
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/EnemigoBase.tscn")

## T042: único punto de mundo donde aparecen los enemigos de todas las
## oleadas de `WaveSpawner` — decisión de menor complejidad válida para el
## MVP de un solo carril recto (mismo supuesto ya documentado en la
## cabecera de `scenes/enemies/enemigo.gd`: avance en `+Y`, sin diagonales
## propias del enemigo), en vez de introducir uno o más `Marker2D` nuevos
## que este alcance no necesita todavía. Coincide a propósito con la
## posición del `Enemigo` colocado a mano en esta escena para el
## Independent Test de US1/US2 (T027) — mismo carril, mismo punto de
## aparición — pero es un valor propio, independiente de ese nodo: si ese
## `Enemigo` de prueba se quitara de la escena más adelante, las oleadas de
## `WaveSpawner` seguirían apareciendo en el mismo lugar sin cambios aquí.
@export var wave_spawn_position: Vector2 = Vector2(576, 50)

## Tamaño de pre-población del `ObjectPool` de enemigos de `WaveSpawner`:
## una optimización de rendimiento para evitar instanciar en el primer uso
## de cada oleada (`constitution.md` Principio IV), no un límite —
## `ObjectPool` sigue creciendo bajo demanda si una oleada necesita más
## enemigos vivos simultáneamente que este valor (`core/object_pool.gd`).
## No es dato de balance (no afecta gameplay, solo cuándo ocurre el costo
## de instanciación), así que vive como constante de implementación, no
## como `@export`/`Resource`.
const _ENEMY_POOL_INITIAL_SIZE := 10

## Ocupación de celdas del tablero de este nivel (`core/board_manager.gd`,
## `research.md` §5). No es autoload: el estado de ocupación es por-nivel.
var _board_manager := BoardManager.new()

## T042: instancia única de `WaveSpawner` de este nivel (ver
## `scenes/levels/wave_spawner.gd`). Creada por código, no como nodo
## hijo en el `.tscn`, mismo patrón ya usado en este script para
## `_board_manager` — ninguno de los dos representa una escena visual
## propia, son utilidades de lógica que este nivel posee.
var _wave_spawner := WaveSpawner.new()

@onready var _tablero: TileMap = $Tablero


func _ready() -> void:
	# El soldado colocado a mano en la escena (T027, setup mínimo del nivel
	# para el Independent Test de US1) también debe contar como ocupante de
	# su celda — de lo contrario un click sobre esa misma celda desplegaría
	# un segundo soldado encima del ya existente.
	var soldado_inicial: Node2D = get_node_or_null("Soldado")
	if soldado_inicial != null:
		_board_manager.occupy_cell(_world_to_cell(soldado_inicial.global_position), soldado_inicial)

	# T042: arranca la secuencia de oleadas de este nivel. El `Enemigo`
	# colocado a mano en la escena (T027, Independent Test de US1/US2) es
	# independiente de esto — nunca pasa por `set_pool()`, así que conserva
	# su `queue_free()` original sin conflicto con las instancias pooleadas
	# que `WaveSpawner` va a crear.
	add_child(_wave_spawner)
	_wave_spawner.setup(enemy_scene, _ENEMY_POOL_INITIAL_SIZE, wave_spawn_position)
	WaveManager.start_waves(waves)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("select_cell"):
		return

	# `InputEvent` base no expone `.position` — se castea explícitamente al
	# subtipo concreto (mouse o touch; `select_cell`, T003, no mapea ningún
	# otro tipo de evento) antes de leerlo, en vez de acceder al miembro
	# sobre el tipo estático `InputEvent` del parámetro.
	var screen_position: Vector2
	if event is InputEventMouseButton:
		screen_position = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		screen_position = (event as InputEventScreenTouch).position
	else:
		return

	var cell := _world_to_cell(_screen_to_world(screen_position))
	_try_deploy_soldado(cell)


## Intenta desplegar un soldado nuevo en `cell` (FR-001/FR-010). No hace
## nada si la celda está ocupada o si la munición recolectada es
## insuficiente (en ese caso `EconomyManager` ya avisó vía
## `deploy_or_reload_rejected`, FR-011).
func _try_deploy_soldado(cell: Vector2i) -> void:
	if not _board_manager.is_cell_free(cell):
		return
	if not EconomyManager.try_spend_ammo(soldado_deploy_stats.deploy_ammo_cost):
		return

	var nuevo_soldado: Soldado = soldado_scene.instantiate()
	nuevo_soldado.stats = soldado_deploy_stats
	nuevo_soldado.global_position = _tablero.to_global(_tablero.map_to_local(cell))
	add_child(nuevo_soldado)
	_board_manager.occupy_cell(cell, nuevo_soldado)


## Convierte la posición de pantalla de un evento de input (mouse o touch,
## ambas en coordenadas de viewport) a posición de mundo 2D, sin depender
## de `get_global_mouse_position()` (que solo refleja al mouse real, no a
## eventos de touch emulados).
func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * screen_position


## Traduce una posición de mundo a coordenada de celda de "Tablero"
## (`Vector2i`), la unidad que consume `BoardManager`.
func _world_to_cell(world_position: Vector2) -> Vector2i:
	return _tablero.local_to_map(_tablero.to_local(world_position))
