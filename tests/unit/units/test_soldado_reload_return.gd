extends GutTest
## 005/T034: transacción y retorno observados con cuerpos/ticks reales.
const SoldierScene := preload("res://scenes/units/Soldado.tscn")
const EnemyScene := preload("res://scenes/enemies/EnemigoBase.tscn")
var _world: Node2D
var _soldier: Soldado
var _saved_state: int
var _saved_ammo: int


func before_each() -> void:
	_saved_state = GameStateManager._current_state
	_saved_ammo = EconomyManager.collected_ammo
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	EconomyManager.collected_ammo = 100
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	_world = Node2D.new()
	viewport.add_child(_world)
	_soldier = SoldierScene.instantiate() as Soldado
	_soldier.stats = _soldier.stats.duplicate()
	_soldier.stats.max_health = 500
	_soldier.position = Vector2(144, 336)
	_soldier.set_grid_cell(Vector2i(1, 3))
	_world.add_child(_soldier)


func after_each() -> void:
	GameStateManager._current_state = _saved_state
	EconomyManager.collected_ammo = _saved_ammo


func _empty(outside := false) -> void:
	# Fixture de estado: disparo/agote real ya cubierto por I2. Retorno usa física real.
	_soldier.set("_current_ammo", 0)
	_soldier.set("_mode", Soldado.SoldierMode.MELEE)
	_soldier.set("_current_morale", 3.0)
	_soldier.take_damage(7)
	if outside:
		_soldier.position.x += 120.0


func _enemy(position: Vector2) -> Enemigo:
	var enemy := EnemyScene.instantiate() as Enemigo
	enemy.stats = enemy.stats.duplicate()
	enemy.stats.max_health = 500
	enemy.stats.move_speed = 0.0
	enemy.position = position
	_world.add_child(enemy)
	enemy.prepare_for_spawn(enemy.stats, position, 2, Enemigo.SpawnOrigin.INITIAL)
	return enemy


func test_empty_living_home_accepts_exact_cost_preserving_health_morale_and_identity() -> void:
	_empty()
	var before := _soldier.get_reload_state()
	EconomyManager.collected_ammo = _soldier.stats.deploy_ammo_cost
	assert_true(_soldier.can_reload(), "Vivo, vacío y fondos exactos es elegible")
	assert_true(_soldier.request_reload(), "La orden válida se acepta")
	var after := _soldier.get_reload_state()
	assert_eq(EconomyManager.collected_ammo, 0)
	assert_eq(after.ammo, _soldier.stats.max_ammo)
	assert_eq(after.health, before.health)
	assert_eq(after.morale, before.morale)
	assert_eq(after.instance_id, before.instance_id)
	assert_eq(_soldier.global_position, Vector2(144, 336))
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.HOME)
	assert_eq(after.mode, Soldado.SoldierMode.RIFLE)
	assert_false(_soldier.can_reload(), "Carga llena deshabilita una segunda recarga")


func test_partial_and_full_load_reject_without_mutation(ammo = use_parameters([1, 10])) -> void:
	_soldier.set("_current_ammo", ammo)
	var before := _soldier.get_reload_state()
	assert_false(_soldier.can_reload())
	assert_false(_soldier.request_reload())
	assert_eq(_soldier.get_reload_state(), before)
	assert_eq(EconomyManager.collected_ammo, 100)


func test_insufficient_funds_reject_then_funding_allows_retry_without_stuck_guard() -> void:
	_empty()
	EconomyManager.collected_ammo = _soldier.stats.deploy_ammo_cost - 1
	var before := _soldier.get_reload_state()
	assert_false(_soldier.request_reload())
	assert_eq(_soldier.get_reload_state(), before)
	assert_eq(EconomyManager.collected_ammo, _soldier.stats.deploy_ammo_cost - 1)
	EconomyManager.add_ammo(1)
	assert_true(_soldier.can_reload(), "El rechazo no deja una orden bloqueada")
	assert_true(_soldier.request_reload())
	assert_eq(EconomyManager.collected_ammo, 0)


func test_terminal_and_dead_reject_without_spend() -> void:
	_empty()
	GameStateManager.report_reached_defended_position()
	assert_false(_soldier.can_reload())
	assert_false(_soldier.request_reload())
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	_soldier.take_damage(9999)
	assert_false(_soldier.can_reload())
	assert_false(_soldier.request_reload())
	assert_eq(EconomyManager.collected_ammo, 100)


func test_spend_callback_cannot_reenter_and_return_accepts_only_one_charge() -> void:
	_empty(true)
	var balances: Array[int] = []
	var nested: Array[bool] = []
	var listener := func(amount: int) -> void:
		balances.append(amount)
		nested.append(_soldier.can_reload())
		nested.append(_soldier.request_reload())
	EconomyManager.ammo_pool_changed.connect(listener)
	var accepted := _soldier.request_reload()
	EconomyManager.ammo_pool_changed.disconnect(listener)
	assert_true(accepted)
	assert_eq(balances, [100 - _soldier.stats.deploy_ammo_cost], "Un solo gasto notificado")
	assert_eq(nested, [false, false], "El bloqueo existe ANTES del callback síncrono")
	assert_false(_soldier.request_reload())
	assert_eq(EconomyManager.collected_ammo, 100 - _soldier.stats.deploy_ammo_cost)


