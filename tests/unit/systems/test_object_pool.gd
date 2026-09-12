extends GutTest
## Test básico de `ObjectPool` (`core/object_pool.gd`). No tiene tarea de
## test dedicada en `tasks.md`, pero es infraestructura crítica reutilizada
## por T026 (pool de enemigos) y T042 (`WaveSpawner`), así que se verifica
## aquí su contrato real de reciclado: `release()` debe permitir que un
## `acquire()` posterior reutilice la MISMA instancia en vez de crear una
## nueva, y `acquire()` debe crear una nueva instancia si el pool está vacío
## (`docs/ARCHITECTURE.md` §4.5, `constitution.md` Principio IV).
##
## La escena poolable se arma en memoria con `PackedScene.pack()` sobre el
## fixture `test_double_pooled_node.gd` en vez de un `.tscn` en disco — evita
## un archivo de escena extra solo para testing y permite instanciar un nodo
## real de todas formas (no un doble simulado).

const PooledDoubleScript := preload("res://tests/unit/systems/test_double_pooled_node.gd")

var _pool: ObjectPool
var _pooled_scene: PackedScene


func before_each() -> void:
	_pooled_scene = PackedScene.new()
	var template := PooledDoubleScript.new()
	_pooled_scene.pack(template)
	template.free()

	_pool = ObjectPool.new()
	add_child_autofree(_pool)


## --- setup(): pre-población inicial ---

func test_setup_pre_instantiates_the_requested_initial_size() -> void:
	# Given/When: se configura el pool pidiendo 3 instancias iniciales
	_pool.setup(_pooled_scene, 3)

	# Then: hay 3 instancias ya disponibles sin necesidad de instanciar más
	assert_eq(
		_pool.available_count(), 3,
		"setup(scene, 3) debe dejar 3 instancias pre-instanciadas disponibles"
	)
	assert_eq(_pool.in_use_count(), 0, "ninguna instancia pre-poblada debe estar en uso todavía")


## --- acquire(): reutiliza si hay disponibles, crea si el pool está vacío ---

func test_acquire_creates_a_new_instance_when_pool_is_empty() -> void:
	# Given: un pool configurado sin pre-población (vacío)
	_pool.setup(_pooled_scene, 0)
	assert_eq(_pool.available_count(), 0, "precondición: el pool arranca sin instancias disponibles")

	# When: se pide una instancia
	var instance := _pool.acquire()

	# Then: se creó una instancia nueva y válida, y quedó registrada como en uso
	assert_not_null(instance, "acquire() sobre un pool vacío debe crear una instancia nueva, no null")
	assert_true(
		instance is PooledDoubleScript,
		"la instancia creada debe ser del tipo de la escena pooleada"
	)
	assert_eq(_pool.in_use_count(), 1, "la instancia recién creada debe contarse como en uso")
	assert_eq(_pool.available_count(), 0, "acquire() no debe dejar instancias disponibles de sobra")


func test_acquire_reuses_an_available_instance_instead_of_creating_new() -> void:
	# Given: un pool pre-poblado con una instancia disponible
	_pool.setup(_pooled_scene, 1)
	var pre_populated_instance := _pool.acquire()
	_pool.release(pre_populated_instance)
	assert_eq(_pool.available_count(), 1, "precondición: la instancia liberada vuelve a estar disponible")

	# When: se vuelve a pedir una instancia
	var reacquired_instance := _pool.acquire()

	# Then: acquire() debe entregar la MISMA instancia que ya existía, no crear otra
	assert_eq(
		reacquired_instance, pre_populated_instance,
		"acquire() debe reutilizar la instancia disponible en vez de instanciar una nueva"
	)
	assert_eq(_pool.available_count(), 0, "la única instancia disponible pasó a estar en uso")
	assert_eq(_pool.in_use_count(), 1, "la instancia reutilizada debe contarse como en uso")


## --- release(): comportamiento de reciclado real end-to-end ---

func test_release_then_acquire_reuses_the_same_instance_rather_than_creating_a_new_one() -> void:
	# Given: una instancia adquirida de un pool vacío (forzando creación real)
	_pool.setup(_pooled_scene, 0)
	var first_instance := _pool.acquire()

	# When: se libera y se vuelve a adquirir
	_pool.release(first_instance)
	var second_instance := _pool.acquire()

	# Then: es la misma instancia — el pool recicló en vez de crear una nueva
	assert_eq(
		second_instance, first_instance,
		"un acquire() posterior a un release() debe reutilizar la misma instancia liberada"
	)


func test_release_moves_instance_from_in_use_to_available() -> void:
	# Given: una instancia en uso
	_pool.setup(_pooled_scene, 0)
	var instance := _pool.acquire()
	assert_eq(_pool.in_use_count(), 1, "precondición: la instancia adquirida está en uso")

	# When: se libera
	_pool.release(instance)

	# Then: los contadores reflejan la liberación
	assert_eq(_pool.in_use_count(), 0, "release() debe sacar la instancia de la lista de en-uso")
	assert_eq(_pool.available_count(), 1, "release() debe dejar la instancia disponible para reciclar")


func test_release_of_instance_not_belonging_to_pool_is_ignored_safely() -> void:
	# Given: un nodo cualquiera que nunca salió de este pool
	_pool.setup(_pooled_scene, 0)
	var foreign_instance := PooledDoubleScript.new()
	autofree(foreign_instance)

	# When/Then: liberar ese nodo no debe alterar el estado del pool ni fallar
	_pool.release(foreign_instance)
	assert_eq(_pool.available_count(), 0, "release() de un nodo ajeno no debe agregarlo a disponibles")
	assert_eq(_pool.in_use_count(), 0, "release() de un nodo ajeno no debe afectar el conteo de en-uso")


## --- Hooks opcionales on_pool_acquired()/on_pool_released() ---

func test_acquire_invokes_on_pool_acquired_hook_on_the_instance() -> void:
	_pool.setup(_pooled_scene, 1)

	var instance := _pool.acquire() as PooledDoubleScript

	assert_eq(
		instance.acquired_count, 1,
		"acquire() debe invocar on_pool_acquired() en la instancia entregada"
	)


func test_release_invokes_on_pool_released_hook_on_the_instance() -> void:
	# Nota: released_count no arranca necesariamente en 0 — _instantiate()
	# también pasa por _deactivate() para normalizar el estado inicial de una
	# instancia recién creada (equivalente a "recién liberada"). Por eso se
	# mide el incremento causado específicamente por release(), no el valor
	# absoluto.
	_pool.setup(_pooled_scene, 1)
	var instance := _pool.acquire() as PooledDoubleScript
	var released_count_before_release := instance.released_count

	_pool.release(instance)

	assert_eq(
		instance.released_count, released_count_before_release + 1,
		"release() debe invocar on_pool_released() exactamente una vez en la instancia devuelta"
	)


func test_reused_instance_receives_on_pool_acquired_again_on_second_acquire() -> void:
	# Given: una instancia reciclada (adquirida, liberada)
	_pool.setup(_pooled_scene, 1)
	var instance := _pool.acquire() as PooledDoubleScript
	_pool.release(instance)

	# When: se vuelve a adquirir la misma instancia reciclada
	_pool.acquire()

	# Then: el hook de adquisición se invoca de nuevo (segunda vez en total)
	assert_eq(
		instance.acquired_count, 2,
		"cada acquire() de una instancia reciclada debe volver a invocar on_pool_acquired()"
	)
