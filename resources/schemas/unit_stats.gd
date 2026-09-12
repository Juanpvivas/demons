## Molde de datos base/máximos para un tipo de soldado (ej. `soldado_base_stats.tres`).
##
## Regla de límite dato/estado (`docs/ARCHITECTURE.md` §4.3): estos campos son
## siempre valores base/máximos, de solo lectura y compartidos entre todas las
## instancias que cargan el mismo `.tres`. NUNCA se mutan en tiempo de
## ejecución — el estado que cambia mientras se juega (munición actual, moral
## acumulada, modo activo) vive en variables propias de `soldado.gd`.
class_name UnitStats
extends Resource

@export_group("Fusil")

## Munición máxima al desplegar o recargar el soldado (FR-003).
@export_range(1, 100, 1) var max_ammo: int = 20

## Daño de cada disparo de fusil contra un enemigo.
@export_range(1, 50, 1) var damage_per_shot: int = 5

## Disparos por segundo mientras hay objetivo y munición disponible.
@export_range(0.1, 10.0, 0.1) var fire_rate: float = 1.5

@export_group("Machete")

## Daño mínimo de machete con moral acumulada en cero (spec.md Edge Case:
## el machete siempre debe infligir un daño base > 0, aunque reducido).
@export_range(1, 50, 1) var machete_base_damage: int = 3

## Multiplicador que escala el daño de machete por punto de moral
## acumulada (FR-005): daño total = machete_base_damage + moral * este valor.
@export_range(0.0, 10.0, 0.1) var machete_moral_multiplier: float = 1.0

## Moral ganada por cada eliminación mientras el soldado dispara con
## munición disponible (FR-006).
@export_range(0.0, 10.0, 0.1) var moral_per_kill: float = 1.0

@export_group("Despliegue")

## Costo en munición recolectada para desplegar un soldado nuevo de este
## tipo (`spec.md` Assumptions: equivalente a una recarga completa,
## normalmente igual a `max_ammo`).
@export_range(1, 100, 1) var deploy_ammo_cost: int = 20
