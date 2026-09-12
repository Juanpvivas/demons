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

## Molde de datos base/máximos de este enemigo — solo lectura, nunca mutado
## en runtime (`docs/ARCHITECTURE.md` §4.3).
@export var stats: EnemyStats

## Salud actual, runtime. Inicializada desde `stats.max_health` en `_ready()`.
var _current_health: int = 0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


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
	# T028: destello de impacto no letal — llamada directa (no señal, no hay
	# contrato de `contracts/signals.md` para "golpe recibido"), inocua para
	# los tests existentes que solo observan `take_damage`/`enemy_defeated`.
	_flash_hit()
	return false


## Mayor valor = más avanzado hacia la posición defendida (`spec.md`
## Assumptions), usado por `Soldado._advance_score()` para desempatar
## prioridad de objetivo. Con el eje de avance `+Y` asumido arriba, la
## posición global en `Y` es directamente esa métrica.
func get_advance_progress() -> float:
	return global_position.y


func _die() -> void:
	enemy_defeated.emit(stats.ammo_drop, global_position)
	_spawn_ammo_pickup()
	# `queue_free()`, nunca `free()` (`docs/ARCHITECTURE.md` §4.5): evita
	# use-after-free si algo más todavía tiene una referencia pendiente en
	# el mismo frame (ej. `Soldado._rifle_candidates`/`_melee_candidates`
	# antes de procesar `body_exited`). El feedback visual de muerte ya se
	# aplicó de forma síncrona vía `_on_enemy_defeated_visual` (conectado en
	# `_ready()`), antes de esta línea — el nodo sigue siendo válido durante
	# el resto de este frame porque `queue_free()` difiere la liberación.
	queue_free()


## T032: instancia la pickup de munición en la posición de muerte de este
## enemigo (FR-007) y notifica a `EconomyManager` para que emita
## `ammo_pickup_spawned` (`contracts/signals.md` — `EconomyManager` es el
## único emisor de esa señal, aunque quien instancia la escena sea este
## nodo, no el autoload). `pickup_id` es simplemente el `instance_id` de la
## pickup recién creada — suficiente para identificarla de forma única sin
## necesitar un contador global.
##
## Se agrega como hijo del padre de este enemigo (no de este nodo, que se
## libera a continuación vía `queue_free()`). `global_position` se asigna
## **después** de `add_child()` (no antes) para que se calcule respecto al
## transform real del padre en el árbol — si se asignara antes, con el nodo
## todavía sin padre, equivaldría a fijar la posición local asumiendo un
## padre en el origen, lo cual sería incorrecto si el contenedor de
## enemigos del nivel tiene su propio offset.
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
