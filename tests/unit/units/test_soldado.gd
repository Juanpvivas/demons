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
##
## T030: agrega cobertura para `reload()` (`data-model.md` transición
## `MELEE → RIFLE`, FR-009) — un método público que TODAVÍA NO EXISTE en
## `soldado.gd` (lo implementa T034, después de este test, siguiendo TDD).
## Se invoca vía `Object.call("reload")` en lugar de `_soldado.reload()`
## porque `_soldado` está tipado como `Node` genérico en este archivo
## (mismo motivo ya documentado en `soldado.gd` para
## `target.call("take_damage", ...)`: GDScript con tipado estático rechaza
## en tiempo de compilación una llamada directa a un método inexistente en
## la clase base declarada; `Object.call()` sí compila y simplemente falla
## en tiempo de ejecución —justo el comportamiento que necesitamos para que
## SOLO estos tests fallen ahora mismo, sin romper la carga del resto del
## archivo). T034 (`tasks.md`) documenta que `reload()` gasta munición vía
## `EconomyManager.try_spend_ammo()` — el autoload `EconomyManager` ya está
## registrado en `project.godot` (T010), así que estos tests fondean
## generosamente el pool global (`EconomyManager.add_ammo(999)`) para no
## acoplarse al costo exacto que decida T034, y restauran
## `collected_ammo` al final para no filtrar estado hacia otros tests que
## compartan el mismo autoload en este proceso de GUT (mismo patrón que
## `tests/unit/systems/test_autoloads_registration.gd`).
##
## T051: agrega cobertura del Edge Case de derrota de `spec.md` ("¿Qué ocurre
## si un soldado en modo cuerpo a cuerpo es derrotado por los enemigos antes
## de que el jugador pueda recargarlo? El soldado y su moral acumulada se
## pierden, liberando esa posición del tablero") y su contrato en
## `contracts/signals.md` (`soldier_defeated(grid_cell: Vector2i)`).
## `soldado.gd` TODAVÍA NO implementa `_current_health`, `take_damage()`,
## `_grid_cell`/su setter, ni la emisión de `soldier_defeated` — todo eso es
## T052 (`tasks.md`); el ataque activo de un `Enemigo` real contra un
## `Soldado` en "RangoMelee" es, a su vez, T053. Todos los tests de esta
## sección DEBEN fallar hasta que ambas tareas existan.
##
## Se usa `Object.call()` para invocar `take_damage()`/`set_grid_cell()` sobre
## `_soldado` (mismo motivo ya documentado arriba para `reload()`): estos
## métodos no existen todavía en la clase base declarada (`Node`), y una
## llamada directa no compilaría.
##
## SUPUESTO no confirmado con `dev-godot` (T052 no especifica el nombre del
## setter público de `_grid_cell`, solo que debe existir): se asume
## `set_grid_cell(cell: Vector2i) -> void`, seleccionado por ser el nombre más
## idiomático para un setter público en este proyecto (ver `BoardManager`:
## `occupy_cell`, `free_cell`, `get_occupant` — todos verbo + `cell`). Si
## T052 elige otro nombre, los tests que dependen de él fallarán por ese
## motivo específico (método inexistente), no por lógica incorrecta — avisar
## si ese es el caso.
##
## Los últimos dos tests de esta sección usan un `Enemigo` REAL
## (`EnemigoBase.tscn`, vía `_spawn_real_enemy()`) en vez de
## `enemigo_double.gd`, porque la conducta de "atacar activamente" que
## ejercitan es responsabilidad de `enemigo.gd` (T053), no del double. Usan
## `move_speed` mínimo (`MOVE_SPEED_SLOW_ENEMY`) y lo posicionan cerca del
## borde de entrada de "RangoMelee" (`MELEE_TOP_OFFSET`) para maximizar el
## tiempo de permanencia en rango, sin asumir ninguna cadencia de ataque
## específica de T053 (deliberadamente no especificada por `tasks.md`, que
## solo exige "documentar el supuesto de implementación elegido").

