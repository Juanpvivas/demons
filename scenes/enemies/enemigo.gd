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
## 005/I1: avanza hacia −X sin cambiar de fila. El origen INITIAL/WAVE y la
## generación pertenecen a cada activación, no a los stats compartidos.
##
## **Integración con `ObjectPool` (T042, `scenes/levels/wave_spawner.gd`)**:
## esta clase admite ser reciclada por un `ObjectPool` en vez de
## instanciarse/destruirse por spawn (`constitution.md` Principio IV) — ver
## `set_pool()`/`prepare_for_spawn()`. Monte Calvo usa el mismo pool para
## INITIAL y WAVE; una instancia aislada sin pool se retira con queue_free().
##
## **Daño cuerpo a cuerpo contra `Soldado` (T053, rehecha — `spec.md` Edge
## Case: "un soldado en modo cuerpo a cuerpo es derrotado por los
## enemigos")**: la implementación original de esta tarea le daba a
## `Enemigo` su propia `Area2D` "RangoAtaque" para detectar y atacar al
## `Soldado` directamente. `qa-validator` encontró con evidencia empírica
## (`intersect_shape()` confirmando overlap geométrico real y sostenido) un
## problema de motor no documentado antes en el proyecto: una `Area2D` hija
## de un `CharacterBody2D` que llama `move_and_slide()` en cada
## `_physics_process` (como sería "RangoAtaque" sobre `Enemigo`) nunca
## actualiza su lista interna de overlaps contra un `StaticBody2D`
## (`Soldado`) — así que `body_entered`/`body_exited` de esa `Area2D` nunca
## dispararían contra un `Soldado` real en juego real. Decisión de la
## persona dueña del proyecto: invertir qué lado dispara la interacción. El
## daño al `Soldado` ahora se dispara desde la propia `Area2D` "RangoMelee"
## del `Soldado` (`StaticBody2D`, que sí detecta de forma fiable) —
## El soldado conserva el daño de contacto; el enemigo sólo administra su
## fusil excluyente mediante consultas de cuerpos, sin Area2D móvil.
class_name Enemigo
extends CharacterBody2D

## Un inicial no contribuye al contador de bajas de las oleadas.
enum SpawnOrigin { INITIAL, WAVE }
enum CombatPhase { MARCH, RIFLE, CONTACT }

## Grupo que identifica a todo `Enemigo` ante los sistemas de detección de
## `Soldado` (`Soldado.ENEMY_GROUP`, mismo literal).
const ENEMY_GROUP: String = "enemies"
const _SOLDIER_GROUP: StringName = &"soldiers"

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

## Snapshot neutro anterior a cualquier retiro/reciclado síncrono.
signal defeat_visual_requested(snapshot: Dictionary)

## Confirmación anterior al daño, con coordenadas y generación, sin owner Node.
signal rifle_shot_visual_requested(snapshot: Dictionary)

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
@export var board_config: LaneBoardConfig = preload("res://resources/levels/monte_calvo_board.tres")

## Estado de esta activación; nunca se escribe en EnemyStats.
var lane_id: int = -1
var spawn_origin: SpawnOrigin = SpawnOrigin.WAVE
var activation_generation: int = 0
var _activation_active: bool = true
var _reached_defense_notified: bool = false
var _last_defeat_origin: SpawnOrigin = SpawnOrigin.WAVE

## Salud actual, runtime. Inicializada desde `stats.max_health` en `_ready()`
## y reinicializada en cada reciclado vía `prepare_for_spawn()` (T042).
var _current_health: int = 0

## Pool propietario o null para un enemigo aislado. Monte Calvo comparte
## el pool para el inicial y las oleadas sin cambiar la API genérica.
var _pool: ObjectPool = null
## Contrato por grupo/capacidades para evitar dependencia circular de scripts.
var _rifle_target: CharacterBody2D
var _rifle_cooldown: float = 0.0
var _combat_phase: CombatPhase = CombatPhase.MARCH
var _attack_in_progress: bool = false
var _closing: bool = false
var _search_shape := RectangleShape2D.new()
var _rifle_range_shape := RectangleShape2D.new()
var _search_query := PhysicsShapeQueryParameters2D.new()

