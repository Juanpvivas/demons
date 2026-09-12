extends GutTest
## Test de integración entre `Soldado.tscn` y `EnemigoBase.tscn` REALES (no
## `enemigo_double.gd`) — recomendación explícita de `qa-validator` antes de
## cerrar el checkpoint de User Story 1 (tras T027/T028): el smoke manual
## verificado fuera del repo ("un soldado real elimina un enemigo real en 3
## disparos") no había quedado como test automatizado repetible.
##
## Cubre el "Independent Test" de `spec.md` User Story 1 en su forma básica:
## "un solo soldado frente a un solo enemigo que avanza — dispara
## automáticamente, agota munición, transiciona a machete sin intervención
## del jugador", usando las escenas/scripts reales de ambos lados del
## contrato (`Soldado.ENEMY_GROUP`, `take_damage`, `enemy_defeated`,
## `get_advance_progress`), no el stand-in usado en `test_soldado.gd`.
##
## `tests/unit/units/test_soldado.gd` ya cubre en detalle cada regla de
## negocio (fórmulas de daño, moral, no-dividir-fuego, etc.) contra el
## contrato asumido vía `enemigo_double.gd` — no se duplica aquí. Este
## archivo solo verifica que las DOS implementaciones reales, desarrolladas
## en paralelo por grupos distintos, efectivamente encajan end-to-end.
##
## Nota de timing: a diferencia de `test_soldado.gd` (que usa un `fire_rate`
## acelerado para tests rápidos), el primer test de este archivo usa a
## propósito los `.tres` de producción sin overrides
## (`soldado_base_stats.tres`, `enemigo_infanteria_base.tres`) para validar
## el caso más fiel a lo que corre en `Nivel_MonteCalvo.tscn`. Esto implica
## esperar más physics frames reales (cooldown de fusil = 1/1.5 ≈ 0.667s).

const SOLDADO_SCENE_PATH := "res://scenes/units/Soldado.tscn"
const ENEMY_SCENE_PATH := "res://scenes/enemies/EnemigoBase.tscn"
const UNIT_STATS_SCRIPT_PATH := "res://resources/schemas/unit_stats.gd"
const ENEMY_STATS_SCRIPT_PATH := "res://resources/schemas/enemy_stats.gd"

# Mismo offset usado en `test_soldado.gd`: cae dentro de "DeteccionRango"
# (rango global x:[-72,72] y:[-264,-24]) pero fuera de "RangoMelee".
const RIFLE_ONLY_OFFSET := Vector2(0, -150)

var _soldado: Node
var _enemy: Node

# Capturados por conexión propia (no por `watch_signals`) porque el enemigo
# real se libera (`queue_free`) tras `enemy_defeated`: para cuando se espera
# lo suficiente como para comprobar la eliminación, el nodo ya está inválido
# y `assert_signal_emitted`/`get_signal_parameters` de GUT no pueden leer su
# historial de señales sobre un `Object` liberado. Estas variables persisten
# más allá de la vida del nodo.
var _enemy_defeated_emitted: bool = false
var _enemy_defeated_ammo_dropped: int = -1


func before_each() -> void:
	_soldado = null
	_enemy = null
	_enemy_defeated_emitted = false
	_enemy_defeated_ammo_dropped = -1


func _spawn_real_soldado() -> Node:
	# Sin overrides: usa el `UnitStats` de producción ya asignado en
	# `Soldado.tscn` (`soldado_base_stats.tres`).
	_soldado = load(SOLDADO_SCENE_PATH).instantiate()
	add_child_autofree(_soldado)
	return _soldado


