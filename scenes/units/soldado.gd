## Soldado defensor: dispara automáticamente con fusil a un único objetivo
## prioritario dentro de "DeteccionRango" (carril frontal + diagonales) hasta
## agotar munición, y transiciona automáticamente a combate cuerpo a cuerpo
## con machete contra enemigos en "RangoMelee" (FR-002 a FR-006).
##
## 005/I2: cuerpo móvil; el fusil permanece en su hogar y el machete avanza
## solo hacia un frontal de su fila. Las consultas del tick físico sustituyen
## los overlaps almacenados del soldado estático anterior. El hallazgo histórico
## de T053 se conserva en `docs/ARCHITECTURE.md` §4.2.
##
## Contrato asumido de `Enemigo`, cumplido desde T018/T025/T026 (la clase
## `Enemigo` ya existe en `scenes/enemies/enemigo.gd`):
## - Pertenece al grupo `"enemies"` (`ENEMY_GROUP`), usado para filtrar los
##   cuerpos detectados por "DeteccionRango"/"RangoMelee" (que también
##   podrían recibir otros `StaticBody2D`/`CharacterBody2D` del nivel).
## - Expone `take_damage(amount: int) -> bool`, que aplica el daño y
##   retorna `true` si ese impacto fue el que lo eliminó (salud llegó a 0),
##   `false` en caso contrario. Este valor de retorno —no una señal— es lo
##   que usa `soldado.gd` para saber si debe sumar moral (FR-006), evitando
##   conectarse a una señal de una instancia dinámica fuera de `_ready()`
##   (prohibido por `docs/ARCHITECTURE.md` §4.2: "ni en callbacks
##   puntuales"). El propio `Enemigo` sigue emitiendo `enemy_defeated`
##   (`contracts/signals.md`) para que `EconomyManager`/el spawner lo
##   escuchen y generen la pickup de munición.
## - Opcionalmente expone `get_advance_progress() -> float` (mayor valor =
##   más avanzado hacia la posición defendida), usado para desempatar la
##   prioridad de objetivo (`spec.md` Assumptions). Si no existe, se usa
##   como respaldo la cercanía a este soldado (`_advance_score()`).
## - Expone `get_melee_damage() -> int` (`stats.melee_damage` de ese
##   enemigo), usado por este soldado para aplicarse daño a sí mismo
##   mientras ese enemigo esté dentro de "RangoMelee" (T053, rehecha —
##   ver `_process_incoming_melee_damage()`).
##
## Se conserva la autoridad de daño mutuo del soldado establecida en T053:
## cada atacante válido aporta `get_melee_damage()` y el soldado aplica el
## pulso entrante de 1 s. I2 cambia su detección, no esa regla de combate.
##
## TODO (T047 — revisión de todo el código nuevo contra ARCHITECTURE.md):
## `_current_target`/`_current_melee_target` siguen tipados como `Node2D` y
## el daño se aplica vía `Object.call("take_damage", ...)` (despacho
## dinámico) en vez de tipar directamente como `Enemigo` y llamar
## `target.take_damage(...)`. Quedó así porque `Enemigo` no existía cuando
## se escribió este archivo; ahora que existe (T025/T026), esto puede
## simplificarse a una llamada tipada estática. Observación no bloqueante
## de `qa-validator` en T027/T028 — no se corrige aquí porque es cambio de
## lógica, fuera del alcance de documentación.
class_name Soldado
extends CharacterBody2D

## Grupo al que se espera que pertenezca todo `Enemigo` (contrato asumido,
## ver comentario de cabecera). Filtra los cuerpos de las consultas físicas.
const ENEMY_GROUP: String = "enemies"

## Munición llega a 0, justo antes de pasar a modo machete (FR-004).
signal ammo_depleted

## Cambio entre `RIFLE` y `MELEE`, en cualquier dirección.
signal mode_changed(new_mode: SoldierMode)

## Se acumuló moral por una eliminación confirmada con fusil (FR-006).
signal moral_changed(new_morale: float)

## El soldado fue derrotado (`spec.md` Edge Case: pierde moral, libera
## celda). Payload por contrato (`contracts/signals.md`): la celda que
## ocupaba en el `BoardManager` del nivel, para que quien escuche (ej.
## `BoardManager`) la libere.
signal soldier_defeated(grid_cell: Vector2i)

