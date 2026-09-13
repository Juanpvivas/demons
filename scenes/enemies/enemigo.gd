## Enemigo que avanza en línea recta hacia la posición defendida y puede ser
## eliminado por el `Soldado` (fusil o machete), según el contrato asumido y
## documentado en la cabecera de `scenes/units/soldado.gd` (T017-T024):
##
## - Pertenece al grupo `"enemies"` (`add_to_group("enemies")` en `_ready()`),
##   usado por `Soldado` para filtrar los cuerpos detectados por sus
##   `Area2D` "DeteccionRango"/"RangoMelee".
## - Expone `take_damage(amount: int) -> bool`, que aplica el daño a
##   `_current_health` y retorna `true` únicamente en la llamada que deja la
##   salud en 0 o menos (la que lo elimina), `false` en cualquier otro caso
##   (incluye llamadas defensivas sobre un enemigo ya eliminado, mientras su
##   `queue_free()` todavía no se procesó).
## - Expone `get_advance_progress() -> float` para que `Soldado` desempate
##   prioridad de objetivo entre varios candidatos (`spec.md` Assumptions):
##   mayor valor = más avanzado hacia la posición defendida.
##
## `CharacterBody2D` raíz (`docs/ARCHITECTURE.md` §5) — a diferencia de
## `Soldado` (`StaticBody2D`, estacionario), el enemigo sí se mueve con
## `move_and_slide()`.
##
## **Eje de avance asumido para este MVP** (un solo carril recto, sin
## soporte de diagonales propias del enemigo — eso lo resuelve la detección
## del `Soldado`, no el movimiento del `Enemigo`): el enemigo avanza en línea
## recta a lo largo del eje `+Y` (hacia abajo en coordenadas de Godot), que
## es el mismo sentido en el que `Soldado.tscn` posiciona su
## "DeteccionRango" por delante de sí (offset `Vector2(0, -144)`, es decir
## por encima/antes en el carril) y su "RangoMelee" más cerca (offset
## `Vector2(0, -32)`). La posición defendida queda más adelante en `+Y` que
## el punto de aparición del enemigo. Si un nivel futuro necesita carriles
## en otra orientación, este supuesto debe revisarse junto con la geometría
## de `Nivel_MonteCalvo.tscn` (T027).
##
## **Integración con `ObjectPool` (T042, `scenes/levels/wave_spawner.gd`)**:
## esta clase admite ser reciclada por un `ObjectPool` en vez de
## instanciarse/destruirse por spawn (`constitution.md` Principio IV) — ver
## `set_pool()`/`prepare_for_spawn()` y la nota dentro de `_die()`. El
## `Enemigo` colocado a mano en `Nivel_MonteCalvo.tscn` para el Independent
## Test de US1/US2 (T027) nunca pasa por un pool y conserva el
## comportamiento original sin cambios (auto-destrucción con `queue_free()`
## al morir).
##
## **Ataque cuerpo a cuerpo contra `Soldado` (T053, `spec.md` Edge Case: "un
## soldado en modo cuerpo a cuerpo es derrotado por los enemigos")**: este
## enemigo detecta a un `Soldado` dentro de su propia `Area2D` "RangoAtaque"
## (mismo patrón `body_entered`/`body_exited` + lista de candidatos que usa
## `Soldado` para "DeteccionRango"/"RangoMelee", `docs/ARCHITECTURE.md` §4.2)
## y le aplica `stats.melee_damage` vía `Soldado.take_damage()` a una cadencia
## fija — ver `_MELEE_ATTACK_INTERVAL`/`_process_melee_attack()` para el
## supuesto de implementación exacto (no es un valor de diseño de `spec.md`
## ni un campo nuevo en `EnemyStats`, fuera del alcance autorizado de esta
## tarea). "RangoAtaque" está posicionada y dimensionada para solaparse con
## "RangoMelee" de `Soldado.tscn` en la franja donde ambos ya se detectan
## mutuamente, así que el intercambio de daño es simétrico: mientras un
## enemigo está lo bastante cerca para que el soldado lo ataque a machete,
## también lo está para atacar al soldado de vuelta.
class_name Enemigo
extends CharacterBody2D