const SOLDADO_SCENE_PATH := "res://scenes/units/Soldado.tscn"
const SOLDADO_SCRIPT_PATH := "res://scenes/units/soldado.gd"
const UNIT_STATS_SCRIPT_PATH := "res://resources/schemas/unit_stats.gd"
const ENEMY_SCENE_PATH := "res://scenes/enemies/EnemigoBase.tscn"
const ENEMY_STATS_SCRIPT_PATH := "res://resources/schemas/enemy_stats.gd"
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

# T051: offset casi en el borde superior de "RangoMelee" (rango local
# y:[-64,0], ver comentario de cabecera de este bloque) — maximiza el tiempo
# que un `Enemigo` real, avanzando lentamente en +Y, permanece DENTRO de
# "RangoMelee" antes de cruzarlo por completo y salir por el otro lado.
const MELEE_TOP_OFFSET := Vector2(0, -60)

# Cuántos frames de física esperar para que una Area2D detecte overlap y
# el soldado dispare/ataque al menos una vez con el cooldown configurado.
const FRAMES_TO_DETECT := 5
const FRAMES_TO_FIRE_SEVERAL_SHOTS := 40

# T051: ventana generosa para que un `Enemigo` real, atacando con una
# cadencia todavía no definida (implementación de T053, fuera del alcance de
# este test), alcance a golpear al soldado al menos una vez mientras
# permanece dentro de "RangoMelee". A `MOVE_SPEED_SLOW_ENEMY` (mínimo
# permitido por `EnemyStats.move_speed`), el enemigo tarda ~6.4s (~384
# frames) en atravesar por completo la franja de 64px de "RangoMelee" desde
# `MELEE_TOP_OFFSET` — 400 frames cubre ese cruce completo con margen.
const FRAMES_TO_DEFEAT_SOLDIER := 400

# Stats por defecto compartidos por la mayoría de los tests; cada test que
# necesite un valor distinto (típicamente max_ammo) pasa overrides a
# `_spawn_soldado`.
const DEFAULT_MAX_AMMO := 3
const DEFAULT_DAMAGE_PER_SHOT := 5
const DEFAULT_FIRE_RATE := 10.0 # cooldown de 0.1s: varios tiros caben en pocos frames de test
const DEFAULT_MACHETE_BASE_DAMAGE := 3
const DEFAULT_MACHETE_MORAL_MULTIPLIER := 2.0
const DEFAULT_MORAL_PER_KILL := 1.0
const DEFAULT_MAX_HEALTH := 30

# T051: velocidad mínima permitida por `EnemyStats.move_speed`
# (`@export_range(10.0, ...)`), usada para que un `Enemigo` real permanezca
# el mayor tiempo posible dentro de "RangoMelee" mientras lo ataca.
const MOVE_SPEED_SLOW_ENEMY := 10.0

var _soldado_script: Script
var _soldado: Node
var _stats: Resource

# Capturados por conexión propia a `soldier_defeated` (no por `watch_signals`)
# en `test_soldier_is_defeated_by_a_real_enemy_attacking_within_rango_melee`
# — mismo patrón ya usado en `test_soldado_enemigo_integration.gd`
# (`_on_enemy_defeated`) por dos motivos: (1) tras 400 frames de física de
# espera, el `Soldado` puede quedar totalmente liberado de memoria para
# cuando se hace la aserción, y `assert_signal_emitted`/`get_signal_parameters`
# de GUT no pueden leer el historial de señales de un `Object` ya freed; (2)
# un lambda de GDScript captura las variables locales de la función POR
# VALOR en el momento de su creación — mutarlas dentro del lambda NO se
# refleja en la variable de la función que lo creó (comprobado
# empíricamente), así que la única forma correcta de capturar el payload es
# con variables de instancia y un método dedicado, como aquí.
var _soldier_defeated_emitted: bool = false
var _soldier_defeated_cell: Vector2i = Vector2i(-1, -1)


