extends GutTest
## Test de `scenes/levels/Nivel_MonteCalvo.tscn` (T027) — verifica que el
## nivel mínimo carga sin errores y que su geometría (posiciones de
## Soldado/Enemigo, tamaños/offsets de las `Area2D` de detección del
## soldado) efectivamente hace que el enemigo, avanzando en +Y como está
## diseñado (`scenes/enemies/enemigo.gd`, comentario de cabecera), entre en
## rango de detección del soldado y termine siendo eliminado — sin ninguna
## intervención adicional, tal como lo describe el "Independent Test" de
## `spec.md` User Story 1.
##
## Recomendación de `qa-validator` (ronda anterior, grupo Enemigo): agregar
## cobertura automatizada de este primer punto de contacto real entre
## `Soldado` y `Enemigo`, más allá del smoke manual de T046.
##
## Nota de timing: usa los `.tres` de producción sin overrides y las
## posiciones/tamaños reales de `Nivel_MonteCalvo.tscn`/`Soldado.tscn` —
## el enemigo recorre ~162px a 40px/s (move_speed de producción) antes de
## entrar en rango, por lo que este test espera varios cientos de physics
## frames (más lento que el resto de la suite, pero es exactamente el
## escenario que este nivel fue diseñado para producir).

const LEVEL_SCENE_PATH := "res://scenes/levels/Nivel_MonteCalvo.tscn"

# T043: para instanciar un Enemigo real adicional al colocado a mano en la
# escena (T027), en un carril lateral separado.
const ENEMY_SCENE_PATH := "res://scenes/enemies/EnemigoBase.tscn"

# Geometría documentada en `Nivel_MonteCalvo.tscn` (T027) y `Soldado.tscn`:
#   - Soldado en (576, 500); Enemigo en (576, 50) (mismo carril X).
#   - "DeteccionRango": CollisionShape2D en offset local (0,-144) del
#     soldado, tamaño 144x240 -> global x:[504,648] y:[236,476].
# El enemigo (caja de colisión 48x48, sin offset) entra en solape con
# "DeteccionRango" cuando su borde inferior alcanza el borde superior del
# área: enemigo_y + 24 >= 236 -> enemigo_y >= 212. Arrancando en y=50 y
# avanzando a `move_speed` (40px/s de producción) hacia +Y, son ~4.05s.
const FRAMES_TO_ENTER_DETECTION_RANGE := 250

# Frames adicionales para que, ya detectado, el soldado dispare las 3 balas
# de daño de producción (15 salud / 5 daño por disparo) necesarias para
# eliminar al enemigo de producción (cooldown de fusil ≈0.667s por disparo).
const FRAMES_TO_DEFEAT_AFTER_DETECTION := 100

var _level: Node

# Capturado por una conexión propia a un método (no un lambda: los closures
# de GDScript capturan variables locales POR VALOR, no por referencia — un
# lambda que asigne a una variable local del test nunca sería visible fuera
# de sí mismo). Necesario además porque el enemigo real se libera
# (`queue_free`) tras `enemy_defeated`, y para cuando se espera lo
# suficiente como para comprobar la eliminación, el nodo ya está inválido:
# GUT no puede leer el historial de señales de un `Object` liberado.
var _enemy_defeated_emitted: bool = false


func before_each() -> void:
	_level = null
	_enemy_defeated_emitted = false


func _on_enemy_defeated(_ammo_dropped: int, _position: Vector2) -> void:
	_enemy_defeated_emitted = true


func _load_level() -> Node:
	_level = load(LEVEL_SCENE_PATH).instantiate()
	add_child_autofree(_level)
	return _level


## --- Carga sin errores y estructura/posiciones esperadas ---