## Snapshot visual anterior al retiro; ningún listener es necesario para morir.
signal defeat_visual_requested(snapshot: Dictionary)

signal rifle_shot_visual_requested(snapshot: Dictionary)

## Cambió el estado individual observado por el panel, sin autoridad de UI.
signal reload_state_changed

## Modo de combate activo (`docs/ARCHITECTURE.md` §4.4).
enum SoldierMode { RIFLE, MELEE }

## Estado de desplazamiento separado del arma. RETURNING pertenece a I3.
enum MovementState { HOME, ADVANCING, MELEE_CONTACT, WAITING, RETURNING, DEAD }

## Molde de datos base/máximos de este soldado — solo lectura, nunca
## mutado en runtime (`docs/ARCHITECTURE.md` §4.3).
@export var stats: UnitStats
@export var board_config: LaneBoardConfig = preload("res://resources/levels/monte_calvo_board.tres")

## Munición actual, runtime. Inicializada desde `stats.max_ammo` en `_ready()`.
var _current_ammo: int = 0
var _reload_in_progress: bool = false

## Moral acumulada por eliminación (FR-006). Persiste entre recargas;
## solo se pierde si el soldado es derrotado (fuera del alcance de estas
## tareas).
var _current_morale: float = 0.0

## Modo de combate activo.
var _mode: SoldierMode = SoldierMode.RIFLE

## Salud actual, runtime. Inicializada desde `stats.max_health` en `_ready()`
## (`data-model.md`, mismo patrón que `Enemigo._current_health`).
var _current_health: int = 0

## Celda ocupada en el `BoardManager` del nivel (`data-model.md`). Nunca se
## asigna sola: quien despliega este soldado debe llamar `set_grid_cell()`
## después de instanciarlo. Se reporta en `soldier_defeated` para que
## `BoardManager` libere la celda correcta.
var _grid_cell: Vector2i

var _movement_state: MovementState = MovementState.HOME
var _home_position: Vector2

## Objetivo activo de fusil — nunca más de uno a la vez (FR-002).
var _current_target: Node2D = null
var _current_target_generation: int = -1

## Objetivo activo de machete — misma regla de "sin dividir fuego",
## aplicada también en modo cuerpo a cuerpo.
var _current_melee_target: Node2D = null
var _current_melee_generation: int = -1

## Candidatos del tick físico, sin recorrer nodos de la escena ni depender
## de las señales Area2D de un cuerpo móvil.
var _rifle_candidates: Array[Node2D] = []
var _melee_candidates: Array[Node2D] = []
var _front_candidates: Array[Node2D] = []
var _candidate_generations: Dictionary[int, int] = {}
var _search_shape := RectangleShape2D.new()
var _search_query := PhysicsShapeQueryParameters2D.new()

## Cuenta regresiva hasta el próximo disparo de fusil, en segundos.
var _rifle_cooldown: float = 0.0

## Cuenta regresiva hasta el próximo golpe de machete, en segundos.
## Reutiliza `stats.fire_rate` como cadencia de ataque cuerpo a cuerpo —
## `UnitStats` no define una cadencia de machete separada (ver reporte de
## T017-T024, supuesto documentado explícitamente).
var _melee_cooldown: float = 0.0

## Cuenta regresiva hasta el próximo golpe QUE RECIBE este soldado de
## cualquier `Enemigo` dentro de "RangoMelee" (daño mutuo, T053 rehecha).
## Independiente de `_mode`: un enemigo adyacente golpea a este soldado
## tanto si sigue disparando con fusil como si ya pasó a machete — el
## ataque entrante no depende del modo de combate del soldado, solo de la
## presencia real de un enemigo en "RangoMelee". Arranca en 0.0 para que el
## primer golpe recibido tras entrar el primer enemigo sea inmediato (mismo
## criterio que `_melee_cooldown`/`_rifle_cooldown`).
var _incoming_melee_cooldown: float = 0.0

@onready var _sprite: SoldadoVisual = $AnimatedSprite2D
@onready var _rifle_shape: CollisionShape2D = $DeteccionRango/CollisionShape2D
@onready var _melee_shape: CollisionShape2D = $RangoMelee/CollisionShape2D