func _spawn_real_enemy_at_offset(offset: Vector2, stats_overrides: Dictionary = {}) -> Node:
	_enemy = load(ENEMY_SCENE_PATH).instantiate()
	if not stats_overrides.is_empty():
		# Mismo patrón que `tests/unit/enemies/test_enemigo.gd`: un `EnemyStats`
		# fresco (no el `.tres` compartido) asignado ANTES de añadir el nodo al
		# árbol, para que `_ready()` snapshotee la salud correcta.
		var stats: Resource = load(ENEMY_STATS_SCRIPT_PATH).new()
		stats.max_health = stats_overrides.get("max_health", 15)
		stats.move_speed = stats_overrides.get("move_speed", 40.0)
		stats.melee_damage = stats_overrides.get("melee_damage", 5)
		stats.ammo_drop = stats_overrides.get("ammo_drop", 3)
		_enemy.stats = stats
	_enemy.enemy_defeated.connect(_on_enemy_defeated)
	add_child_autofree(_enemy)
	_enemy.global_position = _soldado.global_position + offset
	return _enemy


func _on_enemy_defeated(ammo_dropped: int, _position: Vector2) -> void:
	_enemy_defeated_emitted = true
	_enemy_defeated_ammo_dropped = ammo_dropped


## --- Escenario básico: fusil real detecta, dispara y elimina a un Enemigo real ---
## (spec.md User Story 1, Acceptance Scenario 1 — con las DOS implementaciones reales)

func test_real_soldado_detects_fires_and_defeats_a_real_enemigo_with_production_stats() -> void:
	# Given: un soldado real recién desplegado (munición completa de
	# producción) y un enemigo real, con salud/daño de producción, dentro de
	# su carril frontal de detección
	_spawn_real_soldado()
	watch_signals(_soldado)
	var enemy := _spawn_real_enemy_at_offset(RIFLE_ONLY_OFFSET)
	var expected_ammo_drop: int = enemy.stats.ammo_drop
	var expected_moral_per_kill: float = _soldado.stats.moral_per_kill

	# When: transcurre menos tiempo del necesario para un segundo disparo
	# (cooldown de fusil de producción ≈ 0.667s == 40 physics frames a 60fps)
	await wait_physics_frames(20)

	# Then: el enemigo (salud=15, daño_por_disparo=5) recibió como mucho un
	# impacto — sigue vivo, perdiendo salud real de forma incremental, no
	# muerto de un solo golpe
	assert_true(
		is_instance_valid(enemy),
		"el enemigo real no debe morir de un único disparo (salud=15 > daño_por_disparo=5)"
	)
	assert_false(
		_enemy_defeated_emitted,
		"tras un único disparo, el enemigo real todavía no debe haberse eliminado"
	)

	# When: transcurre tiempo suficiente para completar los 3 disparos que
	# agotan la salud de producción del enemigo (15 / 5 por disparo)
	await wait_physics_frames(100)

	# Then: el soldado real detectó y disparó automáticamente contra el
	# enemigo real hasta eliminarlo — enemy_defeated se emite con el
	# ammo_drop de producción, el soldado registra la eliminación como moral
	# (prueba de que pasó por el camino real de disparo -> take_damage ->
	# killed=true, no un atajo), y el enemigo queda liberado del árbol
	assert_true(
		_enemy_defeated_emitted,
		"el enemigo real debe ser eliminado tras suficientes disparos del soldado real (FR-002/FR-007)"
	)
	assert_eq(
		_enemy_defeated_ammo_dropped, expected_ammo_drop,
		"enemy_defeated debe reportar exactamente el ammo_drop de producción del enemigo"
	)
	assert_signal_emitted(
		_soldado, "moral_changed",
		"el soldado real debe acumular moral al confirmar la eliminación disparando (FR-006)"
	)
	assert_eq(
		get_signal_parameters(_soldado, "moral_changed")[0], expected_moral_per_kill,
		"la moral acumulada debe ser exactamente moral_per_kill de producción"
	)
	assert_false(
		is_instance_valid(enemy),
		"el enemigo real debe quedar liberado del árbol tras ser derrotado"
	)
	assert_signal_not_emitted(
		_soldado, "mode_changed",
		"con solo 3 de 10 balas de munición de producción consumidas, el soldado no debe haber transicionado a MELEE"
	)


## --- Independent Test completo de spec.md User Story 1: dispara, agota
## munición y transiciona a machete SIN intervención del jugador, contra un
## Enemigo real que sobrevive lo suficiente para atravesar ambas fases ---
##
## Usa stats acelerados (mismo criterio que `test_soldado.gd`) solo para que
## el test corra en un tiempo razonable — la lógica ejercitada (detección,
## disparo, agotamiento de munición, transición de modo, y ataque de
## machete) es exactamente la de producción, contra un `Enemigo` real.

