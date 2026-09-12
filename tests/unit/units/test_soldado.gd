extends GutTest
## T015: test de `scenes/units/soldado.gd` — cubre "cálculo de daño" y
## "acumulación de moral" de `constitution.md` Principio II, además de
## consumo de munición por disparo y la transición automática RIFLE→MELEE
## (FR-003/FR-004), la fórmula de daño de machete `machete_base_damage +
## moral * machete_moral_multiplier` incluyendo el Edge Case de moral=0
## (FR-005, `spec.md` Edge Cases), la regla de acumulación de moral
## exclusivamente por eliminación (FR-006), y la regla de "no dividir
## fuego" de `spec.md` User Story 1 Acceptance Scenario 3 (FR-002).
##
## `Enemigo` (`scenes/enemies/enemigo.gd`) todavía no existe — lo implementa
## otro grupo en paralelo (T018/T025/T026 de `tasks.md`). Se usa
## `tests/unit/units/enemigo_double.gd`, un `CharacterBody2D` mínimo que
## implementa el contrato asumido por `soldado.gd` (grupo `"enemies"`,
## `take_damage(amount:int)->bool`, `get_advance_progress()->float`).
##
## Estos tests ejercitan la detección real vía `Area2D.body_entered` de
## "DeteccionRango"/"RangoMelee" (posicionando el double dentro de las
## formas de colisión reales de `Soldado.tscn`) en vez de invocar los
## handlers privados directamente, para verificar comportamiento observable
## end-to-end tal como lo describen los Acceptance Scenarios del spec.
##
## IMPORTANTE: `soldado.gd` copia `stats.max_ammo` a `_current_ammo` en
## `_ready()` (snapshot de una sola vez, `docs/ARCHITECTURE.md` §4.3 — el
## Resource es solo el molde base). Por eso cualquier `max_ammo` distinto
## del default debe fijarse en el `UnitStats` ANTES de instanciar/agregar el
## soldado al árbol (ver `_spawn_soldado`) — fijarlo después de que el
## soldado ya esté en el árbol no tiene efecto sobre `_current_ammo`.

const SOLDADO_SCENE_PATH := "res://scenes/units/Soldado.tscn"
const SOLDADO_SCRIPT_PATH := "res://scenes/units/soldado.gd"
const UNIT_STATS_SCRIPT_PATH := "res://resources/schemas/unit_stats.gd"
const EnemigoDouble := preload("res://tests/unit/units/enemigo_double.gd")

# Posiciones relativas al soldado que caen dentro de las formas de colisión
# reales definidas en `Soldado.tscn`:
#   - "DeteccionRango": CollisionShape2D en (0, -144), tamaño 144x240
#     -> rango global x:[-72,72] y:[-264,-24].
#   - "RangoMelee": CollisionShape2D en (0, -32), tamaño 64x64
#     -> rango global x:[-32,32] y:[-64,0].
# `RIFLE_ONLY_OFFSET`/`_B` caen dentro de "DeteccionRango" pero fuera de
# "RangoMelee"; `MELEE_OFFSET` cae dentro de ambas (las formas se solapan
# por diseño en la franja cercana al soldado, lo cual es irrelevante para
# estos tests porque cada uno controla explícitamente en qué modo espera
# que el soldado esté al llegar ese enemigo).
const RIFLE_ONLY_OFFSET := Vector2(0, -150)
const RIFLE_ONLY_OFFSET_B := Vector2(40, -150)
const MELEE_OFFSET := Vector2(0, -40)

# Cuántos frames de física esperar para que una Area2D detecte overlap y
# el soldado dispare/ataque al menos una vez con el cooldown configurado.
const FRAMES_TO_DETECT := 5
const FRAMES_TO_FIRE_SEVERAL_SHOTS := 40