## T053 (rehecha): cadencia del ataque entrante de cada `Enemigo` dentro de
## "RangoMelee" contra este soldado — **supuesto de implementación**, igual
## que el ya documentado arriba para `_melee_cooldown` (`stats.fire_rate`
## reutilizado como cadencia de machete propia del soldado): `EnemyStats` no
## define ningún campo de cadencia de ataque (`move_speed`, `melee_damage`,
## `ammo_drop`, `max_health`), así que se fija un intervalo constante de 1
## golpe por segundo por cada enemigo presente en "RangoMelee", igual para
## todo tipo de enemigo hasta que el balance exija diferenciarlo. Mismo
## valor que usaba la implementación original y descartada de esta cadencia
## del lado de `Enemigo` (T053 original) — no es una decisión de diseño
## nueva, solo cambia qué lado del combate la dispara.
const _INCOMING_MELEE_ATTACK_INTERVAL: float = 1.0


func _ready() -> void:
	assert(stats != null, "Soldado requiere un UnitStats asignado en 'stats'")
	_home_position = global_position
	_current_ammo = stats.max_ammo
	_current_health = stats.max_health

	_search_query.shape = _search_shape
	_search_query.collide_with_areas = false
	_search_query.exclude = [get_rid()]
	# El propio soldado escucha su señal para transicionar de modo — mismo
	# patrón ya documentado en `docs/ARCHITECTURE.md` §4.2.
	ammo_depleted.connect(_on_ammo_depleted)
	mode_changed.connect(_sprite.observe_mode)
	moral_changed.connect(_on_moral_changed_visual)
	_sprite.reset_visual(_mode)


func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if not _can_process_combat():
		_clear_combat_targets()
		_sprite.observe_motion(_movement_state, Vector2.ZERO)
		return
	var previous_position := global_position
	_refresh_physics_candidates()
	var previous_movement := _movement_state
	if _movement_state == MovementState.RETURNING:
		_process_return(delta)
	else:
		match _mode:
			SoldierMode.RIFLE:
				_process_rifle(delta)
			SoldierMode.MELEE:
				_process_melee(delta)
	if _movement_state != previous_movement:
		reload_state_changed.emit()
	# Una baja puede cambiar a WON de forma síncrona durante el ataque.
	if not _can_process_combat():
		velocity = Vector2.ZERO
		_clear_combat_targets()
		_sprite.observe_motion(_movement_state, Vector2.ZERO)
		return
	_sprite.observe_motion(_movement_state, global_position - previous_position)
	_process_incoming_melee_damage(delta)


func _process_return(delta: float) -> void:
	var remaining := _home_position.x - global_position.x
	velocity = Vector2(signf(remaining) * minf(stats.return_speed, absf(remaining) / delta), 0.0)
	move_and_slide()
	_refresh_physics_candidates()
	if _is_at_home():
		velocity = Vector2.ZERO
		_movement_state = MovementState.HOME
		_set_mode(SoldierMode.RIFLE)


func _can_process_combat() -> bool:
	return _current_health > 0 and GameStateManager._current_state == GameStateManager.GameState.PLAYING


func _clear_combat_targets() -> void:
	if _current_health > 0:
		_movement_state = MovementState.HOME if _is_at_home() else MovementState.WAITING
	_current_target = null
	_current_target_generation = -1
	_current_melee_target = null
	_current_melee_generation = -1
	_rifle_candidates.clear()
	_melee_candidates.clear()
	_front_candidates.clear()
	_candidate_generations.clear()


