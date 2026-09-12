## Pickup de munición recolectable soltada por un `Enemigo` derrotado
## (FR-007/FR-008). Recolección **explícita** por tap/click sobre el propio
## `Area2D` (`research.md` §3) — NO por proximidad automática: el jugador
## debe interactuar directamente con la pickup, igual en mouse (PC) que en
## touch (Android/iOS), vía la acción `collect_pickup` del `InputMap`
## (`docs/ARCHITECTURE.md` §7, ya configurada en T003).
##
## Al recolectarse, suma `amount` al pool global vía
## `EconomyManager.add_ammo()` (FR-008) y se destruye a sí misma.
class_name AmmoPickup
extends Area2D

## Cantidad de munición que otorga al recolectarse (FR-007). Se asigna al
## instanciar la escena (ej. `Enemigo._die()`, a partir de
## `stats.ammo_drop` del enemigo derrotado) — nunca hardcodeada aquí.
@export var amount: int = 0


func _ready() -> void:
	# Conexión de señal solo en `_ready()` (`docs/ARCHITECTURE.md` §4.2).
	input_event.connect(_on_input_event)


## `Area2D.input_event(viewport, event, shape_idx)`: recibido cuando el
## jugador hace click/tap sobre la `CollisionShape2D` de esta pickup,
## siempre que `input_pickable` esté activo (ya lo está por defecto en
## `Area2D`, confirmado en `AmmoPickup.tscn`).
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("collect_pickup"):
		_collect()


func _collect() -> void:
	EconomyManager.add_ammo(amount)
	# `queue_free()`, nunca `free()` (`docs/ARCHITECTURE.md` §4.5): evita
	# use-after-free si algo más en este mismo frame todavía referencia esta
	# instancia (ej. el propio evento de input que sigue propagándose).
	queue_free()