func test_nivel_montecalvo_instantiates_without_errors_with_expected_structure() -> void:
	# Given/When: se instancia el nivel y entra al árbol
	var level := _load_level()

	# Then: no hubo errores de carga/parseo, y la estructura mínima esperada
	# (Tablero + Soldado + Enemigo, mismo carril X) está presente
	assert_true(is_instance_valid(level), "Nivel_MonteCalvo.tscn debe instanciar sin errores")
	assert_not_null(level.get_node_or_null("Tablero"), "el nivel debe tener un TileMap 'Tablero'")
	assert_true(
		level.get_node_or_null("Tablero") is TileMap,
		"'Tablero' debe ser un TileMap"
	)

	var soldado := level.get_node_or_null("Soldado")
	var enemigo := level.get_node_or_null("Enemigo")
	assert_not_null(soldado, "el nivel debe tener una instancia de Soldado.tscn")
	assert_not_null(enemigo, "el nivel debe tener una instancia de EnemigoBase.tscn")

	assert_eq(
		soldado.global_position, Vector2(576, 500),
		"el soldado debe estar en la posición documentada del nivel mínimo"
	)
	assert_eq(
		enemigo.global_position, Vector2(576, 50),
		"el enemigo debe aparecer en la posición documentada del nivel mínimo"
	)
	assert_eq(
		soldado.global_position.x, enemigo.global_position.x,
		"soldado y enemigo deben compartir el mismo carril X para que el avance en +Y del enemigo lo acerque al soldado"
	)
	assert_true(
		enemigo.global_position.y < soldado.global_position.y,
		"el enemigo debe aparecer por delante del soldado en el sentido de avance +Y"
	)


## --- Geometría real: el avance en +Y del enemigo lo hace entrar en rango,
## y el soldado lo elimina automáticamente sin intervención adicional ---
## (spec.md User Story 1, Independent Test / Acceptance Scenario 1)

func test_enemigo_avanzando_en_mas_y_entra_en_rango_de_deteccion_y_es_eliminado_sin_intervencion() -> void:
	# Given: el nivel mínimo tal cual está diseñado, sin overrides de stats
	var level := _load_level()
	var soldado := level.get_node("Soldado")
	var enemigo := level.get_node("Enemigo")
	var deteccion_rango: Area2D = soldado.get_node("DeteccionRango")
	enemigo.enemy_defeated.connect(_on_enemy_defeated)

	# Precondición: al arrancar, el enemigo todavía no está dentro del
	# rango de detección (geometría documentada arriba)
	assert_does_not_have(
		deteccion_rango.get_overlapping_bodies(), enemigo,
		"precondición del test: el enemigo no debe empezar ya dentro de DeteccionRango"
	)

	# When: transcurre el tiempo suficiente para que el enemigo, avanzando
	# por su cuenta en +Y (sin intervención del jugador), recorra la
	# distancia real hasta el borde de "DeteccionRango"
	await wait_physics_frames(FRAMES_TO_ENTER_DETECTION_RANGE)

	# Then: la geometría del nivel efectivamente hace que el enemigo entre
	# en el área de detección real del soldado
	assert_has(
		deteccion_rango.get_overlapping_bodies(), enemigo,
		"tras avanzar en +Y la distancia diseñada, el enemigo debe solapar con DeteccionRango del soldado"
	)

	# When: el soldado, ya con el enemigo detectado, dispara automáticamente
	# hasta eliminarlo (sin ninguna acción adicional del jugador)
	await wait_physics_frames(FRAMES_TO_DEFEAT_AFTER_DETECTION)

	# Then: el enemigo del nivel es eliminado por el soldado del nivel,
	# completando de punta a punta el escenario que describe el
	# "Independent Test" de spec.md User Story 1
	assert_true(
		_enemy_defeated_emitted,
		"el soldado del nivel debe eliminar automáticamente al enemigo del nivel tras detectarlo (Independent Test de User Story 1)"
	)
	assert_false(
		is_instance_valid(enemigo),
		"el enemigo del nivel debe quedar liberado del árbol tras ser derrotado"
	)


## --- Despliegue de un soldado nuevo en celda vacía (T035, `spec.md` User
## Story 2, Acceptance Scenario 3; Edge Case "posición ya ocupada"; FR-001/
## FR-010/FR-011) ---
##
## `_try_deploy_soldado(cell: Vector2i)` (`nivel_monte_calvo.gd`) es la
## lógica de despliegue en sí (validar celda libre -> gastar munición ->
## instanciar -> registrar ocupante); `_unhandled_input()` solo la envuelve
## con la conversión de un evento de click/tap real a `Vector2i` de celda
## (pantalla -> mundo -> celda).
##
## Se invoca `_try_deploy_soldado()` directamente vía `Object.call()` en vez
## de simular un click/tap real con `Input.parse_input_event()` porque,
## verificado empíricamente en este entorno (`--headless`, sin
## `DisplayServer` real): el evento de mouse simulado NO llega a
## `_unhandled_input()` con la posición de pantalla original que se le
## asigna. El stretch de ventana configurado en el proyecto
## (`window/stretch/mode="canvas_items"`, `aspect="expand"`) reescala la
## posición del evento en un factor que depende del tamaño de ventana que
## asume el runner headless (no de nada del propio nivel) ANTES de que
## `_unhandled_input()` la reciba — ej. una posición enviada de (240,240)
## llegó medida como (4320,4320) en una prueba exploratoria, un factor que
## ni siquiera coincide con `get_viewport().canvas_transform` (que reporta
## identidad). Simular el click de esa forma haría estos tests
## frágiles/no deterministas (dependientes de configuración de ventana del
## entorno de test, no del comportamiento del nivel) sin ejercitar más
## lógica de negocio real que invocar el método de despliegue directamente.
## Lo único que queda sin cubrir por esta decisión es
## `_screen_to_world()`/`_world_to_cell()`, conversión de coordenadas pura
## sin lógica de negocio, y el filtro de tipo de evento en
## `_unhandled_input()`.
##
## Cada test fondea/restaura `EconomyManager.collected_ammo` (autoload
## compartido entre archivos de test en el mismo proceso GUT), mismo patrón
## que `tests/unit/units/test_soldado.gd`.