# Stats por defecto compartidos por la mayoría de los tests; cada test que
# necesite un valor distinto (típicamente max_ammo) pasa overrides a
# `_spawn_soldado`.
const DEFAULT_MAX_AMMO := 3
const DEFAULT_DAMAGE_PER_SHOT := 5
const DEFAULT_FIRE_RATE := 10.0 # cooldown de 0.1s: varios tiros caben en pocos frames de test
const DEFAULT_MACHETE_BASE_DAMAGE := 3
const DEFAULT_MACHETE_MORAL_MULTIPLIER := 2.0
const DEFAULT_MORAL_PER_KILL := 1.0

var _soldado_script: Script
var _soldado: Node
var _stats: Resource


func before_each() -> void:
	_soldado_script = load(SOLDADO_SCRIPT_PATH)
	_soldado = null
	_stats = null


## Crea un `UnitStats` con los defaults de este archivo (más los overrides
## dados), instancia `Soldado.tscn` con ese `stats` ya asignado, y lo agrega
## al árbol — en ese orden, para que `_ready()` snapshotee el `max_ammo`
## correcto. Devuelve el soldado ya listo para recibir enemigos.
func _spawn_soldado(overrides: Dictionary = {}) -> Node:
	_stats = load(UNIT_STATS_SCRIPT_PATH).new()
	_stats.max_ammo = overrides.get("max_ammo", DEFAULT_MAX_AMMO)
	_stats.damage_per_shot = overrides.get("damage_per_shot", DEFAULT_DAMAGE_PER_SHOT)
	_stats.fire_rate = overrides.get("fire_rate", DEFAULT_FIRE_RATE)
	_stats.machete_base_damage = overrides.get("machete_base_damage", DEFAULT_MACHETE_BASE_DAMAGE)
	_stats.machete_moral_multiplier = overrides.get(
		"machete_moral_multiplier", DEFAULT_MACHETE_MORAL_MULTIPLIER
	)
	_stats.moral_per_kill = overrides.get("moral_per_kill", DEFAULT_MORAL_PER_KILL)
	_stats.deploy_ammo_cost = _stats.max_ammo

	_soldado = load(SOLDADO_SCENE_PATH).instantiate()
	_soldado.stats = _stats
	add_child_autofree(_soldado)
	return _soldado


func _spawn_enemy(offset: Vector2, health: int = 1000) -> Node:
	var enemy := EnemigoDouble.new()
	enemy.health = health
	add_child_autofree(enemy)
	enemy.global_position = _soldado.global_position + offset
	return enemy


## --- Daño de fusil por disparo (FR-002/FR-003) ---

func test_rifle_shot_deals_exactly_stats_damage_per_shot() -> void:
	# Given: un soldado con munición y un enemigo dentro de su carril frontal de detección
	_spawn_soldado()
	var enemy := _spawn_enemy(RIFLE_ONLY_OFFSET)

	# When: pasa suficiente tiempo de física para que lo detecte y dispare
	await wait_physics_frames(FRAMES_TO_DETECT)

	# Then: el enemigo recibió exactamente un disparo con el daño configurado
	assert_eq(
		enemy.damage_received, [_stats.damage_per_shot],
		"el primer disparo de fusil debe infligir exactamente stats.damage_per_shot"
	)


## --- Consumo de munición por disparo (FR-003) ---

func test_ammo_depleted_signal_is_emitted_after_max_ammo_shots() -> void:
	# Given: un soldado con munición limitada y un enemigo que nunca muere
	# (así ningún disparo se "pierde" por eliminación temprana)
	_spawn_soldado({"max_ammo": 3})
	watch_signals(_soldado)
	var enemy := _spawn_enemy(RIFLE_ONLY_OFFSET)

	# When: pasa tiempo suficiente para agotar toda la munición disparando
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)

	# Then: se dispararon exactamente max_ammo balas (ni una más, ni una menos)
	# y se emitió ammo_depleted al llegar a 0
	assert_eq(
		enemy.damage_received.size(), 3,
		"el soldado debe disparar exactamente max_ammo veces contra el mismo objetivo antes de quedarse sin munición"
	)
	assert_signal_emitted(
		_soldado, "ammo_depleted",
		"ammo_depleted debe emitirse justo cuando la munición llega a 0 (FR-004)"
	)