## Grupo que identifica a todo `Enemigo` ante los sistemas de detección de
## `Soldado` (`Soldado.ENEMY_GROUP`, mismo literal).
const ENEMY_GROUP: String = "enemies"

## T032: escena de la pickup de munición que se instancia al morir
## (`_die()`), según `research.md` §3 (recolección explícita por tap/click,
## no por proximidad). Se precarga aquí en vez de vivir como `@export`
## porque toda instancia de `Enemigo` genera el mismo tipo de pickup — solo
## cambia `amount`, tomado de `stats.ammo_drop`.
const _AMMO_PICKUP_SCENE: PackedScene = preload("res://scenes/levels/AmmoPickup.tscn")

## El enemigo fue eliminado (por disparo o por machete). Payload por
## contrato (`contracts/signals.md`): munición que suelta y su posición en
## el momento de morir, para que quien escuche (ej. `EconomyManager`, fuera
## del alcance de esta tarea) pueda generar una pickup en ese punto.
signal enemy_defeated(ammo_dropped: int, position: Vector2)

## T043 (`contracts/signals.md`, FR-013): este enemigo alcanzó la "posición
## defendida" sin haber sido detenido por ningún soldado. No la emite este
## script por sí solo — la detección de la zona vive en el nivel
## (`Nivel_MonteCalvo.tscn`/`nivel_monte_calvo.gd`, `Area2D`
## "PosicionDefendida"), que llama a `notify_reached_defended_position()`
## (ver más abajo) cuando detecta este cuerpo. `GameStateManager` es quien
## debe escuchar esta señal para terminar la partida en derrota (T044, fuera
## del alcance de esta tarea).
signal reached_defended_position

## Molde de datos base/máximos de este enemigo — solo lectura, nunca mutado
## en runtime (`docs/ARCHITECTURE.md` §4.3).
@export var stats: EnemyStats

## Salud actual, runtime. Inicializada desde `stats.max_health` en `_ready()`
## y reinicializada en cada reciclado vía `prepare_for_spawn()` (T042).
var _current_health: int = 0

## T042: `ObjectPool` al que pertenece esta instancia, o `null` si nunca
## pasó por uno (ej. el `Enemigo` colocado a mano en `Nivel_MonteCalvo.tscn`
## para el Independent Test de US1/US2, T027). Determina el destino de
## `_die()` — ver `set_pool()` y el comentario dentro de `_die()` para el
## conflicto real que resuelve entre el `queue_free()` original de esta
## clase y el patrón de reciclado de `ObjectPool` (`WaveSpawner`, T042).
var _pool: ObjectPool = null

## T053: cadencia de ataque cuerpo a cuerpo contra un `Soldado` dentro de
## "RangoAtaque" — **supuesto de implementación**, no un valor de diseño
## definido en `spec.md` ni un campo nuevo en `EnemyStats` (fuera del alcance
## autorizado de esta tarea): ningún campo existente de `EnemyStats`
## representa una cadencia de ataque (`move_speed`, `melee_damage`,
## `ammo_drop`, `max_health`), así que se usa un intervalo fijo de 1 golpe
## por segundo, igual para todo enemigo hasta que el balance exija
## diferenciarlo por tipo.
const _MELEE_ATTACK_INTERVAL: float = 1.0

## Objetivo activo de ataque cuerpo a cuerpo — nunca más de uno a la vez
## (mismo criterio de "sin dividir fuego" que `Soldado._current_melee_target`).
## Tipado como `Node2D`, no `Soldado`, por el mismo motivo ya documentado en
## la cabecera de `soldado.gd` para `_current_target`/`_current_melee_target`:
## evita fricción de tipado estático al filtrar candidatos con `is Soldado`
## dentro de un handler cuyo parámetro llega tipado `Node2D` desde la señal
## `body_entered`/`body_exited` de Godot.
var _melee_target: Node2D = null

## Candidatos (siempre instancias de `Soldado`, filtradas con `is Soldado` en
## `_on_rango_ataque_body_entered()`) actualmente dentro de "RangoAtaque".
var _melee_candidates: Array[Node2D] = []

