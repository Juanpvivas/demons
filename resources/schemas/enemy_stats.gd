## Molde de datos base/máximos para un tipo de enemigo (ej.
## `enemigo_infanteria_base.tres`).
##
## Regla de límite dato/estado (`docs/ARCHITECTURE.md` §4.3): estos campos son
## siempre valores base/máximos, de solo lectura y compartidos entre todas las
## instancias que cargan el mismo `.tres`. NUNCA se mutan en tiempo de
## ejecución — el estado que cambia mientras se juega (salud actual) vive en
## variables propias de `enemigo.gd`.
class_name EnemyStats
extends Resource

## Vida total del enemigo.
@export_range(1, 500, 1) var max_health: int = 20

## Velocidad de avance hacia la posición defendida, en píxeles/segundo.
@export_range(10.0, 500.0, 1.0) var move_speed: float = 60.0

## Daño infligido a un soldado en modo machete al alcanzarlo cuerpo a
## cuerpo (`spec.md` Edge Case: soldado derrotado en cuerpo a cuerpo).
@export_range(1, 100, 1) var melee_damage: int = 10

## Munición que suelta el enemigo al ser derrotado, recolectable por el
## jugador (FR-007).
@export_range(0, 50, 1) var ammo_drop: int = 5
