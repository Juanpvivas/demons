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
class_name Enemigo
extends CharacterBody2D

## Grupo que identifica a todo `Enemigo` ante los sistemas de detección de
## `Soldado` (`Soldado.ENEMY_GROUP`, mismo literal).
const ENEMY_GROUP: String = "enemies"

## El enemigo fue eliminado (por disparo o por machete). Payload por
## contrato (`contracts/signals.md`): munición que suelta y su posición en
## el momento de morir, para que quien escuche (ej. `EconomyManager`, fuera
## del alcance de esta tarea) pueda generar una pickup en ese punto.
signal enemy_defeated(ammo_dropped: int, position: Vector2)

## Molde de datos base/máximos de este enemigo — solo lectura, nunca mutado
## en runtime (`docs/ARCHITECTURE.md` §4.3).
@export var stats: EnemyStats

## Salud actual, runtime. Inicializada desde `stats.max_health` en `_ready()`.
var _current_health: int = 0


func _ready() -> void:
	assert(stats != null, "Enemigo requiere un EnemyStats asignado en 'stats'")
	_current_health = stats.max_health
	add_to_group(ENEMY_GROUP)


func _physics_process(_delta: float) -> void:
	velocity = Vector2(0.0, stats.move_speed)
	move_and_slide()


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
	return false


## Mayor valor = más avanzado hacia la posición defendida (`spec.md`
## Assumptions), usado por `Soldado._advance_score()` para desempatar
## prioridad de objetivo. Con el eje de avance `+Y` asumido arriba, la
## posición global en `Y` es directamente esa métrica.
func get_advance_progress() -> float:
	return global_position.y


func _die() -> void:
	enemy_defeated.emit(stats.ammo_drop, global_position)
	# `queue_free()`, nunca `free()` (`docs/ARCHITECTURE.md` §4.5): evita
	# use-after-free si algo más todavía tiene una referencia pendiente en
	# el mismo frame (ej. `Soldado._rifle_candidates`/`_melee_candidates`
	# antes de procesar `body_exited`).
	queue_free()