## Cuenta regresiva hasta el próximo golpe cuerpo a cuerpo. Se reinicia a 0
## al adquirir un objetivo nuevo, para que el primer golpe contra ese
## objetivo sea inmediato (mismo criterio que `Soldado._melee_cooldown`
## arranca en 0.0 en `soldado.gd`).
var _melee_attack_cooldown: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _rango_ataque: Area2D = $RangoAtaque


func _ready() -> void:
	assert(stats != null, "Enemigo requiere un EnemyStats asignado en 'stats'")
	_current_health = stats.max_health
	add_to_group(ENEMY_GROUP)
	# T028: el propio enemigo escucha su señal de muerte para disparar el
	# feedback visual placeholder — mismo patrón de auto-conexión en
	# `_ready()` que `soldado.gd` usa con `ammo_depleted`
	# (`docs/ARCHITECTURE.md` §4.2). `_die()` emite esta señal antes de
	# llamar `queue_free()`, así que el destello se aplica mientras el nodo
	# sigue siendo válido dentro del mismo frame.
	enemy_defeated.connect(_on_enemy_defeated_visual)
	# T053: mismo patrón de conexión de `Area2D` en `_ready()` que usa
	# `soldado.gd` para "DeteccionRango"/"RangoMelee".
	_rango_ataque.body_entered.connect(_on_rango_ataque_body_entered)
	_rango_ataque.body_exited.connect(_on_rango_ataque_body_exited)


func _physics_process(delta: float) -> void:
	velocity = Vector2(0.0, stats.move_speed)
	move_and_slide()
	_process_melee_attack(delta)


## Aplica `amount` de daño y retorna `true` únicamente si esta llamada dejó
## la salud en 0 o menos (contrato asumido por `soldado.gd`, usado para
## decidir si esa eliminación suma moral — FR-006). Defensivo ante llamadas
## repetidas sobre un enemigo ya eliminado (su `queue_free()` es diferido,
## no inmediato).
func take_damage(amount: int) -> bool:
	if _current_health <= 0:
		return false
	_current_health -= amount
	if _current_health <= 0:
		_die()
		return true
	# T028: destello de impacto no letal — llamada directa (no señal, no hay
	# contrato de `contracts/signals.md` para "golpe recibido"), inocua para
	# los tests existentes que solo observan `take_damage`/`enemy_defeated`.
	_flash_hit()
	return false


## T053: mientras este enemigo tiene un `Soldado` activo dentro de
## "RangoAtaque", lo ataca con `stats.melee_damage` a la cadencia fija de
## `_MELEE_ATTACK_INTERVAL` (`spec.md` Edge Case: "un soldado en modo cuerpo
## a cuerpo es derrotado por los enemigos"). Mismo patrón de cooldown por
## acumulador en `_physics_process` que usa `Soldado._process_melee()`.
func _process_melee_attack(delta: float) -> void:
	if _melee_target == null:
		return
	if not is_instance_valid(_melee_target):
		_remove_melee_candidate(_melee_target)
		return
	_melee_attack_cooldown -= delta
	if _melee_attack_cooldown > 0.0:
		return
	# Mismo despacho dinámico que `soldado.gd` usa para atacar a `Enemigo` —
	# ver el TODO de su cabecera para el motivo (tipado `Node2D`, no
	# `Soldado`, evita la fricción de tipado estático explicada arriba).
	_melee_target.call("take_damage", stats.melee_damage)
	_melee_attack_cooldown = _MELEE_ATTACK_INTERVAL


## Entra un `Soldado` nuevo en "RangoAtaque" — solo se adquiere como objetivo
## si no hay uno activo (misma regla de "sin dividir fuego" que
## `Soldado._on_rango_melee_body_entered()`).
func _on_rango_ataque_body_entered(body: Node2D) -> void:
	if not (body is Soldado) or _melee_candidates.has(body):
		return
	_melee_candidates.append(body)
	if _melee_target == null:
		_recompute_melee_target()


func _on_rango_ataque_body_exited(body: Node2D) -> void:
	if not _melee_candidates.has(body):
		return
	_remove_melee_candidate(body)


func _remove_melee_candidate(body: Node2D) -> void:
	_melee_candidates.erase(body)
	if body == _melee_target:
		_melee_target = null
		_recompute_melee_target()