## --- Transición automática RIFLE -> MELEE al llegar a 0 munición (FR-004) ---

func test_soldier_transitions_to_melee_mode_when_ammo_reaches_zero() -> void:
	# Given: un soldado con munición limitada y un enemigo persistente en su rango de fusil
	_spawn_soldado({"max_ammo": 3})
	watch_signals(_soldado)
	_spawn_enemy(RIFLE_ONLY_OFFSET)

	# When: agota su munición disparando
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)

	# Then: emite mode_changed hacia MELEE (contrato de signals.md)
	assert_signal_emitted(
		_soldado, "mode_changed",
		"mode_changed debe emitirse al agotar la munición"
	)
	assert_eq(
		get_signal_parameters(_soldado, "mode_changed")[0], _soldado_script.SoldierMode.MELEE,
		"el soldado debe transicionar a modo MELEE justo al agotar su munición"
	)


func test_soldier_no_longer_fires_rifle_shots_once_in_melee_mode() -> void:
	# Given: un soldado que ya agotó su munición (mismo enemigo lejos de RangoMelee)
	_spawn_soldado({"max_ammo": 3})
	var enemy := _spawn_enemy(RIFLE_ONLY_OFFSET)
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)
	var shots_when_ammo_depleted: int = enemy.damage_received.size()

	# When: sigue transcurriendo tiempo de física en modo MELEE (el enemigo
	# permanece fuera de RangoMelee, así que no debería recibir más golpes)
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)

	# Then: no se disparan más balas de fusil (la munición ya es 0)
	assert_eq(
		enemy.damage_received.size(), shots_when_ammo_depleted,
		"en modo MELEE no deben producirse más disparos de fusil contra un enemigo fuera de RangoMelee"
	)


## --- Acumulación de moral solo por eliminación (FR-006) ---

func test_moral_changed_is_not_emitted_when_a_shot_does_not_kill_the_target() -> void:
	# Given: un enemigo con salud muy superior al daño de un disparo (no puede morir de un solo tiro)
	_spawn_soldado()
	watch_signals(_soldado)
	_spawn_enemy(RIFLE_ONLY_OFFSET, 1000)

	# When: el soldado impacta al enemigo sin eliminarlo
	await wait_physics_frames(FRAMES_TO_DETECT)

	# Then: no se acumula moral por un impacto que no resulta en eliminación
	assert_signal_not_emitted(
		_soldado, "moral_changed",
		"un impacto que no elimina al objetivo NO debe acumular moral (FR-006)"
	)


func test_moral_changed_is_emitted_with_moral_per_kill_when_a_shot_kills_the_target() -> void:
	# Given: un enemigo con salud exactamente igual al daño de un disparo (muere con el primer tiro)
	_spawn_soldado()
	watch_signals(_soldado)
	_spawn_enemy(RIFLE_ONLY_OFFSET, _stats.damage_per_shot)

	# When: el soldado dispara y elimina al enemigo
	await wait_physics_frames(FRAMES_TO_DETECT)

	# Then: se emite moral_changed con moral_per_kill acumulado
	assert_signal_emitted(
		_soldado, "moral_changed",
		"moral_changed debe emitirse al confirmar una eliminación"
	)
	assert_eq(
		get_signal_parameters(_soldado, "moral_changed")[0], _stats.moral_per_kill,
		"una eliminación confirmada debe sumar exactamente stats.moral_per_kill a la moral (FR-006)"
	)


## --- Daño de machete = base + moral * multiplicador (FR-005) ---