func before_each() -> void:
	_soldado_script = load(SOLDADO_SCRIPT_PATH)
	_soldado = null
	_stats = null
	_soldier_defeated_emitted = false
	_soldier_defeated_cell = Vector2i(-1, -1)


func _on_soldier_defeated(cell: Vector2i) -> void:
	_soldier_defeated_emitted = true
	_soldier_defeated_cell = cell


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
	_stats.max_health = overrides.get("max_health", DEFAULT_MAX_HEALTH)
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


## T051: instancia un `Enemigo` REAL (`EnemigoBase.tscn`), a diferencia de
## `_spawn_enemy()` (que usa el `enemigo_double.gd` de este archivo). Se
## necesita el `Enemigo` real -y no el double- porque la conducta bajo prueba
## (atacar activamente a un `Soldado` dentro de "RangoMelee") es
## responsabilidad de `enemigo.gd` (T053), no del contrato mínimo que
## implementa el double.
func _spawn_real_enemy(offset: Vector2, stats_overrides: Dictionary = {}) -> Node:
	var enemy: Node = load(ENEMY_SCENE_PATH).instantiate()
	var enemy_stats: Resource = load(ENEMY_STATS_SCRIPT_PATH).new()
	enemy_stats.max_health = stats_overrides.get("max_health", 20)
	enemy_stats.move_speed = stats_overrides.get("move_speed", MOVE_SPEED_SLOW_ENEMY)
	enemy_stats.melee_damage = stats_overrides.get("melee_damage", 10)
	enemy_stats.ammo_drop = stats_overrides.get("ammo_drop", 5)
	enemy.stats = enemy_stats
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


