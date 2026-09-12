## Soldado defensor: dispara automáticamente con fusil a un único objetivo
## prioritario dentro de "DeteccionRango" (carril frontal + diagonales) hasta
## agotar munición, y transiciona automáticamente a combate cuerpo a cuerpo
## con machete contra enemigos en "RangoMelee" (FR-002 a FR-006).
##
## `StaticBody2D` raíz (`docs/ARCHITECTURE.md` §5) — el soldado no se mueve,
## solo dispara/ataca desde su celda.
##
## Contrato asumido de `Enemigo` (todavía no implementado en este grupo de
## tareas — ver reporte de T017-T024 para el detalle completo):
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
class_name Soldado
extends StaticBody2D

## Grupo al que se espera que pertenezca todo `Enemigo` (contrato asumido,
## ver comentario de cabecera). Filtra los cuerpos detectados por las
## `Area2D` de este soldado.
const ENEMY_GROUP: String = "enemies"

## Modo de combate activo (`docs/ARCHITECTURE.md` §4.4).
enum SoldierMode { RIFLE, MELEE }

## Molde de datos base/máximos de este soldado — solo lectura, nunca
## mutado en runtime (`docs/ARCHITECTURE.md` §4.3).
@export var stats: UnitStats

## Munición actual, runtime. Inicializada desde `stats.max_ammo` en `_ready()`.
var _current_ammo: int = 0

## Moral acumulada por eliminación (FR-006). Persiste entre recargas;
## solo se pierde si el soldado es derrotado (fuera del alcance de estas
## tareas).
var _current_morale: float = 0.0

## Modo de combate activo.
var _mode: SoldierMode = SoldierMode.RIFLE

## Objetivo activo de fusil — nunca más de uno a la vez (FR-002).
var _current_target: Node2D = null

## Objetivo activo de machete — misma regla de "sin dividir fuego",
## aplicada también en modo cuerpo a cuerpo.
var _current_melee_target: Node2D = null

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

@onready var _deteccion_rango: Area2D = $DeteccionRango
@onready var _rango_melee: Area2D = $RangoMelee

## Munición llega a 0, justo antes de pasar a modo machete (FR-004).
signal ammo_depleted

## Cambio entre `RIFLE` y `MELEE`, en cualquier dirección.
signal mode_changed(new_mode: SoldierMode)

## Se acumuló moral por una eliminación confirmada (FR-006).
signal moral_changed(new_morale: float)


func _ready() -> void:
	assert(stats != null, "Soldado requiere un UnitStats asignado en 'stats'")
	_current_ammo = stats.max_ammo

	_deteccion_rango.body_entered.connect(_on_deteccion_rango_body_entered)
	_deteccion_rango.body_exited.connect(_on_deteccion_rango_body_exited)
	_rango_melee.body_entered.connect(_on_rango_melee_body_entered)
	_rango_melee.body_exited.connect(_on_rango_melee_body_exited)
	# El propio soldado escucha su señal para transicionar de modo — mismo
	# patrón ya documentado en `docs/ARCHITECTURE.md` §4.2.
	ammo_depleted.connect(_on_ammo_depleted)


func _physics_process(delta: float) -> void:
	match _mode:
		SoldierMode.RIFLE:
			_process_rifle(delta)
		SoldierMode.MELEE:
			_process_melee(delta)


# --- Modo fusil (T021, T022) --------------------------------------------

func _process_rifle(delta: float) -> void:
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
	# `.call()` en vez de `target.take_damage(...)`: `_current_target` está
	# tipado como `Node2D` (Enemigo todavía no existe como clase — ver
	# comentario de cabecera), y GDScript con tipado estático rechaza en
	# tiempo de compilación una llamada directa a un método que no existe
	# en `Node2D`. `Object.call()` sí es un método real de `Node2D`
	# (heredado de `Object`), por lo que el despacho dinámico compila sin
	# problema y sigue siendo tipado estático en todo lo demás.
	var killed: bool = target.call("take_damage", stats.damage_per_shot)
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
	# Solo se elige un objetivo nuevo si no hay uno activo — `spec.md`
	# Acceptance Scenario 3 (FR-002): un enemigo nuevo que entra NO le quita
	# el foco al objetivo actual, aunque el recién llegado esté más
	# avanzado. "Recalcular al entrar un enemigo nuevo" (`research.md` §1)
	# es la oportunidad de elegir objetivo cuando no había ninguno, no una
	# reevaluación que pueda robarle el foco a un objetivo ya en curso.
	if _current_target == null:
		_recompute_rifle_target()


func _on_deteccion_rango_body_exited(body: Node2D) -> void:
	if not _rifle_candidates.has(body):
		return
	_remove_rifle_candidate(body)


func _remove_rifle_candidate(body: Node2D) -> void:
	_rifle_candidates.erase(body)
	if body == _current_target:
		_current_target = null
		_recompute_rifle_target()


## Recalcula el objetivo prioritario solo en los 3 momentos que exige
## `research.md` §1 (entra un candidato nuevo, sale el targeteado, muere el
## targeteado) — nunca en `_process()`.
func _recompute_rifle_target() -> void:
	_current_target = _pick_priority_target(_rifle_candidates)


# --- Modo machete (T023) -------------------------------------------------

func _process_melee(delta: float) -> void:
	if _current_melee_target == null:
		return
	_melee_cooldown -= delta
	if _melee_cooldown > 0.0:
		return
	_attack_current_melee_target()
	_melee_cooldown = 1.0 / stats.fire_rate


func _attack_current_melee_target() -> void:
	var target := _current_melee_target
	var killed: bool = target.call("take_damage", _current_machete_damage())
	if killed:
		_register_kill()
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
	# Misma regla de "sin dividir fuego" que en modo fusil — ver comentario
	# de `_on_deteccion_rango_body_entered`.
	if _current_melee_target == null:
		_recompute_melee_target()


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
	_current_melee_target = _pick_priority_target(_melee_candidates)


func _on_ammo_depleted() -> void:
	_set_mode(SoldierMode.MELEE)


func _set_mode(new_mode: SoldierMode) -> void:
	if _mode == new_mode:
		return
	_mode = new_mode
	mode_changed.emit(_mode)


# --- Moral (T024) ---------------------------------------------------------

## Suma moral únicamente por una eliminación confirmada (fusil o machete;
## FR-006) — nunca por un impacto que no mata.
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