# Celda libre del tablero (world center (144,144) con tile_size 96x96),
# distinta de la celda del Soldado inicial colocado a mano (T027).
const FREE_TEST_CELL := Vector2i(1, 1)

# Celda del Soldado inicial (T027): global_position (576,500) con
# tile_size 96x96 -> local_to_map floor(576/96)=6, floor(500/96)=5.
const OCCUPIED_TEST_CELL := Vector2i(6, 5)


func test_deploy_on_free_cell_with_enough_ammo_instantiates_soldado_spends_ammo_and_occupies_cell() -> void:
	# Given: el nivel cargado y munición recolectada suficiente para el costo de despliegue
	var level := _load_level()
	var deploy_cost: int = level.soldado_deploy_stats.deploy_ammo_cost
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.add_ammo(deploy_cost + 999) # fondeo generoso, cubre el costo exacto y de sobra

	var board: BoardManager = level.get("_board_manager")
	assert_true(
		board.is_cell_free(FREE_TEST_CELL),
		"precondición del test: la celda objetivo debe empezar libre"
	)
	var ammo_before_deploy: int = EconomyManager.collected_ammo
	var children_before: int = level.get_child_count()

	# When: el jugador despliega un soldado nuevo en una celda libre del tablero (Acceptance Scenario 3)
	level.call("_try_deploy_soldado", FREE_TEST_CELL)

	# Then: se gasta exactamente deploy_ammo_cost del pool global de munición recolectada
	assert_eq(
		EconomyManager.collected_ammo, ammo_before_deploy - deploy_cost,
		"el despliegue exitoso debe descontar exactamente deploy_ammo_cost del pool global (FR-010)"
	)

	# Then: la celda queda ocupada
	assert_false(
		board.is_cell_free(FREE_TEST_CELL),
		"tras un despliegue exitoso, BoardManager.is_cell_free() debe retornar false para esa celda"
	)

	# Then: se instanció exactamente un nuevo Soldado, centrado en la celda, con los stats de despliegue
	assert_eq(
		level.get_child_count(), children_before + 1,
		"el despliegue exitoso debe agregar exactamente un nuevo nodo hijo (el Soldado nuevo) al nivel"
	)
	var tablero: TileMap = level.get_node("Tablero")
	var expected_position: Vector2 = tablero.to_global(tablero.map_to_local(FREE_TEST_CELL))
	var nuevo_soldado: Node = board.get_occupant(FREE_TEST_CELL)
	assert_not_null(
		nuevo_soldado,
		"BoardManager debe registrar al nuevo Soldado como ocupante de la celda desplegada"
	)
	assert_true(
		nuevo_soldado is Soldado,
		"el nodo instanciado en la celda debe ser una instancia de Soldado.tscn (FR-001)"
	)
	assert_eq(
		nuevo_soldado.global_position, expected_position,
		"el nuevo Soldado debe instanciarse centrado en la celda desplegada"
	)
	assert_eq(
		nuevo_soldado.stats, level.soldado_deploy_stats,
		"el nuevo Soldado debe recibir soldado_deploy_stats como sus stats (munición inicial completa, Acceptance Scenario 3)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


func test_deploy_on_free_cell_without_enough_ammo_does_not_deploy_and_signals_rejection() -> void:
	# Given: el nivel cargado con el pool global sin fondos suficientes (Acceptance Scenario 4)
	var level := _load_level()
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 0 # fondos insuficientes, sin importar el estado previo del pool
	watch_signals(EconomyManager)

	var board: BoardManager = level.get("_board_manager")
	var children_before: int = level.get_child_count()

	# When: el jugador intenta desplegar un soldado nuevo en una celda libre sin fondos suficientes
	level.call("_try_deploy_soldado", FREE_TEST_CELL)

	# Then: no se instancia ningún soldado nuevo ni se ocupa la celda
	assert_eq(
		level.get_child_count(), children_before,
		"sin fondos suficientes no debe agregarse ningún nodo hijo nuevo al nivel"
	)
	assert_true(
		board.is_cell_free(FREE_TEST_CELL),
		"sin fondos suficientes la celda objetivo debe seguir libre"
	)

	# Then: el pool global no cambia
	assert_eq(
		EconomyManager.collected_ammo, 0,
		"un intento de despliegue sin fondos suficientes no debe modificar el pool global"
	)

	# Then: el sistema informa al jugador de la restricción (FR-011)
	assert_signal_emitted(
		EconomyManager, "deploy_or_reload_rejected",
		"un despliegue sin fondos suficientes debe emitir deploy_or_reload_rejected (FR-011, Acceptance Scenario 4)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- T043 (FR-013): Área2D "PosicionDefendida" hace que el Enemigo que la
## alcanza emita `reached_defended_position()` ---
##
## `_on_posicion_defendida_body_entered()` es el handler real de
## `nivel_monte_calvo.gd`, ejercitado aquí vía física real (avance del
## `Enemigo` en +Y, `body_entered` real de la `Area2D`), no vía
## `Object.call()` directo — a diferencia de `_try_deploy_soldado()` arriba,
## esta lógica no depende de coordenadas de pantalla/viewport (la limitación
## de `--headless` documentada en `docs/ARCHITECTURE.md` §6 no aplica aquí),
## así que puede probarse de punta a punta con el mecanismo real.

func test_enemigo_que_alcanza_posicion_defendida_fuera_del_carril_del_soldado_emite_la_senal() -> void:
	# Given: el nivel real cargado, más un Enemigo adicional (no el colocado
	# a mano en T027) en un carril lateral (x=200) deliberadamente fuera de
	# "DeteccionRango"/"RangoMelee" del Soldado inicial (x=576 ± 72, ver
	# geometría documentada arriba) — aísla el mecanismo de la Area2D
	# "PosicionDefendida" (T043) del combate automático del soldado (ya
	# cubierto por otros tests): este enemigo debe llegar VIVO a la posición
	# defendida, sin haber sido siquiera detectado en el camino.
	var level := _load_level()
	var enemigo: Enemigo = load(ENEMY_SCENE_PATH).instantiate()
	add_child_autofree(enemigo)
	enemigo.global_position = Vector2(200, 550)
	watch_signals(enemigo)

	var posicion_defendida: Area2D = level.get_node("PosicionDefendida")
	assert_does_not_have(
		posicion_defendida.get_overlapping_bodies(), enemigo,
		"precondición del test: el enemigo lateral no debe empezar ya dentro de PosicionDefendida"
	)

	# When: avanza en +Y por su cuenta (`enemigo.gd._physics_process`, sin
	# intervención del jugador ni del soldado de otro carril) hasta alcanzar
	# la posición defendida
	await wait_physics_frames(170)

	# Then: la Area2D real detecta al Enemigo real y este emite
	# reached_defended_position (contracts/signals.md, FR-013)
	assert_signal_emitted(
		enemigo, "reached_defended_position",
		"un Enemigo que entra en 'PosicionDefendida' debe emitir reached_defended_position (T043, FR-013)"
	)
	assert_signal_not_emitted(
		enemigo, "enemy_defeated",
		"precondición del escenario: el enemigo lateral debe llegar vivo a PosicionDefendida, sin ser detectado/eliminado por el soldado de otro carril"
	)


## Nota de investigación (hallazgo lateral, no bloqueante para T043): un
## `StaticBody2D` NO sirve como "cuerpo ajeno" para este test. Se confirmó
## empíricamente (script de reproducción aislado, fuera del árbol de este
## repo) que un `Area2D` con `monitorable = false` (como "PosicionDefendida"
## y como "DeteccionRango"/"RangoMelee" de `Soldado.tscn`, mismo patrón)
## nunca puebla `get_overlapping_bodies()` ni dispara `body_entered` para un
## `StaticBody2D` que se solape con ella — sea que el `StaticBody2D` ya
## empiece solapado, o que se solape recién después de moverse —, mientras
## que si sí lo hace con normalidad para un `CharacterBody2D` (se mueva o
## no) y para cualquier cuerpo cuando `monitorable = true`. Esto es un
## comportamiento real del motor de físicas de Godot 4.7 (no documentado
## explícitamente: la documentación de `monitorable` solo dice "otras áreas
## pueden detectar esta"), probablemente una optimización interna de
## broadphase que omite pares donde ambos lados son estrictamente estáticos.
## No afecta la corrección de T043 (el único tipo de cuerpo que debe activar
## "PosicionDefendida" es `Enemigo`, un `CharacterBody2D`, que sí se detecta
## con normalidad — ver el test de arriba), pero sí sería relevante si algún
## día un `StaticBody2D` (ej. un `Soldado`) necesitara ser detectado por una
## `Area2D` con `monitorable = false` en este proyecto.
func test_body_ajeno_a_enemy_group_que_entra_en_posicion_defendida_no_causa_error_ni_falso_positivo() -> void:
	# Given: el nivel real cargado y un cuerpo físico cualquiera que NO
	# pertenece a `Enemigo.ENEMY_GROUP` (Edge Case implícito: la Area2D no
	# debe asumir que todo lo que detecta es un Enemigo). Se usa un
	# `CharacterBody2D` (no un `StaticBody2D`) como "cuerpo ajeno" — ver nota
	# de investigación arriba sobre por qué un `StaticBody2D` no sería
	# detectado en absoluto por esta `Area2D` (`monitorable = false`),
	# invalidando la precondición del test antes de ejercitar el guard real.
	var level := _load_level()
	var dummy_body := CharacterBody2D.new()
	var dummy_shape := CollisionShape2D.new()
	var dummy_rect := RectangleShape2D.new()
	dummy_rect.size = Vector2(48, 48)
	dummy_shape.shape = dummy_rect
	dummy_body.add_child(dummy_shape)
	add_child_autofree(dummy_body)
	dummy_body.global_position = Vector2(200, 650) # dentro de PosicionDefendida, lejos del carril del soldado

	# When: el cuerpo ajeno se solapa físicamente con "PosicionDefendida"
	await wait_physics_frames(20)

	# Then: la Area2D real efectivamente lo detectó (confirma que el guard de
	# `_on_posicion_defendida_body_entered()` fue realmente ejercitado, no que
	# el cuerpo nunca llegó a solaparse)...
	var posicion_defendida: Area2D = level.get_node("PosicionDefendida")
	assert_has(
		posicion_defendida.get_overlapping_bodies(), dummy_body,
		"precondición del test: el cuerpo ajeno debe solaparse físicamente con PosicionDefendida para que el guard de tipo se ejercite de verdad"
	)
	# ...pero como no pertenece a ENEMY_GROUP, el guard debe filtrarlo sin
	# intentar tratarlo como Enemigo (un casteo `as Enemigo` sobre este cuerpo
	# es seguro y da `null`; llamar `notify_reached_defended_position()` sobre
	# ese `null` fallaría con un error de script si el guard no filtrara
	# antes) — si el test llega hasta aquí sin que GUT reporte un error de
	# script, el guard funcionó.
	assert_true(
		not dummy_body.is_in_group(Enemigo.ENEMY_GROUP),
		"precondición del test: el cuerpo ajeno no debe pertenecer a Enemigo.ENEMY_GROUP"
	)
	assert_true(
		true,
		"el nivel no debe fallar (error de script) al recibir en PosicionDefendida un cuerpo ajeno a ENEMY_GROUP"
	)


## --- Hallazgo crítico investigado a pedido explícito del orquestador
## (T043 sobre T027): ¿un Enemigo real puede alcanzar físicamente
## "PosicionDefendida" mientras el Soldado colocado en su mismo carril sigue
## vivo? ---
##
## `Soldado` (`StaticBody2D`, `Soldado.tscn`) y `Enemigo` (`CharacterBody2D`,
## `EnemigoBase.tscn`) no declaran `collision_layer`/`collision_mask`
## explícitos en ninguna escena — ambos caen en el default de Godot
## (layer 1, mask 1), por lo que SÍ colisionan físicamente entre sí (aparte
## y además de la detección lógica vía `Area2D` "DeteccionRango"/
## "RangoMelee"/"PosicionDefendida", que son áreas, no cuerpos sólidos).
## Este test lo verifica empíricamente contra las escenas reales de
## producción, aislando el resultado del combate automático (que en el caso
## normal mata al enemigo bastante antes de que llegue a tocar físicamente
## al soldado — ya cubierto por `test_soldado_enemigo_integration.gd`):
## fuerza al Soldado a 0 munición desde antes de su primer disparo, para que
## el único factor que pueda detener al enemigo sea la colisión física en
## sí, no el fusil ni el machete.
##
## Nota sobre por qué un Soldado con 0 munición desde el inicio nunca ataca
## ni a machete tampoco: `soldado.gd._on_ammo_depleted()` (que dispara la
## transición a `MELEE`) solo está conectado a la señal `ammo_depleted`, y
## esa señal únicamente se emite dentro de `_fire_at_current_target()`
## cuando un disparo real deja la munición en 0. Con `_current_ammo` forzado
## a 0 desde antes de que dispare su primer tiro, `_process_rifle()` retorna
## antes de llegar a disparar, así que `ammo_depleted` nunca se emite y el
## Soldado queda atascado en modo `RIFLE` sin disparar ni atacar a machete.
## Es en sí mismo un caso límite no contemplado por `spec.md` (un soldado
## desplegado ya sin munición) — se aprovecha aquí únicamente como forma de
## aislar la variable bajo prueba (colisión física pura), no se reporta como
## un bug de T043 en sí.
##
## Resultado observado empíricamente por este test: el Enemigo NUNCA
## alcanza "PosicionDefendida" mientras el Soldado siga presente en el árbol
## de escena en su carril — queda bloqueado físicamente por la
## `CollisionShape2D` sólida del Soldado bastante antes de llegar al área.
## Dado que en el alcance actual de esta feature `Soldado` no tiene ninguna
## forma de ser derrotado (`soldier_defeated` está documentado en
## `contracts/signals.md` pero no implementado en `soldado.gd` — confirmado
## por búsqueda en el código fuente; ninguna llamada a `take_damage` recibe
## nunca un `Soldado` como objetivo, solo `Enemigo`), este bloqueo es
## PERMANENTE en la práctica dentro del alcance actual: mientras exista un
## Soldado vivo en un carril, ningún enemigo de ESE carril puede activar la
## condición de derrota de FR-013/`spec.md` Acceptance Scenario 3 de User
## Story 3. Se documenta aquí como HALLAZGO CRÍTICO para que el orquestador
## decida si bloquea la aprobación de T043 o se registra como riesgo
## abierto para T044+ (agravado por el hecho de que `wave_spawn_position`,
## T042, es un único punto fijo que coincide exactamente con el carril x del
## Soldado colocado a mano en T027 — todas las oleadas de producción actual
## de este nivel spawnean enemigos en ese mismo carril bloqueado).
func test_enemigo_no_puede_alcanzar_fisicamente_posicion_defendida_mientras_el_soldado_de_su_carril_sigue_vivo() -> void:
	# Given: el nivel real cargado con el Soldado inicial de producción
	# (T027, carril x=576) forzado a 0 munición desde antes de su primer
	# disparo (aísla la colisión física del combate automático), y el
	# Enemigo colocado a mano (mismo carril) con move_speed acelerado (solo
	# para que el test corra en tiempo razonable, no muta el .tres
	# compartido de producción — se le asigna una instancia nueva de
	# EnemyStats)
	var level := _load_level()
	var soldado: Soldado = level.get_node("Soldado")
	soldado.set("_current_ammo", 0)

	var enemigo: Enemigo = level.get_node("Enemigo")
	var fast_stats := EnemyStats.new()
	fast_stats.max_health = enemigo.stats.max_health
	fast_stats.move_speed = 600.0
	fast_stats.melee_damage = enemigo.stats.melee_damage
	fast_stats.ammo_drop = enemigo.stats.ammo_drop
	enemigo.stats = fast_stats

	watch_signals(enemigo)

	# When: transcurre tiempo muy por encima del necesario para que, sin
	# obstáculos, el enemigo recorra la distancia real hasta
	# "PosicionDefendida" ((576,50) -> (576,650) = 600px, a 600px/s tomaría
	# ~1s/60 frames sin obstáculos; se esperan 90 para dejar margen de sobra)
	await wait_physics_frames(90)

	# Then: el soldado nunca disparó ni hizo daño (0 munición forzada desde
	# antes de su primer physics frame) — el enemigo real sigue íntegro
	assert_signal_not_emitted(
		enemigo, "enemy_defeated",
		"con 0 munición forzada de antemano, el soldado no debe haber dañado ni eliminado al enemigo"
	)
	assert_true(
		is_instance_valid(enemigo),
		"el enemigo debe seguir vivo — un soldado sin munición no puede matarlo ni a fusil ni a machete"
	)

	# Then: HALLAZGO CRÍTICO — pese a tiempo de sobra para recorrer sin
	# obstáculos la distancia real hasta "PosicionDefendida", el enemigo
	# NUNCA la alcanza: queda bloqueado físicamente por la colisión sólida
	# del Soldado (mismo layer/mask=1 por defecto en ambas escenas), mucho
	# antes de llegar al área.
	assert_signal_not_emitted(
		enemigo, "reached_defended_position",
		"HALLAZGO CRÍTICO (T043): un Enemigo real, en el mismo carril que un Soldado vivo (aunque sin munición), nunca alcanza físicamente 'PosicionDefendida' — queda bloqueado por la colisión sólida por defecto entre StaticBody2D y CharacterBody2D (mismo layer/mask=1 implícito, ver nota de cabecera de este test y contracts/signals.md)"
	)
	assert_true(
		enemigo.global_position.y < soldado.global_position.y,
		"HALLAZGO CRÍTICO (T043): el enemigo debe quedar detenido ANTES de alcanzar siquiera la posición Y del propio Soldado (576,500), confirmando bloqueo físico real, no una simple falta de tiempo de simulación"
	)


func test_deploy_on_already_occupied_cell_does_not_deploy_or_spend_ammo() -> void:
	# Given: el nivel cargado (el Soldado inicial ya registrado como
	# ocupante de su celda desde _ready(), T027/T035) y fondos de sobra
	var level := _load_level()
	var deploy_cost: int = level.soldado_deploy_stats.deploy_ammo_cost
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.add_ammo(deploy_cost + 999)
	watch_signals(EconomyManager)

	var board: BoardManager = level.get("_board_manager")
	assert_false(
		board.is_cell_free(OCCUPIED_TEST_CELL),
		"precondición del test: la celda del Soldado inicial debe registrarse como ocupada desde _ready()"
	)
	var ammo_before_deploy: int = EconomyManager.collected_ammo
	var children_before: int = level.get_child_count()

	# When: el jugador intenta desplegar sobre una celda ya ocupada (spec.md Edge Cases)
	level.call("_try_deploy_soldado", OCCUPIED_TEST_CELL)

	# Then: no se instancia ningún soldado nuevo
	assert_eq(
		level.get_child_count(), children_before,
		"una celda ya ocupada no debe agregar ningún nodo hijo nuevo al nivel (Edge Case: posición ya ocupada)"
	)

	# Then: no se gasta munición del pool global (la validación de celda ocurre ANTES de intentar gastar)
	assert_eq(
		EconomyManager.collected_ammo, ammo_before_deploy,
		"una celda ya ocupada no debe gastar munición del pool global"
	)
	assert_signal_not_emitted(
		EconomyManager, "deploy_or_reload_rejected",
		"una celda ya ocupada no debe siquiera intentar gastar munición, por lo que tampoco debe emitir deploy_or_reload_rejected"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- T054 (`spec.md` Edge Case de derrota del Soldado: "libera esa
## posición del tablero"): derrotar un Soldado del nivel (colocado a mano o
## desplegado) debe liberar su celda en `_board_manager` ---
##
## `soldier_defeated` se emite de forma SÍNCRONA dentro de `take_damage()`
## (`soldado.gd._die()`, antes de `queue_free()`), así que
## `_on_soldado_defeated()` (`nivel_monte_calvo.gd`) ya corrió -y
## `_board_manager.free_cell()` ya se aplicó- para cuando `take_damage()`
## retorna: no hace falta `await` de ningún frame para observar el efecto.

func test_soldado_inicial_colocado_a_mano_defeated_libera_su_celda_en_board_manager() -> void:
	# Given: el nivel real cargado, con el Soldado inicial (T027) ya
	# registrado como ocupante de su celda desde _ready() (T054)
	var level := _load_level()
	var soldado: Soldado = level.get_node("Soldado")
	var board: BoardManager = level.get("_board_manager")
	assert_false(
		board.is_cell_free(OCCUPIED_TEST_CELL),
		"precondición del test: la celda del Soldado inicial debe empezar ocupada"
	)

	# When: el Soldado inicial es derrotado (daño suficiente para agotar toda
	# su salud de producción en una sola llamada)
	soldado.take_damage(soldado.stats.max_health)

	# Then: su celda queda libre en el BoardManager del nivel (spec.md Edge
	# Case: "libera esa posición del tablero")
	assert_true(
		board.is_cell_free(OCCUPIED_TEST_CELL),
		"al derrotar al Soldado inicial colocado a mano, su celda debe quedar libre en BoardManager (T054)"
	)
	assert_null(
		board.get_occupant(OCCUPIED_TEST_CELL),
		"tras la derrota, BoardManager.get_occupant() de esa celda debe volver a ser null"
	)


func test_soldado_desplegado_defeated_libera_su_celda_en_board_manager() -> void:
	# Given: el nivel real cargado y un Soldado nuevo desplegado en una celda
	# libre (T035)
	var level := _load_level()
	var original_collected_ammo: int = EconomyManager.collected_ammo
	var deploy_cost: int = level.soldado_deploy_stats.deploy_ammo_cost
	EconomyManager.add_ammo(deploy_cost + 999)

	var board: BoardManager = level.get("_board_manager")
	level.call("_try_deploy_soldado", FREE_TEST_CELL)
	var soldado_desplegado: Soldado = board.get_occupant(FREE_TEST_CELL)
	assert_not_null(
		soldado_desplegado,
		"precondición del test: el despliegue debe haber registrado un Soldado como ocupante de la celda"
	)

	# When: el Soldado desplegado es derrotado
	soldado_desplegado.take_damage(soldado_desplegado.stats.max_health)

	# Then: su celda vuelve a quedar libre en el BoardManager del nivel
	assert_true(
		board.is_cell_free(FREE_TEST_CELL),
		"al derrotar a un Soldado desplegado dinámicamente, su celda debe quedar libre en BoardManager (T054)"
	)
	assert_null(
		board.get_occupant(FREE_TEST_CELL),
		"tras la derrota, BoardManager.get_occupant() de esa celda debe volver a ser null"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


func test_celda_liberada_tras_derrota_puede_volver_a_desplegarse_un_nuevo_soldado() -> void:
	# Given: el nivel real cargado, un Soldado desplegado en una celda libre,
	# y luego derrotado (cierra el ciclo completo del Edge Case: la celda no
	# solo se marca libre internamente, sino que vuelve a estar disponible
	# para el jugador)
	var level := _load_level()
	var original_collected_ammo: int = EconomyManager.collected_ammo
	var deploy_cost: int = level.soldado_deploy_stats.deploy_ammo_cost
	EconomyManager.add_ammo(2 * deploy_cost + 999)

	var board: BoardManager = level.get("_board_manager")
	level.call("_try_deploy_soldado", FREE_TEST_CELL)
	var primer_soldado: Soldado = board.get_occupant(FREE_TEST_CELL)
	primer_soldado.take_damage(primer_soldado.stats.max_health)
	assert_true(
		board.is_cell_free(FREE_TEST_CELL),
		"precondición del test: la celda debe quedar libre tras derrotar al primer Soldado desplegado ahí"
	)
	var children_before_redeploy: int = level.get_child_count()

	# When: el jugador despliega un segundo Soldado nuevo sobre esa misma
	# celda, ahora liberada
	level.call("_try_deploy_soldado", FREE_TEST_CELL)

	# Then: el segundo despliegue tiene éxito (la celda vuelve a estar
	# disponible para el jugador, cerrando el ciclo completo del Edge Case)
	assert_eq(
		level.get_child_count(), children_before_redeploy + 1,
		"un segundo despliegue sobre la celda liberada debe agregar un nuevo Soldado al nivel"
	)
	assert_false(
		board.is_cell_free(FREE_TEST_CELL),
		"tras el segundo despliegue exitoso, la celda debe quedar ocupada de nuevo"
	)
	var segundo_soldado: Node = board.get_occupant(FREE_TEST_CELL)
	assert_not_null(segundo_soldado, "el segundo Soldado debe quedar registrado como ocupante de la celda")
	assert_true(
		segundo_soldado is Soldado,
		"el nodo instanciado en el segundo despliegue debe ser una instancia de Soldado.tscn"
	)
	assert_ne(
		segundo_soldado, primer_soldado,
		"el segundo Soldado desplegado debe ser una instancia distinta del primero (derrotado)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo
