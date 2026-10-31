extends GutTest
## 015: datos de producción y transacciones con actores reales, sin jugar99bajas.
const SOLDIER := preload("res://scenes/units/Soldado.tscn")
const ENEMY := preload("res://scenes/enemies/EnemigoBase.tscn")
const LEVEL := preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
var _saved: Dictionary
var _world: Node2D
var _level: Node

class ReentrantEnemy:
	extends Enemigo
	var during_damage: Callable
	var calls := 0
	var entered := false
	func take_damage(amount: int) -> bool:
		calls += 1
		if not entered and during_damage.is_valid():
			entered = true
			during_damage.call()
		return super.take_damage(amount)


func before_each() -> void:
	_saved = {"state": GameStateManager._current_state, "ammo": EconomyManager.collected_ammo, "waves": {}}
	for key: String in ["waves", "current_wave_index", "_total_enemies_in_current_wave", "_defeated_in_current_wave"]:
		_saved.waves[key] = WaveManager.get(key)
	WaveManager.cancel_waves()
	GameStateManager._current_state = GameStateManager.GameState.PLAYING
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	_world = Node2D.new()
	viewport.add_child(_world)
	_level = null


func after_each() -> void:
	if is_instance_valid(_level): _level.close_match()
	WaveManager.cancel_waves()
	GameStateManager._current_state = _saved.state
	EconomyManager.collected_ammo = _saved.ammo
	for key: String in _saved.waves: WaveManager.set(key, _saved.waves[key])


func _melee_owner() -> Soldado:
	var soldier: Soldado = SOLDIER.instantiate()
	soldier.stats = soldier.stats.duplicate()
	soldier.stats.machete_moral_per_kill = 2.0
	soldier.stats.machete_heal_per_kill = 3
	soldier.set_grid_cell(Vector2i(1, 3))
	soldier.position = Vector2(144, 336)
	_world.add_child(soldier)
	# Transacción puntual; la entrada física y cambio de arma se prueban en test_soldado.
	soldier.set_physics_process(false)
	soldier.set("_current_ammo", 0)
	soldier.set("_mode", Soldado.SoldierMode.MELEE)
	soldier.take_damage(5)
	return soldier


func _enemy(stats: EnemyStats, position: Vector2) -> Enemigo:
	var enemy: Enemigo = ENEMY.instantiate()
	enemy.stats = stats
	enemy.position = position
	_world.add_child(enemy)
	return enemy


func _dispose_unready_level(level: Node) -> void:
	# Estos servicios son miembros Node aún sin parent antes de _ready().
	for key: String in ["_wave_spawner", "_combat_visual_effects", "_combat_audio"]:
		var service: Node = level.get(key)
		if service.get_parent() == null: level.add_child(service)
	level.free()