@onready var _sprite: EnemigoVisual = $AnimatedSprite2D
@onready var _health_bar: WorldHealthBar = $HealthBar


func _ready() -> void:
	assert(stats != null, "Enemigo requiere un EnemyStats asignado en 'stats'")
	_current_health = stats.max_health
	if _activation_active:
		_health_bar.set_health(_current_health, stats.max_health)
	else:
		_health_bar.clear()
	add_to_group(ENEMY_GROUP)
	_sprite.reset_visual()
	_search_query.shape = _search_shape
	_search_query.collide_with_areas = false
	_search_query.exclude = [get_rid()]
	GameStateManager.game_state_changed.connect(_on_game_state_changed)


func _physics_process(delta: float) -> void:
	if _attack_in_progress:
		return
	if _closing or not is_targetable() or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		velocity = Vector2.ZERO
		return
	var before := global_position
	if stats.rifle_range > 0.0 and stats.rifle_damage > 0 and stats.rifle_interval > 0.0:
		var targets := _find_rifle_candidates()
		for candidate: CharacterBody2D in targets:
			if candidate.call("is_in_melee_contact_with", self):
				_reset_rifle()
				_combat_phase = CombatPhase.CONTACT
				velocity = Vector2.ZERO
				_sprite.observe_displacement(Vector2.ZERO)
				return
		if not _is_rifle_target_valid(_rifle_target):
			_reset_rifle()
			for candidate: CharacterBody2D in targets:
				if _is_rifle_target_valid(candidate) and (_rifle_target == null \
						or candidate.global_position.x > _rifle_target.global_position.x):
					_rifle_target = candidate
		if _rifle_target != null:
			_combat_phase = CombatPhase.RIFLE
			velocity = Vector2.ZERO
			_sprite.observe_displacement(Vector2.ZERO)
			_rifle_cooldown -= delta
			if _rifle_cooldown <= 0.0:
				_fire_rifle()
			return
	_combat_phase = CombatPhase.MARCH
	velocity = Vector2(-stats.move_speed, 0.0)
	move_and_slide()
	_sprite.observe_displacement(global_position - before)


func _find_rifle_candidates() -> Array[CharacterBody2D]:
	# El margen derecho incluye contacto durante el regreso de un soldado.
	var margin := float(board_config.cell_size.x)
	_search_shape.size = Vector2(stats.rifle_range + margin, board_config.cell_size.y)
	_search_query.transform = Transform2D(0.0,
		global_position + Vector2((margin - stats.rifle_range) * 0.5, 0.0))
	_search_query.collision_mask = collision_mask
	var space := get_world_2d().direct_space_state
	var limit := 32
	var hits := space.intersect_shape(_search_query, limit)
	while hits.size() == limit:
		limit *= 2
		hits = space.intersect_shape(_search_query, limit)
	var result: Array[CharacterBody2D] = []
	for hit: Dictionary in hits:
		var soldier := hit.collider as CharacterBody2D
		if is_instance_valid(soldier) and soldier.is_in_group(_SOLDIER_GROUP) \
				and soldier.call("get_reload_state").alive and not result.has(soldier):
			result.append(soldier)
	return result


func _is_rifle_target_valid(target: CharacterBody2D) -> bool:
	if not is_instance_valid(target) or not target.is_inside_tree() \
			or not target.is_in_group(_SOLDIER_GROUP) or not target.call("get_reload_state").alive \
			or target.global_position.x >= global_position.x:
		return false
	if floori(target.global_position.y / board_config.cell_size.y) \
			!= floori(global_position.y / board_config.cell_size.y):
		return false
	# Revalidar las formas con sus transforms actuales, también tras listeners síncronos.
	_rifle_range_shape.size = Vector2(stats.rifle_range, board_config.cell_size.y)
	var range_transform := Transform2D(0.0, global_position - Vector2(stats.rifle_range * 0.5, 0.0))
	for owner_id: int in target.get_shape_owners():
		if target.is_shape_owner_disabled(owner_id):
			continue
		var body_transform := target.global_transform * target.shape_owner_get_transform(owner_id)
		for index in target.shape_owner_get_shape_count(owner_id):
			if _rifle_range_shape.collide(range_transform, target.shape_owner_get_shape(owner_id, index), body_transform):
				return true
	return false