## El fusil consulta su alcance; el machete busca hasta el extremo del tablero
## en su fila. Los filtros posteriores conservan las formas autoradas.
func _refresh_physics_candidates() -> void:
	_rifle_candidates.clear()
	_melee_candidates.clear()
	_front_candidates.clear()
	_candidate_generations.clear()
	var rifle_rect := _rifle_shape.shape.get_rect()
	var width := _rifle_shape.position.x + rifle_rect.end.x
	var height := rifle_rect.size.y
	if _mode == SoldierMode.MELEE:
		width = maxf(board_config.design_rect.end.x - global_position.x, width)
		height = board_config.cell_size.y
	_search_shape.size = Vector2(width, height)
	_search_query.transform = Transform2D(0.0, global_position + Vector2(width * 0.5, 0.0))
	if _movement_state == MovementState.RETURNING:
		# Mismo alcance de contacto delante y detrás durante el retorno.
		_search_shape.size = Vector2(2.0 * (_melee_shape.position.x + _melee_shape.shape.get_rect().end.x), _melee_shape.shape.get_rect().size.y)
		_search_query.transform = Transform2D(0.0, global_position)
	_search_query.collision_mask = collision_mask
	# Crecer hasta obtener el conjunto completo: el orden interno de física
	# no puede ocultar candidatos válidos por un límite fijo de resultados.
	var result_limit := 32
	var space := get_world_2d().direct_space_state
	var hits := space.intersect_shape(_search_query, result_limit)
	while hits.size() == result_limit:
		result_limit *= 2
		hits = space.intersect_shape(_search_query, result_limit)
	for hit: Dictionary in hits:
		var body := hit["collider"] as Node2D
		if body == null or _candidate_generations.has(body.get_instance_id()):
			continue
		_candidate_generations[body.get_instance_id()] = _generation_of(body)
		if _is_rifle_eligible(body):
			_rifle_candidates.append(body)
		if _is_front_eligible(body):
			_front_candidates.append(body)
		if _is_incoming_eligible(body):
			_melee_candidates.append(body)


# --- Modo fusil (T021, T022) --------------------------------------------

func _process_rifle(delta: float) -> void:
	if not _is_at_home():
		return
	_movement_state = MovementState.HOME
	if not is_instance_valid(_current_target) \
			or not _rifle_candidates.has(_current_target) \
			or not _is_rifle_eligible(_current_target) \
			or _generation_of(_current_target) != _current_target_generation:
		_recompute_rifle_target()
	if _current_target == null or _current_ammo <= 0:
		return
	_rifle_cooldown -= delta
	if _rifle_cooldown > 0.0:
		return
	_fire_at_current_target()
	_rifle_cooldown = 1.0 / stats.fire_rate


func _fire_at_current_target() -> void:
	var target := _current_target
	_current_ammo -= 1
	# TODO (T047): `.call()` en vez de `target.take_damage(...)` directo —
	# ver TODO en la cabecera del archivo. `_current_target` sigue tipado
	# como `Node2D` aunque `Enemigo` ya existe (T025/T026); GDScript con
	# tipado estático rechaza en tiempo de compilación una llamada directa
	# a un método que no existe en `Node2D`. `Object.call()` sí es un
	# método real de `Node2D` (heredado de `Object`), por lo que el
	# despacho dinámico compila sin problema, pero es más frágil que tipar
	# `_current_target` como `Enemigo`.
	var killed: bool = target.call("take_damage", stats.damage_per_shot)
	_sprite.play_confirmed_attack(SoldierMode.RIFLE)
	if killed:
		_register_kill()
		_remove_rifle_candidate(target)
	if _current_ammo <= 0:
		_current_ammo = 0
		ammo_depleted.emit()
	reload_state_changed.emit()


func _remove_rifle_candidate(body: Node2D) -> void:
	_rifle_candidates.erase(body)
	if body == _current_target:
		_current_target = null
		_recompute_rifle_target()


## También pierde elegibilidad al salir de la celda diagonal, aunque siga
## dentro del broadphase. Un cuerpo reciclado pertenece a otra generación.
func _recompute_rifle_target() -> void:
	var eligible: Array[Node2D] = []
	for candidate: Node2D in _rifle_candidates:
		if _is_rifle_eligible(candidate):
			eligible.append(candidate)
	_current_target = _pick_priority_target(eligible)
	_current_target_generation = _generation_of(_current_target)


# --- Modo machete (T023) -------------------------------------------------