## Recalcula el objetivo activo de "RangoAtaque" — el primer candidato válido
## de la lista (a diferencia de `Soldado._pick_priority_target()`, no hay
## noción de "más avanzado" que desempatar aquí: en la práctica, el grid del
## tablero nunca permite más de un `Soldado` simultáneo dentro de esta
## `Area2D`, tan pequeña como "RangoMelee" de `Soldado.tscn`). Reinicia el
## cooldown a 0 para que el primer golpe contra el objetivo nuevo sea
## inmediato.
func _recompute_melee_target() -> void:
	_melee_target = null
	for candidate in _melee_candidates:
		if is_instance_valid(candidate):
			_melee_target = candidate
			break
	_melee_attack_cooldown = 0.0


## T042: registra el `ObjectPool` dueño de esta instancia. Llamado
## exactamente una vez por instancia física, no en cada spawn — ver
## `WaveSpawner._on_enemy_pool_instance_created()`, que escucha
## `ObjectPool.instance_created` (emitida solo cuando el pool crea una
## instancia nueva, nunca en cada `acquire()`/`release()` de una ya
## existente).
func set_pool(pool: ObjectPool) -> void:
	_pool = pool


## T042: (re)activa esta instancia para un nuevo spawn. Llamado por
## `WaveSpawner` inmediatamente después de `ObjectPool.acquire()` en vez de
## depender del hook automático `on_pool_acquired()`, porque
## `ObjectPool.acquire()` no admite argumentos: `on_pool_acquired()` se
## ejecutaría ANTES de que el llamador pudiera asignar el `stats` correcto
## de la `WaveSpawnEntry` que se está por spawnear, dejando a la instancia
## con el `stats`/salud de su uso anterior (o el default embebido en
## `EnemigoBase.tscn`, en su primera creación). Reinicia exactamente lo que
## `_ready()` inicializa una sola vez (`_current_health`), reasigna `stats`
## (distintas oleadas pueden reciclar la misma instancia física con
## `EnemyStats` distintos) y reposiciona el enemigo en el punto de spawn.
## También limpia cualquier tinte visual dejado por `_flash_hit()`/la
## muerte anterior (`_on_enemy_defeated_visual()` tiñe a negro), para que
## un enemigo reciclado no aparezca ya "golpeado" o "muerto".
func prepare_for_spawn(new_stats: EnemyStats, spawn_position: Vector2) -> void:
	stats = new_stats
	_current_health = stats.max_health
	global_position = spawn_position
	_sprite.modulate = Color(1.0, 1.0, 1.0)


## Mayor valor = más avanzado hacia la posición defendida (`spec.md`
## Assumptions), usado por `Soldado._advance_score()` para desempatar
## prioridad de objetivo. Con el eje de avance `+Y` asumido arriba, la
## posición global en `Y` es directamente esa métrica.
func get_advance_progress() -> float:
	return global_position.y


## T043: notifica que este enemigo alcanzó la "posición defendida"
## (`contracts/signals.md`, FR-013). Expuesto como método público en vez de
## que el llamador externo emita `reached_defended_position` directamente
## sobre esta instancia — mismo patrón ya usado en esta clase para
## `take_damage()`/`set_pool()`/`prepare_for_spawn()`: la lógica de emisión
## de las señales propias de `Enemigo` vive dentro de la clase dueña, nunca
## en el nodo que detecta el evento (`Nivel_MonteCalvo.tscn`, `Area2D`
## "PosicionDefendida", ver `nivel_monte_calvo.gd`).
func notify_reached_defended_position() -> void:
	reached_defended_position.emit()


