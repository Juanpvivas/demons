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