func test_ten_authorized_profiles_and_spawn_timing_are_immutable() -> void:
	var expected_damage := [1, 1, 1, 1, 2, 2, 2, 2, 2, 3]
	var expected_interval := [4.0, 3.75, 3.5, 3.25, 3.0, 2.8, 2.6, 2.4, 2.2, 2.0]
	var counts := [3, 4, 5, 6, 8, 10, 12, 14, 17, 20]
	var spawn_intervals := [1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.6]
	var profiles: Array[EnemyStats] = []
	for index in 10:
		var wave: WaveData = load("res://resources/waves/nivel_montecalvo_oleada_%02d.tres" % (index + 1))
		assert_eq(wave.wave_number, index + 1)
		var total := 0
		var rifle_profiles: Array[EnemyStats] = []
		for entry: WaveSpawnEntry in wave.spawn_entries:
			total += entry.count
			assert_almost_eq(entry.spawn_interval, spawn_intervals[index], 0.0001)
			assert_eq([entry.enemy_stats.max_health, entry.enemy_stats.move_speed,
				entry.enemy_stats.melee_damage, entry.enemy_stats.ammo_drop], [15, 40.0, 5, 3])
			if entry.enemy_stats.rifle_damage > 0:
				if not rifle_profiles.has(entry.enemy_stats): rifle_profiles.append(entry.enemy_stats)
			else:
				assert_eq([entry.enemy_stats.rifle_range, entry.enemy_stats.rifle_damage,
					entry.enemy_stats.rifle_interval], [0.0, 0, 0.0], "Asaltante sin fusil")
		assert_eq(total, counts[index], "No cambiar cantidad de spawn al intercalar tipos")
		assert_eq(rifle_profiles.size(), 1, "Cada ola conserva un único perfilR I1 inmutable")
		if rifle_profiles.size() != 1: return
		var profile := rifle_profiles[0]
		assert_eq(profile.rifle_range, 864.0)
		assert_eq(profile.rifle_damage, expected_damage[index], "Tabla humana por oleada")
		assert_almost_eq(profile.rifle_interval, expected_interval[index], 0.0001)
		assert_eq([profile.max_health, profile.move_speed, profile.melee_damage, profile.ammo_drop], [15, 40.0, 5, 3])
		if index > 0: assert_false(profiles.has(profile), "Perfiles con datos diferentes no comparten instancia mutable")
		profiles.append(profile)
	var level := LEVEL.instantiate()
	assert_same(level.initial_enemy_stats, profiles[0], "Inicial usa perfil1")
	_dispose_unready_level(level)
	var first := _enemy(profiles[0], Vector2(1008, 144))
	first.set_physics_process(false)
	var second := _enemy(profiles[9], Vector2(1008, 528))
	second.prepare_for_spawn(profiles[9], second.position, 4)
	assert_same(first.stats, profiles[0])
	assert_eq(first.stats.rifle_damage, 1, "Activar ola10 no muta un enemigo vivo de ola1")
	assert_eq(first.stats.rifle_interval, 4.0)
	assert_eq(first.get("_current_health"), 15)
	var unit: UnitStats = load("res://resources/units/soldado_base_stats.tres")
	assert_eq([unit.rifle_range, unit.machete_moral_per_kill, unit.machete_heal_per_kill], [864.0, 2.0, 3])
	assert_eq([unit.max_health, unit.max_ammo, unit.damage_per_shot, unit.fire_rate, unit.machete_base_damage, unit.machete_moral_multiplier, unit.moral_per_kill], [30, 10, 5, 1.5, 3, 1.0, 1.0])


func test_level_production_composition_acquires_actual_entry_from_home() -> void:
	_level = LEVEL.instantiate()
	_world.add_child(_level)
	await wait_physics_frames(4)
	var enemies: Array[Enemigo] = []
	for node: Node in _level.find_children("*", "", true, false):
		if node is Enemigo and node.is_targetable(): enemies.append(node)
	assert_gte(enemies.size(), 1, "Inicial real; el primer spawn de ola espera1.5s autorados")
	var damaged := 0
	for enemy: Enemigo in enemies:
		if enemy.get("_current_health") < enemy.stats.max_health: damaged += 1
	assert_gte(damaged, 1, "Alcance Resource864 se aplica en la composición de producción")


func test_last_melee_kill_preserves_reward_when_wave_wins_synchronously() -> void:
	var owner := _melee_owner()
	var stats := EnemyStats.new()
	stats.max_health = 3
	stats.move_speed = 0.0
	stats.melee_damage = 0
	stats.ammo_drop = 0
	var enemy := _enemy(stats, Vector2(184, 336))
	var entry := WaveSpawnEntry.new()
	entry.count = 1
	entry.enemy_stats = stats
	var wave := WaveData.new()
	wave.spawn_entries = [entry]
	WaveManager.start_waves([wave])
	enemy.enemy_defeated.connect(func(_ammo: int, _position: Vector2): WaveManager.notify_enemy_defeated())
	await wait_physics_frames(2)
	owner._physics_process(1.0 / 60.0)
	assert_eq(GameStateManager._current_state, GameStateManager.GameState.WON, "Autoridad de victoria real")
	assert_eq(owner.get_reload_state().morale, 2.0)
	assert_eq(owner.get_reload_state().health, 28)