func _fire_rifle() -> void:
	var target := _rifle_target
	if _attack_in_progress or not _is_rifle_target_valid(target) or target.call("is_in_melee_contact_with", self):
		return
	var generation := activation_generation
	var target_id := target.get_instance_id()
	var damage := stats.rifle_damage
	_rifle_cooldown = stats.rifle_interval
	_attack_in_progress = true
	var snapshot := _sprite.capture_rifle_shot_snapshot(target.global_position)
	snapshot["activation_generation"] = generation
	rifle_shot_visual_requested.emit(snapshot)
	# Un listener puede mover/matar el blanco o reciclar al propio emisor.
	if not _closing and is_targetable() and activation_generation == generation \
			and GameStateManager._current_state == GameStateManager.GameState.PLAYING \
			and _is_rifle_target_valid(target) and target.get_instance_id() == target_id \
			and not target.call("is_in_melee_contact_with", self):
		_sprite.play_confirmed_rifle()
		target.call("take_damage", damage)
	_attack_in_progress = false


func _reset_rifle() -> void:
	_rifle_target = null
	_rifle_cooldown = 0.0
	_combat_phase = CombatPhase.MARCH


func close_match() -> void:
	_closing = true
	_reset_rifle()
	velocity = Vector2.ZERO


func _on_game_state_changed(state: int) -> void:
	if state == GameStateManager.GameState.MENU:
		close_match()
	elif state in [GameStateManager.GameState.WON, GameStateManager.GameState.LOST]:
		_reset_rifle()
		velocity = Vector2.ZERO
	# PAUSED congela el intervalo restante; regresar no acumula tiros ni readquiere.


func _exit_tree() -> void:
	close_match()
	if GameStateManager.game_state_changed.is_connected(_on_game_state_changed):
		GameStateManager.game_state_changed.disconnect(_on_game_state_changed)


func is_targetable() -> bool:
	return not _closing and _activation_active and _current_health > 0 and not is_queued_for_deletion()


## El retiro del pool también desactiva enemigos vivos; no constituye una baja.
func has_confirmed_defeat() -> bool:
	return _current_health <= 0


## Aplica `amount` de daño y retorna `true` únicamente si esta llamada dejó
## la salud en 0 o menos (contrato asumido por `soldado.gd`, usado para
## decidir si esa eliminación suma moral — FR-006). Defensivo ante llamadas
## repetidas sobre un enemigo ya eliminado (su `queue_free()` es diferido,
## no inmediato).
func take_damage(amount: int) -> bool:
	if not is_targetable():
		return false
	_current_health -= amount
	_health_bar.set_health(_current_health, stats.max_health)
	if _current_health <= 0:
		_die()
		return true
	if amount > 0:
		_sprite.play_confirmed_hit()
	return false


## T053 (rehecha): expone el daño cuerpo a cuerpo de este enemigo para que
## `Soldado` lo aplique sobre sí mismo mientras este `Enemigo` esté dentro de
## su "RangoMelee" (`spec.md` Edge Case: "un soldado en modo cuerpo a cuerpo
## es derrotado por los enemigos"). Mismo criterio ya usado en esta clase
## para exponer datos a quien consume (`get_advance_progress()`): la lógica
## de emisión/aplicación del daño vive en la clase dueña de la detección
## fiable (`Soldado`, ver cabecera de este archivo), este método solo aporta
## el valor de `EnemyStats` que le corresponde a esta instancia.
func get_melee_damage() -> int:
	return stats.melee_damage


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
## Reinicia además toda la presentación antes del primer frame del nuevo uso.
func prepare_for_spawn(new_stats: EnemyStats, spawn_position: Vector2,
		new_lane_id: int = -1, new_origin: SpawnOrigin = SpawnOrigin.WAVE) -> void:
	stats = new_stats
	_current_health = stats.max_health
	lane_id = new_lane_id
	spawn_origin = new_origin
	activation_generation += 1
	_reset_rifle()
	_closing = false
	_activation_active = true
	_reached_defense_notified = false
	velocity = Vector2.ZERO
	global_position = spawn_position
	_set_body_disabled(false)
	_sprite.reset_visual()
	_health_bar.set_health(_current_health, stats.max_health)