func _process_melee(delta: float) -> void:
	if not is_instance_valid(_current_melee_target) \
			or not _melee_candidates.has(_current_melee_target) \
			or not _is_melee_eligible(_current_melee_target) \
			or _generation_of(_current_melee_target) != _current_melee_generation:
		_recompute_melee_target()
	if _current_melee_target == null:
		if _front_candidates.is_empty():
			_movement_state = MovementState.HOME if _is_at_home() else MovementState.WAITING
			return
		# Todos los frontales de esta fila requieren el mismo avance +X.
		# El foco de combate solo se adquiere al entrar en alcance real.
		_movement_state = MovementState.ADVANCING
		velocity = Vector2(stats.advance_speed, 0.0)
		move_and_slide()
		_refresh_physics_candidates()
		_recompute_melee_target()
	if _current_melee_target == null:
		return
	# Detenerse desde el primer golpe, aunque el enemigo aún se aproxime
	# dentro del alcance y los cuerpos todavía no hayan chocado.
	velocity = Vector2.ZERO
	_movement_state = MovementState.MELEE_CONTACT
	_melee_cooldown -= delta
	if _melee_cooldown > 0.0:
		return
	_attack_current_melee_target()
	_melee_cooldown = 1.0 / stats.fire_rate
	if _current_melee_target == null:
		_movement_state = MovementState.HOME if _is_at_home() else MovementState.WAITING


func _attack_current_melee_target() -> void:
	var target := _current_melee_target
	# TODO (T047): mismo despacho dinámico que `_fire_at_current_target()` —
	# ver TODO en la cabecera del archivo.
	var killed: bool = target.call("take_damage", _current_machete_damage())
	_sprite.play_confirmed_attack(SoldierMode.MELEE)
	if killed:
		# A diferencia del fusil, una eliminación a machete NO suma moral
		# (FR-006, `data-model.md` fila `moral_per_kill`, `spec.md`
		# Assumptions): la moral se acumula únicamente por eliminaciones
		# mientras el soldado dispara con munición disponible.
		_remove_melee_candidate(target)


## Daño de machete = base + moral * multiplicador (`research.md` §2). Con
## moral 0, `machete_base_damage` (> 0 por diseño de `UnitStats`) garantiza
## el daño mínimo que exige el Edge Case de `spec.md`.
func _current_machete_damage() -> int:
	return roundi(stats.machete_base_damage + _current_morale * stats.machete_moral_multiplier)


func _remove_melee_candidate(body: Node2D) -> void:
	_melee_candidates.erase(body)
	_front_candidates.erase(body)
	if body == _current_melee_target:
		_current_melee_target = null
		_recompute_melee_target()


func _recompute_melee_target() -> void:
	var eligible: Array[Node2D] = []
	for candidate: Node2D in _melee_candidates:
		if _is_melee_eligible(candidate):
			eligible.append(candidate)
	_current_melee_target = _pick_priority_target(eligible)
	_current_melee_generation = _generation_of(_current_melee_target)


## T053 (rehecha): daño mutuo dentro de "RangoMelee" (`spec.md` Edge Case,
## ver comentario de `_incoming_melee_cooldown` y la cabecera del archivo).
## A diferencia del ataque de machete de este soldado (que solo golpea a
## `_current_melee_target`, sin dividir fuego), el daño ENTRANTE se aplica
## por cada `Enemigo` presente en `_melee_candidates` — un soldado rodeado
## por varios enemigos cuerpo a cuerpo recibe el golpe de cada uno, aunque
## él mismo solo pueda atacar a uno a la vez. La consulta deduplica cuerpos
## y conserva su generación anterior a callbacks de daño/reciclado.
func _process_incoming_melee_damage(delta: float) -> void:
	if _melee_candidates.is_empty():
		return
	_incoming_melee_cooldown -= delta
	if _incoming_melee_cooldown > 0.0:
		return
	for enemy: Node2D in _melee_candidates.duplicate():
		if not _can_process_combat():
			break
		if not _is_incoming_eligible(enemy) or not enemy.has_method("get_melee_damage"):
			continue
		take_damage(enemy.call("get_melee_damage"))
	_incoming_melee_cooldown = _INCOMING_MELEE_ATTACK_INTERVAL


func _is_live_candidate(body: Node2D) -> bool:
	if not is_instance_valid(body) or not body.is_inside_tree() \
			or body.is_queued_for_deletion() or not body.is_in_group(ENEMY_GROUP):
		return false
	if _candidate_generations.get(body.get_instance_id(), -2) != _generation_of(body):
		return false
	if body is Enemigo:
		return (body as Enemigo).is_targetable()
	return true