func test_melee_reentry_and_recycled_target_credit_only_the_original_kill(
	scenario = use_parameters(["reentry", "recycle", "owner_dies"])) -> void:
	var owner := _melee_owner()
	var enemy: Enemigo = ENEMY.instantiate()
	enemy.set_script(ReentrantEnemy)
	var stats := EnemyStats.new()
	stats.max_health = 3
	stats.move_speed = 0.0
	stats.melee_damage = 0
	stats.ammo_drop = 0
	enemy.stats = stats
	enemy.position = Vector2(184, 336)
	_world.add_child(enemy)
	enemy.set_physics_process(false)
	var outcomes: Array[Dictionary] = []
	owner.reload_state_changed.connect(func(): outcomes.append(owner.get_reload_state()))
	if scenario == "reentry":
		enemy.during_damage = func(): owner._physics_process(1.0 / 60.0)
	elif scenario == "recycle":
		enemy.enemy_defeated.connect(func(_ammo: int, _position: Vector2):
			enemy.on_pool_released()
			enemy.prepare_for_spawn(stats, Vector2(800, 336), 2))
	else:
		enemy.enemy_defeated.connect(func(_ammo: int, _position: Vector2): owner.take_damage(999))
	await wait_physics_frames(2)
	owner._physics_process(1.0 / 60.0)
	if scenario == "owner_dies":
		assert_false(owner.get_reload_state().alive)
		assert_lte(owner.get_reload_state().health, 0, "No resucitar dueño muerto durante callback")
		assert_eq(owner.get_reload_state().morale, 0.0)
	else:
		assert_eq(owner.get_reload_state().morale, 2.0, "Sólo baja original, crédito único al dueño vivo")
		assert_eq(owner.get_reload_state().health, 28)
		if scenario == "reentry": assert_eq(enemy.calls, 1, "Guard de transacción impide segundo daño reentrante")
		else:
			assert_eq(enemy.activation_generation, 1)
			assert_eq(enemy.get("_current_health"), 3, "Activación nueva intacta")


# 015-I2/T017: el recurso de A todavía no se requiere para cargar RED.
# La composición se observa desde el nivel real y sus Resources actuales.
func test_production_waves_form_continuous_two_assaults_one_rifle_sequence() -> void:
	var level := LEVEL.instantiate()
	var waves: Array[WaveData] = level.waves.duplicate()
	var initial: EnemyStats = level.initial_enemy_stats
	_dispose_unready_level(level)
	var counts := [3, 4, 5, 6, 8, 10, 12, 14, 17, 20]
	var expected_pairs := [Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, 2),
		Vector2i(4, 2), Vector2i(6, 2), Vector2i(6, 4), Vector2i(8, 4),
		Vector2i(10, 4), Vector2i(11, 6), Vector2i(13, 7)]
	var spawn_intervals := [1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.6]
	assert_eq(waves.size(), 10)
	var roles := ""
	var total_a := 0
	var total_r := 0
	for index in waves.size():
		var pair := Vector2i.ZERO
		for entry: WaveSpawnEntry in waves[index].spawn_entries:
			assert_gt(entry.count, 0)
			assert_almost_eq(entry.spawn_interval, spawn_intervals[index], 0.0001,
				"Ambos tipos conservan el intervalo original de la ola")
			var is_rifle := entry.enemy_stats.rifle_damage > 0
			for unused in entry.count:
				roles += "R" if is_rifle else "A"
				if is_rifle: pair.y += 1
				else: pair.x += 1
		assert_eq(pair.x + pair.y, counts[index])
		assert_eq(pair, expected_pairs[index], "Reparto autorado de la ola%d" % (index + 1))
		total_a += pair.x
		total_r += pair.y
	assert_eq(roles.length(), 99, "Sólo WAVE; el inicial independiente no consume el patrón")
	assert_eq(roles, "AAR".repeat(33), "A,A,R CONTINUO, sin reiniciar el índice en cada ola")
	assert_eq(Vector2i(total_a, total_r), Vector2i(66, 33))
	var wave_one_rifle: EnemyStats
	for entry: WaveSpawnEntry in waves[0].spawn_entries:
		if entry.enemy_stats.rifle_damage > 0: wave_one_rifle = entry.enemy_stats
	assert_same(initial, wave_one_rifle, "Inicial R/perfil1 independiente de la secuencia WAVE")