func test_return_moves_same_actor_at_own_speed_and_resumes_rifle_only_at_home(
		speed = use_parameters([40.0, 73.0])) -> void:
	_empty(true)
	_soldier.stats.return_speed = speed
	var home := _soldier.get_home_position()
	var identity := _soldier.get_instance_id()
	var health: int = _soldier.get_reload_state().health
	var morale: float = _soldier.get_reload_state().morale
	var enemy := _enemy(_soldier.position + Vector2(200, 0))
	assert_true(_soldier.request_reload())
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.RETURNING)
	assert_eq(_soldier.get_reload_state().ammo, _soldier.stats.max_ammo)
	var start := _soldier.position
	var frame := Engine.get_physics_frames()
	await wait_physics_frames(30)
	var elapsed := float(Engine.get_physics_frames() - frame) / Engine.physics_ticks_per_second
	assert_almost_eq(start.x - _soldier.position.x, speed * elapsed, 1.3, "Regreso físico a velocidad propia")
	assert_eq(_soldier.position.y, home.y)
	assert_eq(enemy.get("_current_health"), 500, "No dispara durante retorno aun con blanco en alcance")
	assert_eq(_soldier.get_reload_state().ammo, _soldier.stats.max_ammo)
	assert_eq(_soldier.get_instance_id(), identity)
	assert_eq(_soldier.get_reload_state().health, health)
	assert_eq(_soldier.get_reload_state().morale, morale)
	assert_false(_soldier.can_reload())
	await wait_physics_frames(210)
	assert_almost_eq(_soldier.position.x, home.x, 0.01, "Llega sin sobrepasar ni oscilar")
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.HOME)
	# Poner un blanco en alcance del hogar comprueba reanudación real del fusil.
	enemy.position = home + Vector2(200, 0)
	await wait_physics_frames(8)
	assert_lt(enemy.get("_current_health"), 500, "Solo al llegar reanuda el fusil")


func test_return_is_vulnerable_without_melee_and_death_cancels_without_refund() -> void:
	_empty(true)
	# Enemigo detrás bloquea físicamente el regreso y mantiene contacto real.
	var enemy := _enemy(_soldier.position - Vector2(48, 0))
	assert_true(_soldier.request_reload())
	var health: int = _soldier.get_reload_state().health
	await wait_physics_frames(75)
	assert_lt(_soldier.get_reload_state().health, health, "Recibe daño por contacto en regreso")
	assert_eq(enemy.get("_current_health"), 500, "No usa machete contra el contacto")
	assert_gt(_soldier.position.x, _soldier.get_home_position().x + 1.0, "El cuerpo impide atravesar")
	watch_signals(_soldier)
	_soldier.take_damage(9999)
	assert_signal_emit_count(_soldier, "soldier_defeated", 1)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.DEAD)
	assert_false(_soldier.request_reload())
	assert_eq(EconomyManager.collected_ammo, 100 - _soldier.stats.deploy_ammo_cost, "Sin reembolso ni resurrección")


func test_terminal_cancels_accepted_return_without_late_movement_or_attack() -> void:
	_empty(true)
	assert_true(_soldier.request_reload())
	await wait_physics_frames(8)
	GameStateManager.report_reached_defended_position()
	var position_before := _soldier.position
	await wait_physics_frames(12)
	assert_eq(_soldier.position, position_before)
	assert_false(_soldier.request_reload())
	assert_eq(EconomyManager.collected_ammo, 100 - _soldier.stats.deploy_ammo_cost)


func test_legacy_reload_cannot_bypass_partial_or_full_load_rejection(
		ammo = use_parameters([1, 10])) -> void:
	_soldier.set("_current_ammo", ammo)
	var before := _soldier.get_reload_state()
	_soldier.reload()
	assert_eq(EconomyManager.collected_ammo, 100, "API heredada también exige carga cero")
	assert_eq(_soldier.get_reload_state(), before)


func test_legacy_reload_outside_uses_one_transaction_and_physical_return() -> void:
	_empty(true)
	var before := _soldier.position
	_soldier.reload()
	assert_eq(EconomyManager.collected_ammo, 100 - _soldier.stats.deploy_ammo_cost)
	assert_eq(_soldier.get_reload_state().ammo, _soldier.stats.max_ammo)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.RETURNING)
	assert_eq(_soldier.position, before, "Aceptar no teletransporta")
	_soldier.reload()
	assert_eq(EconomyManager.collected_ammo, 100 - _soldier.stats.deploy_ammo_cost)


func test_return_front_contact_receives_damage_without_rifle_or_machete_counterattack() -> void:
	_empty(true)
	var enemy := _enemy(_soldier.position + Vector2(48, 0))
	enemy.stats.move_speed = 80.0
	assert_true(_soldier.request_reload())
	var health: int = _soldier.get_reload_state().health
	await wait_physics_frames(45)
	assert_eq(_soldier.get_movement_state(), Soldado.MovementState.RETURNING)
	assert_lt(_soldier.get_reload_state().health, health, "Perseguidor causa daño real durante regreso")
	assert_eq(enemy.get("_current_health"), 500, "Contacto frontal no habilita contraataque de machete ni fusil")
	assert_eq(_soldier.get_reload_state().ammo, _soldier.stats.max_ammo)