func _die() -> void:
	enemy_defeated.emit(stats.ammo_drop, global_position)
	_spawn_ammo_pickup()

	# T042: conflicto real entre esta clase y `ObjectPool` — un
	# `queue_free()` incondicional aquí destruiría cualquier instancia
	# pooleada que `WaveSpawner`/`ObjectPool` todavía creyeran disponible
	# para un futuro `acquire()` (el pool nunca reparenta ni pierde su
	# referencia a las instancias que reparte). Se resuelve delegando el
	# destino de la instancia a quien la posee:
	if _pool == null:
		# Sin pool (`set_pool()` nunca se llamó) — el `Enemigo` colocado a
		# mano en `Nivel_MonteCalvo.tscn` para el Independent Test de
		# US1/US2 (T027) cae en este caso. Conserva el comportamiento
		# original: `queue_free()`, nunca `free()`
		# (`docs/ARCHITECTURE.md` §4.5), evita use-after-free si algo más
		# todavía tiene una referencia pendiente en el mismo frame (ej.
		# `Soldado._rifle_candidates`/`_melee_candidates` antes de procesar
		# `body_exited`). El feedback visual de muerte ya se aplicó de
		# forma síncrona vía `_on_enemy_defeated_visual` (conectado en
		# `_ready()`), antes de esta línea — el nodo sigue siendo válido
		# durante el resto de este frame porque `queue_free()` difiere la
		# liberación.
		queue_free()
	# Con pool asignado, esta instancia NO se autodestruye: quien escucha
	# `enemy_defeated` (`WaveSpawner._on_enemy_defeated()`) es responsable
	# de llamar `_pool.release(self)` para reciclarla en vez de destruirla.
	# Esa llamada ocurre de forma síncrona en el mismo `emit()` de arriba
	# (las señales de Godot despachan sus listeners de forma síncrona), así
	# que para cuando esta función retorna, la instancia ya fue devuelta al
	# pool (o no, si nadie escucha — no es responsabilidad de `Enemigo`
	# garantizar que alguien libere lo que él no destruye).


## T032: instancia la pickup de munición en la posición de muerte de este
## enemigo (FR-007) y notifica a `EconomyManager` para que emita
## `ammo_pickup_spawned` (`contracts/signals.md` — `EconomyManager` es el
## único emisor de esa señal, aunque quien instancia la escena sea este
## nodo, no el autoload). `pickup_id` es simplemente el `instance_id` de la
## pickup recién creada — suficiente para identificarla de forma única sin
## necesitar un contador global.
##
## Se agrega como hijo del padre de este enemigo, no de este nodo — sin
## pool (T027), este nodo se libera a continuación vía `queue_free()`; con
## pool (T042), este nodo va a quedar invisible/con procesamiento
## deshabilitado (`ObjectPool.release()`), así que tampoco es un padre
## sensato para la pickup en ninguno de los dos casos. `global_position` se
## asigna **después** de `add_child()` (no antes) para que se calcule
## respecto al transform real del padre en el árbol — si se asignara antes,
## con el nodo todavía sin padre, equivaldría a fijar la posición local
## asumiendo un padre en el origen, lo cual sería incorrecto si el
## contenedor de enemigos del nivel tiene su propio offset. Nota T042: si el
## padre de este enemigo es el `ObjectPool` que lo posee (`extends Node`,
## sin transform 2D propio), la pickup queda como hijo de un `Node` plano en
## vez de un `Node2D`/`CanvasItem` — Godot sigue renderizándola y resolviendo
## su `global_position` correctamente (un `CanvasItem` sin ancestro
## `CanvasItem` se trata como de nivel superior para efectos de transform),
## mismo patrón ya documentado como válido en `core/object_pool.gd`
## ("Uso típico: `add_child(enemy_pool)`").
func _spawn_ammo_pickup() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var pickup: AmmoPickup = _AMMO_PICKUP_SCENE.instantiate()
	pickup.amount = stats.ammo_drop
	parent.add_child(pickup)
	pickup.global_position = global_position
	var pickup_id: int = pickup.get_instance_id()
	EconomyManager.notify_pickup_spawned(pickup_id, global_position, stats.ammo_drop)


# --- Feedback visual placeholder (T028) ------------------------------------

## Destello breve al recibir un golpe que no elimina al enemigo — sin
## sprites artísticos reales todavía (`Soldado`/`EnemigoBase` usan una
## textura sólida generada vía `GradientTexture2D`), pero suficiente para que
## un impacto sea perceptible (`constitution.md` Principio III).
func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.15)


## Destello final antes de que el nodo se libere (mismo frame): tiñe el
## sprite a negro para marcar visualmente la eliminación (FR-007,
## `contracts/signals.md` fila `enemy_defeated`).
func _on_enemy_defeated_visual(_ammo_dropped: int, _position: Vector2) -> void:
	_sprite.modulate = Color(0.05, 0.05, 0.05)
