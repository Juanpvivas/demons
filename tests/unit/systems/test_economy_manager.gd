extends GutTest
## T013: test del autoload EconomyManager (`autoloads/economy_manager.gd`) —
## cubre "consumo/recolección de munición" de `constitution.md` Principio II.
##
## Estado en este punto (T008 recién completado): EconomyManager es solo
## estructura de datos + señales (`collected_ammo`, `ammo_pool_changed`,
## `ammo_pickup_spawned`). NO existen todavía `try_spend_ammo`/`add_ammo`
## (llegan en T033) ni la señal `deploy_or_reload_rejected` (también T033).
## Este archivo cubre por ahora lo que SÍ existe: la estructura base y que
## las señales declaradas en `contracts/signals.md` son reales y escuchables.
##
## EconomyManager no está registrado todavía como autoload en project.godot
## (eso es T010, tarea separada) — por eso se carga el script directamente
## con `load()` + `.new()` en vez de referenciar un singleton global, igual
## que hace `test_resource_schemas.gd` con los Resource schemas.
##
## TODO (T029, cuando T033 implemente try_spend_ammo/add_ammo en este mismo
## archivo): agregar aquí
##   - test de que add_ammo(n) suma a collected_ammo y emite
##     ammo_pool_changed con el nuevo total.
##   - test de que try_spend_ammo(n) con fondos suficientes resta de
##     collected_ammo, emite ammo_pool_changed y retorna éxito (true).
##   - test de que try_spend_ammo(n) con fondos insuficientes NO modifica
##     collected_ammo, emite deploy_or_reload_rejected(reason) en vez de
##     ammo_pool_changed, y retorna fracaso (false) — cubre FR-011.
##   - edge case: gastar exactamente el total disponible (deja el pool en 0
##     sin rechazo).

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


## --- Lo que NO existe todavía (documentado explícitamente, no un olvido) ---

func test_try_spend_ammo_does_not_exist_yet_before_t033() -> void:
	# Este test es intencional: confirma el estado esperado de "TDD
	# incremental" en este punto del plan (T008 completo, T033 pendiente).
	# Cuando T033 implemente try_spend_ammo, este test DEBE eliminarse junto
	# con el resto de este bloque, como parte del trabajo de T029.
	assert_false(
		_economy_manager.has_method("try_spend_ammo"),
		"try_spend_ammo no debe existir todavía (llega en T033) — si este test falla, actualizar T029"
	)


func test_add_ammo_does_not_exist_yet_before_t033() -> void:
	assert_false(
		_economy_manager.has_method("add_ammo"),
		"add_ammo no debe existir todavía (llega en T033) — si este test falla, actualizar T029"
	)