func test_moral_changed_is_not_emitted_when_a_melee_kill_happens() -> void:
	# Given: un soldado que ya está en modo MELEE (agotó su munición sin
	# eliminar a nadie con el fusil, moral permanece en 0)
	_spawn_soldado({"max_ammo": 1})
	_spawn_enemy(RIFLE_ONLY_OFFSET, 1000) # sobrevive al único disparo, sin acumular moral
	await wait_physics_frames(FRAMES_TO_DETECT)

	# When: entra un enemigo en RangoMelee y el soldado, ya en modo MELEE, lo
	# elimina a machetazos
	watch_signals(_soldado)
	var melee_target := _spawn_enemy(MELEE_OFFSET, _stats.machete_base_damage)
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)
	assert_true(
		melee_target.damage_received.size() > 0,
		"precondición del test: el objetivo en RangoMelee debe haber sido golpeado"
	)

	# Then: la eliminación en modo MELEE (machete) NO debe sumar moral —
	# FR-006 exige que la moral solo suba por eliminaciones mientras hay
	# munición/modo RIFLE
	assert_signal_not_emitted(
		_soldado, "moral_changed",
		"una eliminación en modo MELEE (machete) no debe acumular moral (FR-006)"
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
	# targeteado en su carril frontal, MENOS avanzado que el que entrará después
	_spawn_soldado({"max_ammo": 10})
	var first_enemy := _spawn_enemy(RIFLE_ONLY_OFFSET, 1000)
	first_enemy.advance_progress = 0.0
	await wait_physics_frames(FRAMES_TO_DETECT)
	assert_true(
		first_enemy.damage_received.size() > 0,
		"precondición del test: el primer enemigo debe haber recibido ya al menos un disparo"
	)

	# When: un segundo enemigo entra simultáneamente en una diagonal adyacente,
	# MÁS avanzado que el objetivo actual (spec.md Edge Cases: "el recién
	# llegado... más avanzado"), mientras el primero sigue vivo y en rango.
	# Si el soldado recalculara prioridad al entrar un candidato nuevo (en vez
	# de solo cuando no hay objetivo activo), el score más alto del recién
	# llegado le robaría el foco al objetivo original — por eso este test
	# exige una diferencia de prioridad real, no un empate resuelto por orden
	# de inserción.
	var second_enemy := _spawn_enemy(RIFLE_ONLY_OFFSET_B, 1000)
	second_enemy.advance_progress = 100.0
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


## --- Recarga: MELEE -> RIFLE conservando _current_morale (T030, FR-009) ---
##
## `reload()` todavía no existe en `soldado.gd` (es T034) — ambos tests de
## esta sección DEBEN fallar hasta que se implemente.

func test_reload_transitions_soldier_from_melee_back_to_rifle_mode() -> void:
	# Given: un soldado que agotó su única bala sin eliminar a nadie y ya
	# transicionó a modo MELEE
	_spawn_soldado({"max_ammo": 1})
	_spawn_enemy(RIFLE_ONLY_OFFSET, 1000) # sobrevive al único disparo, agota la munición
	await wait_physics_frames(FRAMES_TO_DETECT)

	# Y el jugador tiene munición recolectada suficiente para recargar
	# (fondeo generoso: T030 no depende de T033/T034 y no debe acoplarse al
	# costo exacto de recarga que decida T034)
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.add_ammo(999)
	watch_signals(_soldado)

	# When: se recarga al soldado
	_soldado.call("reload")

	# Then: el soldado vuelve a modo RIFLE (contrato de `data-model.md`:
	# "MELEE -> RIFLE: al recargar", y `contracts/signals.md`: `mode_changed`
	# se emite "en cualquier dirección, incluida recarga")
	assert_signal_emitted(
		_soldado, "mode_changed",
		"reload() debe emitir mode_changed al devolver al soldado a modo RIFLE"
	)
	assert_eq(
		get_signal_parameters(_soldado, "mode_changed")[0], _soldado_script.SoldierMode.RIFLE,
		"reload() debe transicionar al soldado de vuelta a modo RIFLE (FR-009, data-model.md)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


func test_reload_preserves_accumulated_morale_instead_of_resetting_it() -> void:
	# Given: un soldado que elimina un enemigo con su única bala (acumula
	# exactamente moral_per_kill de moral) antes de agotar munición y pasar
	# a modo MELEE
	_spawn_soldado({"max_ammo": 1})
	_spawn_enemy(RIFLE_ONLY_OFFSET, _stats.damage_per_shot) # muere con el único disparo
	await wait_physics_frames(FRAMES_TO_DETECT)

	# Y el jugador tiene munición recolectada suficiente para recargar
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.add_ammo(999)

	# When: se recarga (vuelve a RIFLE con una bala nueva) y esa bala se
	# dispara contra un segundo objetivo que NO muere (FR-006: un impacto
	# que no elimina no suma moral adicional), lo que agota la munición de
	# nuevo y devuelve al soldado a MELEE
	_soldado.call("reload")
	var second_enemy := _spawn_enemy(RIFLE_ONLY_OFFSET_B, 1000) # sobrevive al disparo
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)
	assert_true(
		second_enemy.damage_received.size() > 0,
		"precondición del test: tras reload() el soldado debe volver a disparar con fusil " +
		"(consumir su bala recargada) antes de poder verificar el daño de machete resultante " +
		"— si esto falla, reload() no devolvió al soldado a modo RIFLE"
	)

	# Then: el daño de machete contra un tercer objetivo en RangoMelee sigue
	# reflejando ÚNICAMENTE la moral acumulada ANTES de la recarga
	# (moral_per_kill de la única eliminación) — reload() NO debe resetear
	# `_current_morale` a 0 (FR-009, `data-model.md`: "conservando
	# _current_morale")
	var melee_target := _spawn_enemy(MELEE_OFFSET, 1000)
	await wait_physics_frames(FRAMES_TO_FIRE_SEVERAL_SHOTS)
	var expected_damage: int = roundi(
		_stats.machete_base_damage + _stats.moral_per_kill * _stats.machete_moral_multiplier
	)
	assert_true(
		melee_target.damage_received.size() > 0,
		"el objetivo en RangoMelee debe recibir al menos un golpe de machete"
	)
	assert_eq(
		melee_target.damage_received[0], expected_damage,
		"reload() debe conservar _current_morale: el daño de machete tras recargar debe seguir " +
		"reflejando la moral acumulada antes de la recarga, no reiniciarla a 0"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- Derrota del soldado: Edge Case de `spec.md` (T051, depende de T050) ---
##
## `take_damage()`, `_current_health`, `set_grid_cell()` y `soldier_defeated`
## TODAVÍA NO existen en `soldado.gd` — todos los tests de esta sección DEBEN
## fallar hasta que se implementen T052 (contrato de daño/derrota) y, para
## los dos últimos, también T053 (el `Enemigo` real atacando activamente).

func test_soldier_current_health_is_initialized_from_stats_max_health() -> void:
	# Given/When: un soldado recién desplegado con un max_health de producción
	_spawn_soldado({"max_health": 30})

	# Then: su salud runtime arranca exactamente en ese máximo
	# (`data-model.md`: "_current_health inicializado desde stats.max_health")
	assert_eq(
		_soldado.get("_current_health"), 30,
		"_current_health debe inicializarse desde stats.max_health en _ready()"
	)


func test_take_damage_reduces_current_health_without_killing_if_amount_is_less_than_health() -> void:
	# Given: un soldado con salud de sobra frente a un único golpe cuerpo a
	# cuerpo de un enemigo (magnitud de `EnemyStats.melee_damage`)
	_spawn_soldado({"max_health": 30})
	var melee_damage := 10

	# When: recibe un único golpe que no lo elimina
	var killed: bool = _soldado.call("take_damage", melee_damage)

	# Then: su salud se reduce exactamente en esa cantidad y no se reporta
	# como eliminado
	assert_false(
		killed,
		"take_damage() debe retornar false cuando el golpe no deja la salud en 0 o menos"
	)
	assert_eq(
		_soldado.get("_current_health"), 30 - melee_damage,
		"take_damage() debe restar exactamente el monto recibido de _current_health"
	)


func test_take_damage_returns_true_only_on_the_hit_that_reaches_zero_health() -> void:
	# Given: un soldado cuya salud es exactamente dos golpes de
	# EnemyStats.melee_damage (10 + 10 = 20)
	_spawn_soldado({"max_health": 20})
	var melee_damage := 10

	# When/Then: el primer golpe lo deja vivo (salud = 10, no eliminado)...
	var first_hit_killed: bool = _soldado.call("take_damage", melee_damage)
	assert_false(
		first_hit_killed,
		"el primer golpe (salud restante > 0) no debe reportarse como eliminación"
	)

	# ...y solo el segundo, que agota su salud, se reporta como la eliminación
	var second_hit_killed: bool = _soldado.call("take_damage", melee_damage)
	assert_true(
		second_hit_killed,
		"take_damage() debe retornar true únicamente en el golpe que deja la salud en 0 o menos"
	)


func test_soldier_emits_soldier_defeated_with_its_assigned_grid_cell_when_health_reaches_zero() -> void:
	# Given: un soldado desplegado en una celda conocida del tablero
	_spawn_soldado({"max_health": 10})
	var expected_cell := Vector2i(3, 4)
	_soldado.call("set_grid_cell", expected_cell)
	watch_signals(_soldado)

	# When: recibe daño suficiente para agotar su salud de una sola vez
	_soldado.call("take_damage", 10)

	# Then: emite soldier_defeated con exactamente la celda que ocupaba
	# (`contracts/signals.md`: "El soldado es derrotado... libera celda")
	assert_signal_emitted(
		_soldado, "soldier_defeated",
		"al llegar _current_health a 0, el soldado debe emitir soldier_defeated"
	)
	assert_eq(
		get_signal_parameters(_soldado, "soldier_defeated")[0], expected_cell,
		"soldier_defeated debe reportar exactamente la grid_cell asignada al soldado derrotado"
	)


func test_soldier_loses_all_accumulated_morale_when_defeated() -> void:
	# Given: un soldado que acumuló moral eliminando un enemigo con el fusil
	# antes de ser derrotado (una eliminación = moral_per_kill > 0)
	_spawn_soldado({"max_ammo": 1, "max_health": 10})
	_spawn_enemy(RIFLE_ONLY_OFFSET, _stats.damage_per_shot) # muere con el único disparo
	await wait_physics_frames(FRAMES_TO_DETECT)
	assert_gt(
		_soldado.get("_current_morale"), 0.0,
		"precondición del test: el soldado debe haber acumulado moral antes de ser derrotado"
	)

	# When: recibe daño suficiente para agotar su salud
	_soldado.call("take_damage", 10)

	# Then: pierde toda la moral acumulada (`spec.md` Edge Case: "el soldado
	# y su moral acumulada se pierden")
	assert_eq(
		_soldado.get("_current_morale"), 0.0,
		"un soldado derrotado debe perder toda su moral acumulada (_current_morale vuelve a 0)"
	)


func test_soldier_is_removed_from_the_scene_tree_when_defeated() -> void:
	# Given: un soldado con salud mínima
	_spawn_soldado({"max_health": 10})

	# When: recibe daño suficiente para agotar su salud
	_soldado.call("take_damage", 10)
	await wait_physics_frames(1) # queue_free() difiere la liberación al fin de frame

	# Then: el nodo queda liberado del árbol (contrato de T052: "queue_free()"
	# tras reportar la derrota)
	assert_false(
		is_instance_valid(_soldado),
		"un soldado derrotado debe liberarse del árbol (queue_free()) tras emitir soldier_defeated"
	)


## --- Derrota por ataque real de un Enemigo dentro de RangoMelee (T053) ---

func test_soldier_is_defeated_by_a_real_enemy_attacking_within_rango_melee() -> void:
	# Given: un soldado cuya salud total equivale a un único golpe cuerpo a
	# cuerpo de un enemigo real (EnemyStats.melee_damage = 10), desplegado en
	# una celda conocida del tablero
	_spawn_soldado({"max_health": 10})
	var expected_cell := Vector2i(1, 2)
	_soldado.call("set_grid_cell", expected_cell)
	# NO se usa watch_signals()/assert_signal_emitted() aquí a propósito:
	# `FRAMES_TO_DEFEAT_SOLDIER` (400 frames) es una ventana lo bastante
	# amplia como para que, tras la muerte del soldado, transcurran muchos
	# frames de física adicionales antes de esta aserción — tiempo de sobra
	# para que el `queue_free()` diferido de `_die()` termine de liberar el
	# nodo POR COMPLETO de memoria (no solo "pendiente de liberar"). Un
	# objeto totalmente liberado ya no puede responder ni siquiera a
	# `get_signal_list()` (lo que usa `assert_signal_emitted` internamente
	# para verificar que la señal existe), y GUT reporta el falso negativo
	# "Object <Freed Object> does not have the signal [...]" en vez de
	# evaluar si se emitió o no. Mismo problema ya identificado y resuelto en
	# `test_soldado_enemigo_integration.gd` (ver su comentario de cabecera
	# sobre `_on_enemy_defeated`): se captura el payload conectando la señal
	# manualmente ANTES de que el nodo pueda morir, en vez de depender de la
	# infraestructura de watch_signals de GUT sobre un nodo que va a dejar de
	# existir. Se conecta a un MÉTODO DE INSTANCIA (`_on_soldier_defeated`),
	# no a un lambda: un lambda captura `expected_cell`/variables locales por
	# valor, y mutar variables locales dentro de un lambda no se propaga a la
	# función que lo creó (comprobado empíricamente) — ver comentario junto a
	# `_soldier_defeated_emitted` en la cabecera de este archivo.
	_soldado.connect("soldier_defeated", _on_soldier_defeated)

	# When: un Enemigo real entra en su "RangoMelee" y permanece el tiempo
	# suficiente para atacarlo activamente (Edge Case de derrota de
	# `spec.md`: "un soldado en modo cuerpo a cuerpo es derrotado por los
	# enemigos")
	_spawn_real_enemy(MELEE_TOP_OFFSET, {"melee_damage": 10})
	await wait_physics_frames(FRAMES_TO_DEFEAT_SOLDIER)

	# Then: el soldado real fue derrotado por el ataque real del enemigo —
	# emite soldier_defeated con su celda y queda liberado del árbol
	assert_true(
		_soldier_defeated_emitted,
		"un Enemigo real atacando dentro de RangoMelee debe derrotar al soldado (T052+T053)"
	)
	assert_eq(
		_soldier_defeated_cell, expected_cell,
		"soldier_defeated debe reportar la grid_cell del soldado derrotado por el enemigo real"
	)
	assert_false(
		is_instance_valid(_soldado),
		"el soldado derrotado por el enemigo real debe liberarse del árbol"
	)


## T053 (rehecha), cobertura del supuesto de implementación NO ejercitado por
## el test anterior (con un solo enemigo en rango, "solo al objetivo actual" y
## "a todos los candidatos" son indistinguibles): `soldado.gd`
## `_process_incoming_melee_damage()` documenta explícitamente que aplica el
## daño entrante de CADA `Enemigo` presente en `_melee_candidates`, no solo de
## `_current_melee_target` (a diferencia del ataque saliente del propio
## soldado, que sí respeta "sin dividir fuego"). Usa `enemigo_double.gd` (no
## un `Enemigo` real) porque no es necesario que se muevan ni que la fuente
## del daño sea creíble en términos de gameplay — solo que ambos permanezcan
## simultáneamente dentro de "RangoMelee" con un `get_melee_damage()`
## distinguible cada uno, para poder sumar el daño esperado con precisión.
func test_soldier_takes_incoming_melee_damage_from_every_candidate_present_not_only_the_current_target() -> void:
	# Given: un soldado con salud de sobra y dos enemigos distintos,
	# simultáneamente dentro de "RangoMelee", cada uno con un melee_damage
	# distinguible
	_spawn_soldado({"max_health": 1000})
	var enemy_a := EnemigoDouble.new()
	enemy_a.health = 1000
	enemy_a.melee_damage = 4
	add_child_autofree(enemy_a)
	enemy_a.global_position = _soldado.global_position + Vector2(-20, -40)

	var enemy_b := EnemigoDouble.new()
	enemy_b.health = 1000
	enemy_b.melee_damage = 7
	add_child_autofree(enemy_b)
	enemy_b.global_position = _soldado.global_position + Vector2(20, -40)

	# When: transcurre tiempo suficiente para que ambos sean detectados y
	# reciba exactamente el primer golpe de cada uno (_incoming_melee_cooldown
	# arranca en 0.0; el segundo ciclo de ataque requiere ~60 frames más a
	# _INCOMING_MELEE_ATTACK_INTERVAL=1.0s, muy por fuera de esta ventana)
	await wait_physics_frames(FRAMES_TO_DETECT)

	# Then: el soldado perdió la SUMA de ambos melee_damage (4 + 7 = 11), no
	# solo el del enemigo elegido como _current_melee_target — confirma que
	# `_process_incoming_melee_damage()` recorre TODOS los `_melee_candidates`
	assert_eq(
		_soldado.get("_current_health"), 1000 - 11,
		"el soldado debe recibir el daño de CADA enemigo presente en RangoMelee simultáneamente, no solo del objetivo actual de su propio ataque"
	)