func test_machete_damage_with_zero_accumulated_morale_equals_base_damage() -> void:
	# Given: un soldado que agota su munición sin haber eliminado a nadie
	# (moral permanece en 0 — spec.md Edge Case)
	_spawn_soldado({"max_ammo": 1})
	_spawn_enemy(RIFLE_ONLY_OFFSET, 1000) # sobrevive al único disparo, sin acumular moral
	await wait_physics_frames(FRAMES_TO_DETECT)

	# When: entra un enemigo nuevo en su rango de melee, ya en modo MELEE
	var melee_target := _spawn_enemy(MELEE_OFFSET, 1000)
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)

	# Then: el golpe de machete inflige exactamente machete_base_damage (>0),
	# sin bonus alguno de moral
	assert_true(
		melee_target.damage_received.size() > 0,
		"el objetivo en RangoMelee debe recibir al menos un golpe de machete"
	)
	assert_eq(
		melee_target.damage_received[0], _stats.machete_base_damage,
		"con moral acumulada en 0, el daño de machete debe ser exactamente machete_base_damage"
	)


func test_machete_damage_scales_with_accumulated_morale() -> void:
	# Given: un soldado que elimina exactamente 2 enemigos con el fusil antes
	# de quedarse sin munición (acumula moral = 2 * moral_per_kill)
	_spawn_soldado({"max_ammo": 2})
	_spawn_enemy(RIFLE_ONLY_OFFSET, _stats.damage_per_shot) # muere con el 1er disparo
	await wait_physics_frames(FRAMES_TO_DETECT)
	_spawn_enemy(RIFLE_ONLY_OFFSET_B, _stats.damage_per_shot) # 2do objetivo, también muere con 1 disparo
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)

	# When: entra un tercer enemigo en RangoMelee, ya en modo MELEE (la
	# munición ya está agotada: 2 disparos consumidos = max_ammo)
	var melee_target := _spawn_enemy(MELEE_OFFSET, 1000)
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)

	# Then: el daño de machete refleja la fórmula con la moral acumulada
	var expected_morale: float = 2 * _stats.moral_per_kill
	var expected_damage: int = roundi(
		_stats.machete_base_damage + expected_morale * _stats.machete_moral_multiplier
	)
	assert_true(
		melee_target.damage_received.size() > 0,
		"el objetivo en RangoMelee debe recibir al menos un golpe de machete"
	)
	assert_eq(
		melee_target.damage_received[0], expected_damage,
		"el daño de machete debe ser machete_base_damage + moral_acumulada * machete_moral_multiplier"
	)


## --- No dividir fuego: spec.md User Story 1, Acceptance Scenario 3 (FR-002) ---

func test_soldier_does_not_split_fire_when_a_second_enemy_enters_detection_range() -> void:
	# Given: un soldado con munición suficiente y un primer enemigo ya
	# targeteado en su carril frontal
	_spawn_soldado({"max_ammo": 10})
	var first_enemy := _spawn_enemy(RIFLE_ONLY_OFFSET, 1000)
	await wait_physics_frames(FRAMES_TO_DETECT)
	assert_true(
		first_enemy.damage_received.size() > 0,
		"precondición del test: el primer enemigo debe haber recibido ya al menos un disparo"
	)

	# When: un segundo enemigo entra simultáneamente en una diagonal adyacente,
	# mientras el primero sigue vivo y en rango
	var second_enemy := _spawn_enemy(RIFLE_ONLY_OFFSET_B, 1000)
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)

	# Then: el soldado sigue disparando exclusivamente al objetivo original;
	# el recién llegado no recibe ningún disparo mientras el primero siga vivo
	assert_eq(
		second_enemy.damage_received.size(), 0,
		"el soldado no debe dividir su fuego: un enemigo nuevo no debe recibir disparos mientras el objetivo actual sigue vivo (Acceptance Scenario 3)"
	)
	assert_true(
		first_enemy.damage_received.size() > 1,
		"el soldado debe seguir disparando repetidamente contra su objetivo original"
	)