func test_real_soldado_fires_depletes_ammo_and_finishes_a_real_enemigo_with_machete_without_player_input() -> void:
	# Given: un soldado con munición muy limitada y cadencia rápida (para que
	# el test corra en tiempo razonable), y un enemigo real con salud
	# suficiente para sobrevivir el fusil pero morir a machetazos una vez
	# alcance el rango melee mientras sigue avanzando en +Y
	var unit_stats: Resource = load(UNIT_STATS_SCRIPT_PATH).new()
	unit_stats.max_ammo = 2
	unit_stats.damage_per_shot = 5
	unit_stats.fire_rate = 10.0 # cooldown de 0.1s
	unit_stats.machete_base_damage = 5
	unit_stats.machete_moral_multiplier = 1.0
	unit_stats.moral_per_kill = 1.0
	unit_stats.deploy_ammo_cost = 2

	_soldado = load(SOLDADO_SCENE_PATH).instantiate()
	_soldado.stats = unit_stats
	add_child_autofree(_soldado)
	watch_signals(_soldado)

	# 2 disparos de fusil (10 de daño) no deben eliminarlo; move_speed
	# moderado para que, tras agotar munición, tenga tiempo suficiente
	# dentro de "RangoMelee" (ventana ≈112px) para recibir los machetazos
	# necesarios (30 salud / 5 daño = 6 golpes a 0.1s = 0.6s ≈ 36 frames)
	# antes de salir del rango por el otro lado.
	var enemy := _spawn_real_enemy_at_offset(
		RIFLE_ONLY_OFFSET, {"max_health": 30, "move_speed": 60.0, "ammo_drop": 4}
	)
	var expected_ammo_drop: int = enemy.stats.ammo_drop

	# When: pasa tiempo suficiente para que el soldado dispare sus 2 balas y
	# se quede sin munición, sin ninguna acción del jugador
	await wait_physics_frames(20)

	# Then: el soldado transicionó automáticamente a modo MELEE al agotar su
	# munición (FR-004, Acceptance Scenario 4), sin haber eliminado al
	# enemigo real con el fusil (10 de daño < 30 de salud)
	assert_signal_emitted(
		_soldado, "ammo_depleted",
		"la munición del soldado real debe agotarse tras sus disparos de fusil"
	)
	assert_signal_emitted(
		_soldado, "mode_changed",
		"el soldado real debe transicionar de modo automáticamente al agotar la munición (FR-004)"
	)
	assert_true(
		is_instance_valid(enemy),
		"el enemigo real (salud=30) no debe morir con solo 2 disparos de fusil (10 de daño)"
	)

	# When: el enemigo real, avanzando en +Y por su propia cuenta
	# (`enemigo.gd._physics_process`), sin intervención del jugador, alcanza
	# el rango de melee del soldado y este lo ataca con machete hasta
	# eliminarlo
	await wait_physics_frames(140)

	# Then: el enemigo real fue eliminado a machetazos — completando, sin
	# ninguna acción del jugador, el ciclo completo que describe el
	# "Independent Test" de spec.md User Story 1: disparar, agotar
	# munición, y transicionar a machete hasta derrotar al enemigo
	assert_true(
		_enemy_defeated_emitted,
		"el enemigo real debe ser eliminado a machetazos tras alcanzar RangoMelee (FR-004/FR-007)"
	)
	assert_eq(
		_enemy_defeated_ammo_dropped, expected_ammo_drop,
		"enemy_defeated debe reportar exactamente el ammo_drop configurado del enemigo"
	)
	assert_signal_not_emitted(
		_soldado, "moral_changed",
		"una eliminación en modo MELEE (machete) no debe acumular moral, incluso contra un enemigo real (FR-006)"
	)
	assert_false(
		is_instance_valid(enemy),
		"el enemigo real debe quedar liberado del árbol tras ser derrotado a machetazos"
	)
