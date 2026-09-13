## ObjectPool genérico y reutilizable (`docs/ARCHITECTURE.md` §4.5): recicla
## instancias de una escena en vez de instanciar/destruir en cada oleada
## (`constitution.md` Principio IV — Requisitos de Rendimiento). Pensado para
## enemigos y proyectiles por igual; no conoce nada específico de `Enemigo`
## ni de ningún proyectil concreto.
##
## No es autoload: es una utilidad instanciable, dueña de los nodos que
## reserva. Un nivel (o cualquier nodo) crea un `ObjectPool` por tipo de
## escena que necesite reciclar y lo añade a su árbol de escena (para que
## las instancias pooleadas tengan un padre válido mientras esperan
## reutilización).
##
## Uso típico:
##   var enemy_pool := ObjectPool.new(preload("res://scenes/enemies/EnemigoBase.tscn"), 20)
##   add_child(enemy_pool)
##   ...
##   var enemy := enemy_pool.acquire()
##   enemy.global_position = spawn_point
##   ...
##   enemy_pool.release(enemy)
##
## Contrato opcional con la escena pooleada: si el nodo raíz de la escena
## define los métodos `on_pool_acquired()` / `on_pool_released()`, el pool
## los llama en cada transición — así cada tipo de escena resetea su propio
## estado (salud, munición, posición, colisión) sin que `ObjectPool` necesite
## conocer nada específico de `Enemigo`/proyectiles (mantiene la separación
## de responsabilidades de `constitution.md` Principio I).
class_name ObjectPool
extends Node

## Emitida cada vez que el pool debe crear una instancia nueva (pool vacío,
## o pre-población inicial en `setup()`) — útil para depuración/telemetría
## de cuántas instancias reales llegó a necesitar un pool.
signal instance_created(instance: Node)

## Escena que este pool instancia. Se fija una única vez en `setup()`.
var _scene: PackedScene

## Instancias libres, listas para `acquire()`.
var _available: Array[Node] = []

## Instancias actualmente entregadas y no liberadas todavía — permite
## `release()` defensivo (ignora liberar algo que no salió de este pool).
var _in_use: Array[Node] = []


## Constructor de conveniencia: si se provee `scene`, equivale a llamar
## `setup(scene, initial_size)` inmediatamente. También se puede instanciar
## sin argumentos y llamar `setup()` más tarde.
func _init(scene: PackedScene = null, initial_size: int = 0) -> void:
	if scene != null:
		setup(scene, initial_size)


## Fija la escena que este pool reciclará y pre-instancia `initial_size`
## copias inactivas, listas para `acquire()` sin costo de instanciación en
## el primer uso. Puede llamarse una sola vez por pool.
func setup(scene: PackedScene, initial_size: int = 0) -> void:
	assert(_scene == null, "ObjectPool.setup() ya fue llamado — un pool no cambia de escena en runtime")
	assert(scene != null, "ObjectPool.setup() requiere una PackedScene válida")
	_scene = scene
	for i in initial_size:
		_available.append(_instantiate())


## Entrega una instancia lista para usar: reutiliza una libre del pool, o
## instancia una nueva si el pool está vacío. Nunca retorna null (asume
## `setup()` ya fue llamado).
func acquire() -> Node:
	assert(_scene != null, "ObjectPool.acquire() llamado antes de setup()")
	var instance: Node = _available.pop_back() if not _available.is_empty() else _instantiate()
	_in_use.append(instance)
	_activate(instance)
	return instance


## Devuelve una instancia al pool en vez de destruirla: la desactiva y la
## deja disponible para un futuro `acquire()`. Ignora silenciosamente
## instancias que no pertenecen a este pool (ya liberadas o de otro pool).
func release(instance: Node) -> void:
	if not _in_use.has(instance):
		return
	_in_use.erase(instance)
	_deactivate(instance)
	_available.append(instance)


## Cantidad de instancias libres, disponibles para `acquire()` sin
## instanciar una nueva.
func available_count() -> int:
	return _available.size()


## Cantidad de instancias actualmente entregadas (no liberadas todavía).
func in_use_count() -> int:
	return _in_use.size()


## Libera definitivamente todas las instancias del pool (disponibles y en
## uso) con `queue_free()` — nunca `free()` (`docs/ARCHITECTURE.md` §4.5),
## para evitar use-after-free si algo todavía tiene una referencia pendiente
## en el mismo frame. Se usa al descargar el nivel, fuera del ciclo de vida
## normal de reciclado.
func clear() -> void:
	for instance in _available:
		instance.queue_free()
	for instance in _in_use:
		instance.queue_free()
	_available.clear()
	_in_use.clear()


func _instantiate() -> Node:
	var instance: Node = _scene.instantiate()
	add_child(instance)
	_deactivate(instance)
	instance_created.emit(instance)
	return instance


func _activate(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is CanvasItem:
		instance.visible = true
	if instance.has_method("on_pool_acquired"):
		instance.on_pool_acquired()


func _deactivate(instance: Node) -> void:
	if instance.has_method("on_pool_released"):
		instance.on_pool_released()
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is CanvasItem:
		instance.visible = false