# Controles de IA existente: deben estar GREEN antes de autorar la mezcla.
func test_unarmed_assault_advances_from_rifleman_occupied_spawn_with_live_target() -> void:
	var target: Soldado = SOLDIER.instantiate()
	target.stats = target.stats.duplicate()
	target.stats.max_health = 1000
	target.position = Vector2(144, 336)
	target.set_grid_cell(Vector2i(1, 3))
	_world.add_child(target)
	target.set_physics_process(false)
	var rifle: EnemyStats = load("res://resources/enemies/enemigo_infanteria_base.tres")
	var stationary := _enemy(rifle, Vector2(1008, 336))
	watch_signals(stationary)
	await wait_physics_frames(3)
	assert_signal_emit_count(stationary, "rifle_shot_visual_requested", 1, "Control: blanco válido desde aparición")
	assert_eq(stationary.position, Vector2(1008, 336))
	var unarmed := rifle.duplicate() as EnemyStats
	unarmed.rifle_range = 0.0
	unarmed.rifle_damage = 0
	unarmed.rifle_interval = 0.0
	var assault := _enemy(unarmed, Vector2(1008, 336))
	watch_signals(assault)
	var original_layer := assault.collision_layer
	var original_mask := assault.collision_mask
	await wait_physics_frames(5)
	var after_recovery := assault.position
	await wait_physics_frames(30)
	assert_lt(assault.position.x, after_recovery.x - 10.0, "Avanza de verdad después de resolver el solape")
	assert_almost_eq(assault.position.y, 336.0, 0.01, "Conserva su carril")
	assert_eq(stationary.position, Vector2(1008, 336), "El fusilero sigue fijado al mismo blanco válido")
	assert_signal_not_emitted(assault, "rifle_shot_visual_requested")
	assert_eq([assault.collision_layer, assault.collision_mask], [original_layer, original_mask])


func test_same_pool_actor_switches_rifle_assault_rifle_without_inherited_target_or_cooldown() -> void:
	var target: Soldado = SOLDIER.instantiate()
	target.stats = target.stats.duplicate()
	target.stats.max_health = 1000
	target.position = Vector2(144, 336)
	target.set_grid_cell(Vector2i(1, 3))
	_world.add_child(target)
	target.set_physics_process(false)
	var rifle := load("res://resources/enemies/enemigo_infanteria_base.tres").duplicate() as EnemyStats
	var assault := rifle.duplicate() as EnemyStats
	assault.rifle_range = 0.0
	assault.rifle_damage = 0
	assault.rifle_interval = 0.0
	var pool := ObjectPool.new()
	_world.add_child(pool)
	pool.setup(ENEMY, 1)
	var actor := pool.acquire() as Enemigo
	actor.set_pool(pool)
	actor.prepare_for_spawn(rifle, Vector2(1008, 336), 2)
	watch_signals(actor)
	await wait_physics_frames(3)
	assert_signal_emit_count(actor, "rifle_shot_visual_requested", 1)
	var first_generation := actor.activation_generation
	pool.release(actor)
	var reused := pool.acquire() as Enemigo
	assert_same(reused, actor, "Un mismo cuerpo físico cambia de rol")
	reused.prepare_for_spawn(assault, Vector2(1008, 336), 2)
	await wait_physics_frames(10)
	assert_gt(reused.activation_generation, first_generation)
	assert_lt(reused.position.x, 1008.0, "A no conserva la fase estacionaria de R")
	assert_signal_emit_count(reused, "rifle_shot_visual_requested", 1, "A no hereda ningún disparo de R")
	pool.release(reused)
	var third := pool.acquire() as Enemigo
	assert_same(third, actor)
	third.prepare_for_spawn(rifle, Vector2(1008, 336), 2)
	await wait_physics_frames(3)
	assert_signal_emit_count(third, "rifle_shot_visual_requested", 2, "R readquiere de inmediato sin esperar el cooldown viejo")
	assert_eq(third.position, Vector2(1008, 336))
	assert_eq([rifle.rifle_range, rifle.rifle_damage, rifle.rifle_interval], [864.0, 1, 4.0])
	assert_eq([assault.rifle_range, assault.rifle_damage, assault.rifle_interval], [0.0, 0, 0.0])
