extends CharacterBody2D
## Test double de `Enemigo` (`scenes/enemies/enemigo.gd`), que todavía no
## existe (lo implementa otro grupo en paralelo — T018/T025/T026 de
## `tasks.md`). Implementa exactamente el contrato asumido y documentado en
## la cabecera de `scenes/units/soldado.gd`:
##
## - Pertenece al grupo `"enemies"` (`Soldado.ENEMY_GROUP`), usado para
##   filtrar los cuerpos detectados por las `Area2D` "DeteccionRango" y
##   "RangoMelee" del soldado.
## - Expone `take_damage(amount: int) -> bool`, que aplica el daño y
##   retorna `true` únicamente si ese impacto dejó `health` en 0 o menos.
## - Expone opcionalmente `get_advance_progress() -> float` (mayor valor =
##   más avanzado hacia la posición defendida).
##
## Es un `CharacterBody2D` (igual que especifica `docs/ARCHITECTURE.md` §5
## para `EnemigoBase.tscn`) con una `CollisionShape2D` propia, para que las
## `Area2D` "DeteccionRango"/"RangoMelee" de `Soldado` puedan detectarlo vía
## `body_entered` real (capas de colisión por defecto = 1 en ambos lados,
## igual que en `Soldado.tscn`, que no las sobreescribe).
##
## Vive en `tests/unit/units/` (no en `scenes/enemies/`) para no pisar el
## trabajo del grupo que implementará el `Enemigo` real.

## Salud restante. Configurable antes de agregar el nodo al árbol.
var health: int = 100

## Log de cada llamada a `take_damage`, en orden — permite verificar tanto
## "cuántas veces" como "con qué daño exacto" fue golpeado este enemigo.
var damage_received: Array[int] = []

## Valor que devuelve `get_advance_progress()`. Irrelevante para T015 (no se
## testea prioridad de objetivo aquí, solo daño/munición/modo/moral), pero
## se deja disponible para no bloquear tests futuros de targeting que
## puedan reutilizar este double.
var advance_progress: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)


func take_damage(amount: int) -> bool:
	damage_received.append(amount)
	health -= amount
	return health <= 0


func get_advance_progress() -> float:
	return advance_progress
