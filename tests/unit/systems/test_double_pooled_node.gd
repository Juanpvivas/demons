extends Node2D
## Fixture de test para `test_object_pool.gd`: nodo mínimo que implementa el
## contrato opcional de `core/object_pool.gd` (`on_pool_acquired()` /
## `on_pool_released()`) para poder verificar que `ObjectPool` efectivamente
## invoca esos hooks en las transiciones, además de contar cuántas veces
## ocurre cada una.
##
## No pertenece a ninguna feature de gameplay — es infraestructura de test.

var acquired_count: int = 0
var released_count: int = 0


func on_pool_acquired() -> void:
	acquired_count += 1


func on_pool_released() -> void:
	released_count += 1