func _generation_of(body: Node2D) -> int:
	return (body as Enemigo).activation_generation if is_instance_valid(body) and body is Enemigo else -1


func _candidate_cell(body: Node2D) -> Vector2i:
	return Vector2i(floori(body.global_position.x / board_config.cell_size.x),
		floori(body.global_position.y / board_config.cell_size.y))


func _is_rifle_eligible(body: Node2D) -> bool:
	if not _is_live_candidate(body) or body.global_position.x <= global_position.x:
		return false
	var cell := _candidate_cell(body)
	var lane := board_config.home_cells.find(_grid_cell)
	if lane < 0 or cell.y < board_config.home_cells[0].y or cell.y > board_config.home_cells[-1].y:
		return false
	var same_row := cell.y == _grid_cell.y
	var direct_diagonal := cell.x == _grid_cell.x + 1 and absi(cell.y - _grid_cell.y) == 1
	return (same_row or direct_diagonal) and _body_overlaps_range(body, _rifle_shape)


func _is_melee_eligible(body: Node2D) -> bool:
	return _is_front_eligible(body) and _body_overlaps_range(body, _melee_shape)


func _is_incoming_eligible(body: Node2D) -> bool:
	if _movement_state != MovementState.RETURNING:
		return _is_melee_eligible(body)
	if not _is_live_candidate(body) or _candidate_cell(body).y != _grid_cell.y:
		return false
	var contact_transform := _melee_shape.global_transform
	if body.global_position.x < global_position.x:
		contact_transform.origin = global_position - _melee_shape.position
	return _body_overlaps_range(body, _melee_shape, contact_transform)


func _is_front_eligible(body: Node2D) -> bool:
	return _is_live_candidate(body) and body.global_position.x > global_position.x \
		and _candidate_cell(body).y == _grid_cell.y


func _is_at_home() -> bool:
	return global_position.distance_to(_home_position) <= 0.01


## Solape de las formas reales, sin convertir el extremo del área en una
## distancia al centro del enemigo ni asumir que todos los cuerpos miden igual.
func _body_overlaps_range(body: Node2D, range_shape: CollisionShape2D,
		range_transform: Transform2D = Transform2D.IDENTITY) -> bool:
	if range_transform == Transform2D.IDENTITY:
		range_transform = range_shape.global_transform
	var collider := body as CollisionObject2D
	if collider == null:
		return false
	for owner_id: int in collider.get_shape_owners():
		if collider.is_shape_owner_disabled(owner_id):
			continue
		var body_transform := collider.global_transform * collider.shape_owner_get_transform(owner_id)
		for shape_id in collider.shape_owner_get_shape_count(owner_id):
			var shape := collider.shape_owner_get_shape(owner_id, shape_id)
			if range_shape.shape.collide(range_transform, shape, body_transform):
				return true
	return false


func _on_ammo_depleted() -> void:
	_set_mode(SoldierMode.MELEE)


## Compatibilidad: toda ruta de recarga usa la misma transacción validada.
func reload() -> void:
	request_reload()


func _set_mode(new_mode: SoldierMode) -> void:
	if _mode == new_mode:
		return
	_mode = new_mode
	mode_changed.emit(_mode)


# --- Salud y derrota (T052) ------------------------------------------------

## Setter público de `_grid_cell` — quien despliega este soldado (spawner del
## nivel) debe llamarlo justo después de instanciarlo, para que
## `soldier_defeated` reporte la celda correcta si más adelante es derrotado.
func set_grid_cell(cell: Vector2i) -> void:
	_grid_cell = cell


func get_movement_state() -> MovementState:
	return _movement_state


func get_home_position() -> Vector2:
	return _home_position


func get_lane_id() -> int:
	return board_config.home_cells.find(_grid_cell)


## Snapshot de lectura para selección/HUD; no autoriza una orden económica.
func get_reload_state() -> Dictionary:
	return {
		"instance_id": get_instance_id(),
		"home_cell": _grid_cell,
		"lane_id": get_lane_id(),
		"ammo": _current_ammo,
		"max_ammo": stats.max_ammo,
		"morale": _current_morale,
		"health": _current_health,
		"alive": _current_health > 0 and not is_queued_for_deletion(),
		"mode": _mode,
		"movement_state": _movement_state,
		"reload_cost": stats.deploy_ammo_cost,
		"can_reload": can_reload(),
	}


