## Soldado defensor: dispara automáticamente con fusil a un único objetivo
## prioritario dentro de "DeteccionRango" (carril frontal + diagonales) hasta
## agotar munición, y transiciona automáticamente a combate cuerpo a cuerpo
## con machete contra enemigos en "RangoMelee" (FR-002 a FR-006).
##
## `StaticBody2D` raíz (`docs/ARCHITECTURE.md` §5) — el soldado no se mueve,
## solo dispara/ataca desde su celda.
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
## **T053, rehecha — daño mutuo dentro de "RangoMelee" (`spec.md` Edge Case:
## "un soldado en modo cuerpo a cuerpo es derrotado por los enemigos")**: la
## implementación original de T053 le daba a `Enemigo` su propia `Area2D`
## "RangoAtaque" para detectar y atacar a este soldado. `qa-validator`
## encontró con evidencia empírica que una `Area2D` hija de un
## `CharacterBody2D` que llama `move_and_slide()` en cada `_physics_process`
## (como sería "RangoAtaque" sobre `Enemigo`) nunca actualiza su lista
## interna de overlaps contra un `StaticBody2D` (este `Soldado`) — esa
## `Area2D` nunca dispararía `body_entered`/`body_exited` contra un `Soldado`
## real en juego real. Decisión de la persona dueña del proyecto: invertir
## qué lado dispara la interacción. Este soldado ahora es quien, desde la
## misma "RangoMelee" que ya usa de forma fiable para atacar a machete
## (T023), también se aplica a sí mismo el daño de cualquier `Enemigo`
## presente ahí, vía `get_melee_damage()` de cada uno — ver
## `_process_incoming_melee_damage()`.
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
extends StaticBody2D

## Grupo al que se espera que pertenezca todo `Enemigo` (contrato asumido,
## ver comentario de cabecera). Filtra los cuerpos detectados por las
## `Area2D` de este soldado.
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

## Modo de combate activo (`docs/ARCHITECTURE.md` §4.4).
enum SoldierMode { RIFLE, MELEE }

## Molde de datos base/máximos de este soldado — solo lectura, nunca
## mutado en runtime (`docs/ARCHITECTURE.md` §4.3).
@export var stats: UnitStats
@export var board_config: LaneBoardConfig = preload("res://resources/levels/monte_calvo_board.tres")

## Munición actual, runtime. Inicializada desde `stats.max_ammo` en `_ready()`.
var _current_ammo: int = 0

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

## Objetivo activo de fusil — nunca más de uno a la vez (FR-002).
var _current_target: Node2D = null
var _current_target_generation: int = -1

## Objetivo activo de machete — misma regla de "sin dividir fuego",
## aplicada también en modo cuerpo a cuerpo.
var _current_melee_target: Node2D = null
var _current_melee_generation: int = -1

## Candidatos actualmente dentro de "DeteccionRango" (no se re-escanea la
## escena en `_process()` — `research.md` §1).
var _rifle_candidates: Array[Node2D] = []

## Candidatos actualmente dentro de "RangoMelee".
var _melee_candidates: Array[Node2D] = []

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

@onready var _deteccion_rango: Area2D = $DeteccionRango
@onready var _rango_melee: Area2D = $RangoMelee
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
	_current_ammo = stats.max_ammo
	_current_health = stats.max_health

	_deteccion_rango.body_entered.connect(_on_deteccion_rango_body_entered)
	_deteccion_rango.body_exited.connect(_on_deteccion_rango_body_exited)
	_rango_melee.body_entered.connect(_on_rango_melee_body_entered)
	_rango_melee.body_exited.connect(_on_rango_melee_body_exited)
	# El propio soldado escucha su señal para transicionar de modo — mismo
	# patrón ya documentado en `docs/ARCHITECTURE.md` §4.2.
	ammo_depleted.connect(_on_ammo_depleted)
	mode_changed.connect(_sprite.observe_mode)
	moral_changed.connect(_on_moral_changed_visual)
	_sprite.reset_visual(_mode)


func _physics_process(delta: float) -> void:
	if _current_health <= 0 or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		_current_target = null
		_current_melee_target = null
		return
	match _mode:
		SoldierMode.RIFLE:
			_process_rifle(delta)
		SoldierMode.MELEE:
			_process_melee(delta)
	# T053 (rehecha): daño mutuo, independiente del modo activo (ver
	# comentario de `_incoming_melee_cooldown`).
	_process_incoming_melee_damage(delta)


# --- Modo fusil (T021, T022) --------------------------------------------

func _process_rifle(delta: float) -> void:
	if not _is_rifle_eligible(_current_target) or _generation_of(_current_target) != _current_target_generation:
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


func _on_deteccion_rango_body_entered(body: Node2D) -> void:
	if not body.is_in_group(ENEMY_GROUP) or _rifle_candidates.has(body):
		return
	_rifle_candidates.append(body)
	# Se elige durante el tick físico: incluye todos los cuerpos que entraron
	# juntos y nunca reemplaza un blanco que continúa siendo elegible.


