extends GutTest
## T013/T029: test del autoload EconomyManager (`autoloads/economy_manager.gd`)
## — cubre "consumo/recolección de munición" de `constitution.md` Principio II.
##
## T029 amplía la cobertura tras la implementación de T033
## (`try_spend_ammo`/`add_ammo`/`deploy_or_reload_rejected`), verificando el
## comportamiento observable descrito en `spec.md` FR-009/FR-010/FR-011 y
## User Story 2, Acceptance Scenario 4 (rechazo por munición insuficiente).
##
## Nota sobre `deploy_or_reload_rejected`: `contracts/signals.md` la lista
## bajo la tabla de `Soldado`, pero `EconomyManager` es quien la emite
## realmente (ver comentario en `economy_manager.gd` — decisión de T033
## siguiendo `tasks.md`). Estos tests verifican el comportamiento real del
## autoload; la corrección del contrato es responsabilidad del orquestador.
##
## EconomyManager no está registrado todavía como autoload en project.godot
## (eso es T010, tarea separada) — por eso se carga el script directamente
## con `load()` + `.new()` en vez de referenciar un singleton global, igual
## que hace `test_resource_schemas.gd` con los Resource schemas. Cada test
## obtiene una instancia nueva vía `before_each`, por lo que no hay estado
## compartido entre tests pese a que en producción esto sea un singleton.

const ECONOMY_MANAGER_SCRIPT_PATH := "res://autoloads/economy_manager.gd"

var _economy_manager: Node


func before_each() -> void:
	_economy_manager = load(ECONOMY_MANAGER_SCRIPT_PATH).new()
	add_child_autofree(_economy_manager)


## --- Estructura base (T008) ---

func test_economy_manager_script_extends_node() -> void:
	# Nota: se usa load() (no preload como const de nivel de script) porque
	# GDScript trata un `const X := preload(...)` como referencia a "clase"
	# y bloquea llamar métodos de instancia como get_instance_base_type()
	# directamente sobre él ("Make an instance instead") — mismo patrón que
	# test_resource_schemas.gd.
	var script := load(ECONOMY_MANAGER_SCRIPT_PATH)
	assert_eq(
		script.get_instance_base_type(), "Node",
		"EconomyManager debe extender Node (autoload de estado de partida, no Resource)"
	)


func test_economy_manager_instantiates() -> void:
	assert_not_null(_economy_manager, "EconomyManager.new() debe instanciar sin error")
	assert_true(_economy_manager is Node, "una instancia de EconomyManager debe ser un Node")


func test_collected_ammo_defaults_to_zero() -> void:
	# Given: un EconomyManager recién creado (inicio de partida, sin recolección aún)
	# Then: el pool de munición recolectada arranca en 0
	assert_eq(
		_economy_manager.collected_ammo, 0,
		"collected_ammo debe iniciar en 0 al arrancar la partida"
	)


func test_collected_ammo_field_is_typed_as_int() -> void:
	assert_typeof(_economy_manager.collected_ammo, TYPE_INT, "collected_ammo debe ser int")


## --- Señales declaradas en contracts/signals.md ---

func test_ammo_pool_changed_signal_exists() -> void:
	assert_true(
		_economy_manager.has_signal("ammo_pool_changed"),
		"EconomyManager debe declarar la señal ammo_pool_changed (contracts/signals.md)"
	)


func test_ammo_pickup_spawned_signal_exists() -> void:
	assert_true(
		_economy_manager.has_signal("ammo_pickup_spawned"),
		"EconomyManager debe declarar la señal ammo_pickup_spawned (contracts/signals.md)"
	)


func test_ammo_pool_changed_is_emitted_and_listenable_with_new_amount_payload() -> void:
	# No hay todavía lógica de negocio que dispare esta señal por sí sola
	# (add_ammo/try_spend_ammo son T033); este test confirma que la señal
	# existe con la firma correcta (new_amount) y es escuchable end-to-end
	# vía emisión manual — el requisito mínimo verificable en este punto.
	watch_signals(_economy_manager)

	_economy_manager.emit_signal("ammo_pool_changed", 5)

	assert_signal_emitted(_economy_manager, "ammo_pool_changed")
	assert_signal_emitted_with_parameters(_economy_manager, "ammo_pool_changed", [5])


func test_ammo_pickup_spawned_is_emitted_and_listenable_with_full_payload() -> void:
	watch_signals(_economy_manager)

	_economy_manager.emit_signal("ammo_pickup_spawned", "pickup_1", Vector2(10, 20), 3)

	assert_signal_emitted(_economy_manager, "ammo_pickup_spawned")
	assert_signal_emitted_with_parameters(
		_economy_manager, "ammo_pickup_spawned", ["pickup_1", Vector2(10, 20), 3]
	)


## --- add_ammo (FR-008: recolección de munición) ---

func test_add_ammo_increases_collected_ammo_by_given_amount() -> void:
	# Given: un pool en 0
	# When: se recolecta munición de un enemigo derrotado
	_economy_manager.add_ammo(5)

	# Then: el pool refleja la suma
	assert_eq(
		_economy_manager.collected_ammo, 5,
		"add_ammo(5) debe sumar 5 a collected_ammo"
	)