func can_reload() -> bool:
	return _can_process_combat() and not is_queued_for_deletion() \
		and _current_ammo == 0 and not _reload_in_progress \
		and _movement_state != MovementState.RETURNING \
		and EconomyManager.collected_ammo >= stats.deploy_ammo_cost


func request_reload() -> bool:
	if not can_reload():
		return false
	# Bloquear antes de cualquier señal: los listeners del gasto son síncronos.
	_reload_in_progress = true
	reload_state_changed.emit()
	if not EconomyManager.try_spend_ammo(stats.deploy_ammo_cost):
		_reload_in_progress = false
		reload_state_changed.emit()
		return false
	# Un callback puede terminar la partida o matar al actor; nunca resucitarlo.
	if _can_process_combat() and not is_queued_for_deletion():
		_current_ammo = stats.max_ammo
		_clear_combat_targets()
		if _is_at_home():
			_movement_state = MovementState.HOME
			_set_mode(SoldierMode.RIFLE)
		else:
			_movement_state = MovementState.RETURNING
		_sprite.observe_motion(_movement_state, Vector2.ZERO)
	_reload_in_progress = false
	reload_state_changed.emit()
	return true


## Aplica `amount` de daño y retorna `true` únicamente si esta llamada dejó
## la salud en 0 o menos (mismo contrato que `Enemigo.take_damage()`, ver
## cabecera de este archivo y de `enemigo.gd`). Al llegar a 0, el soldado
## pierde toda su moral acumulada, reporta su derrota con
## `soldier_defeated(_grid_cell)` (`contracts/signals.md`, `spec.md` Edge
## Case) y se libera del árbol.
func take_damage(amount: int) -> bool:
	if _current_health <= 0:
		return false
	_current_health -= amount
	reload_state_changed.emit()
	if _current_health <= 0:
		_die()
		return true
	if amount > 0:
		_sprite.play_confirmed_hit()
	return false


func _die() -> void:
	_movement_state = MovementState.DEAD
	velocity = Vector2.ZERO
	_clear_combat_targets()
	var snapshot := _sprite.capture_defeat_snapshot(global_position)
	_sprite.deactivate_visual()
	defeat_visual_requested.emit(snapshot)
	_current_morale = 0.0
	_reload_in_progress = false
	reload_state_changed.emit()
	soldier_defeated.emit(_grid_cell)
	queue_free()


# --- Moral (T024) ---------------------------------------------------------

## Suma moral únicamente por una eliminación confirmada mientras el soldado
## dispara con munición disponible (modo RIFLE; FR-006) — nunca por un
## impacto que no mata, y nunca por una eliminación a machete (modo MELEE,
## ver `_attack_current_melee_target()`).
func _register_kill() -> void:
	_current_morale += stats.moral_per_kill
	moral_changed.emit(_current_morale)
	reload_state_changed.emit()


# --- Prioridad de objetivo (T021) -----------------------------------------

## Elige, entre `candidates`, el enemigo más avanzado hacia la posición
## defendida (`spec.md` Assumptions) — sin dividir fuego (FR-002).
func _pick_priority_target(candidates: Array[Node2D]) -> Node2D:
	var best: Node2D = null
	var best_score: float = -INF
	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var score := _advance_score(candidate)
		if score > best_score:
			best_score = score
			best = candidate
	return best


## Mayor valor = más avanzado hacia la posición defendida. Usa
## `get_advance_progress()` del enemigo si existe (contrato asumido, ver
## comentario de cabecera); si no, cae en la cercanía a este soldado como
## proxy razonable dentro de un área de detección pequeña.
func _advance_score(enemy: Node2D) -> float:
	if enemy.has_method("get_advance_progress"):
		return enemy.call("get_advance_progress")
	return -global_position.distance_squared_to(enemy.global_position)


# --- Presentación observacional (004/T008) --------------------------------

func _on_moral_changed_visual(_new_morale: float) -> void:
	_sprite.play_confirmed_morale()
