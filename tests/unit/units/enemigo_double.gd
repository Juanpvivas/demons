extends CharacterBody2D
## Test double del contrato de `Enemigo` (`scenes/enemies/enemigo.gd`).
## Conserva el log tras morir para las aserciones, pero retira grupo/colisión
## como el actor real: una consulta física no puede readquirir su cadáver.
##
## - Pertenece al grupo `"enemies"` (`Soldado.ENEMY_GROUP`), usado para
##   filtrar los cuerpos detectados por el soldado.
## - Expone `take_damage(amount: int) -> bool`, que aplica el daño y
##   retorna `true` únicamente si ese impacto dejó `health` en 0 o menos.
## - Expone opcionalmente `get_advance_progress() -> float` (mayor valor =
##   más avanzado hacia la posición defendida).
## - Expone `get_melee_damage() -> int` (T053, rehecha), usado por
##   `soldado.gd` para aplicarse a sí mismo el daño mutuo mientras este
##   double esté dentro de "RangoMelee". Configurable vía `melee_damage`,
##   con default 0 (sin daño) para no romper ningún test existente
##   (T015-T034) que reutiliza este double sin haber configurado esto nunca.
##
## Es un `CharacterBody2D` (igual que especifica `docs/ARCHITECTURE.md` §5
## para `EnemigoBase.tscn`) con una `CollisionShape2D` propia y las capas de
## colisión por defecto del proyecto. Vive sólo en tests.

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

## Valor que devuelve `get_melee_damage()`. Default 0 para no infligir daño
## mutuo sobre `Soldado` en ningún test que no lo configure explícitamente
## (T015-T034, escritos antes de que existiera este contrato).
var melee_damage: int = 0


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
	if health <= 0:
		return false
	damage_received.append(amount)
	health -= amount
	if health > 0:
		return false
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	return true


func get_advance_progress() -> float:
	return advance_progress


func get_melee_damage() -> int:
	return melee_damage