func test_add_ammo_accumulates_across_multiple_calls() -> void:
	_economy_manager.add_ammo(3)
	_economy_manager.add_ammo(4)

	assert_eq(
		_economy_manager.collected_ammo, 7,
		"llamadas sucesivas a add_ammo deben acumularse en collected_ammo"
	)


func test_add_ammo_emits_ammo_pool_changed_with_new_total() -> void:
	watch_signals(_economy_manager)

	_economy_manager.add_ammo(5)

	assert_signal_emitted(_economy_manager, "ammo_pool_changed")
	assert_signal_emitted_with_parameters(_economy_manager, "ammo_pool_changed", [5])


## --- try_spend_ammo con fondos suficientes (FR-009/FR-010, US2 Scenario 2/3) ---

func test_try_spend_ammo_with_sufficient_funds_returns_true() -> void:
	# Given: el jugador tiene munición recolectada suficiente
	_economy_manager.add_ammo(10)

	# When: recarga un soldado o despliega uno nuevo
	var success: bool = _economy_manager.try_spend_ammo(6)

	# Then: la operación se permite
	assert_true(success, "try_spend_ammo debe retornar true cuando hay fondos suficientes")


func test_try_spend_ammo_with_sufficient_funds_subtracts_from_pool() -> void:
	_economy_manager.add_ammo(10)

	_economy_manager.try_spend_ammo(6)

	assert_eq(
		_economy_manager.collected_ammo, 4,
		"try_spend_ammo(6) sobre un pool de 10 debe dejar collected_ammo en 4"
	)


func test_try_spend_ammo_with_sufficient_funds_emits_ammo_pool_changed_with_new_total() -> void:
	_economy_manager.add_ammo(10)
	watch_signals(_economy_manager)

	_economy_manager.try_spend_ammo(6)

	assert_signal_emitted(_economy_manager, "ammo_pool_changed")
	assert_signal_emitted_with_parameters(_economy_manager, "ammo_pool_changed", [4])


func test_try_spend_ammo_with_sufficient_funds_does_not_emit_rejection() -> void:
	_economy_manager.add_ammo(10)
	watch_signals(_economy_manager)

	_economy_manager.try_spend_ammo(6)

	assert_signal_not_emitted(
		_economy_manager, "deploy_or_reload_rejected",
		"un gasto exitoso no debe emitir deploy_or_reload_rejected"
	)


func test_try_spend_ammo_can_spend_exact_available_amount_leaving_pool_at_zero() -> void:
	# Edge case: gastar exactamente el total disponible no debe ser rechazado.
	_economy_manager.add_ammo(5)

	var success: bool = _economy_manager.try_spend_ammo(5)

	assert_true(success, "gastar exactamente el total disponible debe ser exitoso")
	assert_eq(_economy_manager.collected_ammo, 0, "el pool debe quedar en 0, no negativo")


## --- try_spend_ammo con fondos insuficientes (FR-011, US2 Scenario 4) ---

func test_try_spend_ammo_with_insufficient_funds_returns_false() -> void:
	# Given: el jugador NO tiene munición recolectada suficiente
	_economy_manager.add_ammo(3)

	# When: intenta recargar o desplegar un soldado
	var success: bool = _economy_manager.try_spend_ammo(10)

	# Then: el sistema le impide la acción
	assert_false(success, "try_spend_ammo debe retornar false cuando la munición es insuficiente")


func test_try_spend_ammo_with_insufficient_funds_does_not_mutate_collected_ammo() -> void:
	_economy_manager.add_ammo(3)

	_economy_manager.try_spend_ammo(10)

	assert_eq(
		_economy_manager.collected_ammo, 3,
		"un gasto rechazado no debe restar ni parcialmente del pool"
	)


func test_try_spend_ammo_with_insufficient_funds_emits_deploy_or_reload_rejected() -> void:
	_economy_manager.add_ammo(3)
	watch_signals(_economy_manager)

	_economy_manager.try_spend_ammo(10)

	# Then: el sistema le indica al jugador que no tiene recursos suficientes
	assert_signal_emitted(_economy_manager, "deploy_or_reload_rejected")
	assert_signal_emitted_with_parameters(
		_economy_manager, "deploy_or_reload_rejected", ["Munición insuficiente"]
	)


func test_try_spend_ammo_with_insufficient_funds_does_not_emit_ammo_pool_changed() -> void:
	_economy_manager.add_ammo(3)
	watch_signals(_economy_manager)

	_economy_manager.try_spend_ammo(10)

	assert_signal_not_emitted(
		_economy_manager, "ammo_pool_changed",
		"un gasto rechazado no debe emitir ammo_pool_changed (el pool no cambió)"
	)


func test_try_spend_ammo_with_zero_collected_ammo_is_rejected() -> void:
	# Edge case: pool vacío desde el inicio (sin ninguna recolección previa).
	var success: bool = _economy_manager.try_spend_ammo(1)

	assert_false(success, "intentar gastar con el pool en 0 debe ser rechazado")
	assert_eq(_economy_manager.collected_ammo, 0, "el pool debe permanecer en 0")