## Puede ocurrir antes de `_ready()` al precalentar un pool fuera del árbol.
## No necesita stats nuevos; el reset de aparición sigue en prepare_for_spawn.
func on_pool_released() -> void:
	_activation_active = false
	_reset_rifle()
	var health_bar := get_node_or_null("HealthBar") as WorldHealthBar
	if health_bar != null:
		health_bar.clear()
	velocity = Vector2.ZERO
	_set_body_disabled(true)
	var visual := get_node_or_null("AnimatedSprite2D") as EnemigoVisual
	if visual != null:
		visual.deactivate_visual()


func _set_body_disabled(disabled: bool) -> void:
	var body := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body != null:
		body.set_deferred("disabled", disabled)


## Mayor valor = más avanzado hacia la posición defendida (`spec.md`
## Assumptions), usado por `Soldado._advance_score()` para desempatar
## prioridad de objetivo. En el avance horizontal el menor X va primero.
func get_advance_progress() -> float:
	return -global_position.x


## Contexto capturado antes de listeners visuales o del reciclado síncrono.
func get_defeat_origin() -> SpawnOrigin:
	return _last_defeat_origin


## T043: notifica que este enemigo alcanzó la "posición defendida"
## (`contracts/signals.md`, FR-013). Expuesto como método público en vez de
## que el llamador externo emita `reached_defended_position` directamente
## sobre esta instancia — mismo patrón ya usado en esta clase para
## `take_damage()`/`set_pool()`/`prepare_for_spawn()`: la lógica de emisión
## de las señales propias de `Enemigo` vive dentro de la clase dueña, nunca
## en el nodo que detecta el evento (`Nivel_MonteCalvo.tscn`, `Area2D`
## "PosicionDefendida", ver `nivel_monte_calvo.gd`).
func notify_reached_defended_position() -> void:
	if not is_targetable() or _reached_defense_notified:
		return
	_reached_defense_notified = true
	reached_defended_position.emit()


func _die() -> void:
	# El callback de baja puede liberar y reutilizar este mismo nodo antes
	# de retornar. La recompensa conserva el contexto de la baja anterior.
	var drop_amount := stats.ammo_drop
	var drop_position := global_position
	var drop_parent := get_parent()
	var pool := _pool
	_last_defeat_origin = spawn_origin
	_activation_active = false
	_reset_rifle()
	_health_bar.clear()
	var snapshot := _sprite.capture_defeat_snapshot(global_position)
	_sprite.deactivate_visual()
	defeat_visual_requested.emit(snapshot)
	enemy_defeated.emit(drop_amount, drop_position)
	_spawn_ammo_pickup(drop_parent, drop_position, drop_amount)

	# T042: conflicto real entre esta clase y `ObjectPool` — un
	# `queue_free()` incondicional aquí destruiría cualquier instancia
	# pooleada que `WaveSpawner`/`ObjectPool` todavía creyeran disponible
	# para un futuro `acquire()` (el pool nunca reparenta ni pierde su
	# referencia a las instancias que reparte). Se resuelve delegando el
	# destino de la instancia a quien la posee:
	if pool == null:
		# Enemigo aislado: el retiro no espera la caída visual.
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
func _spawn_ammo_pickup(parent: Node, drop_position: Vector2, drop_amount: int) -> void:
	if not is_instance_valid(parent):
		return
	var pickup: AmmoPickup = _AMMO_PICKUP_SCENE.instantiate()
	pickup.amount = drop_amount
	parent.add_child(pickup)
	pickup.global_position = drop_position
	var pickup_id: int = pickup.get_instance_id()
	EconomyManager.notify_pickup_spawned(pickup_id, drop_position, drop_amount)