func _on_deteccion_rango_body_exited(body: Node2D) -> void:
	if not _rifle_candidates.has(body):
		return
	_remove_rifle_candidate(body)


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
	if not _is_melee_eligible(_current_melee_target) or _generation_of(_current_melee_target) != _current_melee_generation:
		_recompute_melee_target()
	if _current_melee_target == null:
		return
	_melee_cooldown -= delta
	if _melee_cooldown > 0.0:
		return
	_attack_current_melee_target()
	_melee_cooldown = 1.0 / stats.fire_rate


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


func _on_rango_melee_body_entered(body: Node2D) -> void:
	if not body.is_in_group(ENEMY_GROUP) or _melee_candidates.has(body):
		return
	_melee_candidates.append(body)
	# La selección se difiere al tick físico, como en fusil.


func _on_rango_melee_body_exited(body: Node2D) -> void:
	if not _melee_candidates.has(body):
		return
	_remove_melee_candidate(body)


func _remove_melee_candidate(body: Node2D) -> void:
	_melee_candidates.erase(body)
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
## él mismo solo pueda atacar a uno a la vez. Se dispara desde este lado
## (`Soldado`, `StaticBody2D`) porque es el que detecta overlaps de forma
## fiable — ver la nota de motor documentada en la cabecera de este archivo
## y en `enemigo.gd`.
func _process_incoming_melee_damage(delta: float) -> void:
	if _melee_candidates.is_empty():
		return
	_incoming_melee_cooldown -= delta
	if _incoming_melee_cooldown > 0.0:
		return
	for enemy in _melee_candidates:
		if not _is_melee_eligible(enemy) or not enemy.has_method("get_melee_damage"):
			continue
		# `take_damage()` es defensivo ante llamadas repetidas una vez que
		# `_current_health` llega a 0 (ver cabecera de esa función) — seguro
		# de llamar por cada enemigo restante aunque uno anterior ya haya
		# derrotado a este soldado en esta misma pasada.
		take_damage(enemy.call("get_melee_damage"))
	_incoming_melee_cooldown = _INCOMING_MELEE_ATTACK_INTERVAL


func _is_live_candidate(body: Node2D) -> bool:
	if not is_instance_valid(body) or body.is_queued_for_deletion() or not body.is_in_group(ENEMY_GROUP):
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
	return _is_live_candidate(body) and body.global_position.x > global_position.x \
		and _candidate_cell(body).y == _grid_cell.y and _body_overlaps_range(body, _melee_shape)


## Solape de las formas reales, sin convertir el extremo del área en una
## distancia al centro del enemigo ni asumir que todos los cuerpos miden igual.
func _body_overlaps_range(body: Node2D, range_shape: CollisionShape2D) -> bool:
	var collider := body as CollisionObject2D
	if collider == null:
		return false
	for owner_id: int in collider.get_shape_owners():
		if collider.is_shape_owner_disabled(owner_id):
			continue
		var body_transform := collider.global_transform * collider.shape_owner_get_transform(owner_id)
		for shape_id in collider.shape_owner_get_shape_count(owner_id):
			var shape := collider.shape_owner_get_shape(owner_id, shape_id)
			if range_shape.shape.collide(range_shape.global_transform, shape, body_transform):
				return true
	return false


func _on_ammo_depleted() -> void:
	_set_mode(SoldierMode.MELEE)


## Recarga pública (T034, FR-009): gasta munición recolectada vía
## `EconomyManager.try_spend_ammo()` con el costo de una recarga completa
## (`stats.deploy_ammo_cost`, `spec.md` Assumptions: "una recarga completa"
## y `data-model.md`: costo de despliegue = costo de recarga, no hay campo
## separado). Si hay fondos suficientes, repone `_current_ammo` a
## `stats.max_ammo` y vuelve a modo `RIFLE` (`data-model.md`: "MELEE →
## RIFLE: al recargar"). `_current_morale` NUNCA se toca aquí — persiste
## entre recargas (`spec.md` Assumptions, `data-model.md` fila
## `_current_morale`). Si `try_spend_ammo()` falla (fondos insuficientes),
## `EconomyManager` ya emitió `deploy_or_reload_rejected` (FR-011) y este
## soldado permanece en su modo actual sin más efecto.
func reload() -> void:
	if _current_health <= 0 or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return
	if not EconomyManager.try_spend_ammo(stats.deploy_ammo_cost):
		return
	_current_ammo = stats.max_ammo
	_set_mode(SoldierMode.RIFLE)


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
	if _current_health <= 0:
		_die()
		return true
	if amount > 0:
		_sprite.play_confirmed_hit()
	return false


func _die() -> void:
	var snapshot := _sprite.capture_defeat_snapshot(global_position)
	_sprite.deactivate_visual()
	defeat_visual_requested.emit(snapshot)
	_current_morale = 0.0
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
