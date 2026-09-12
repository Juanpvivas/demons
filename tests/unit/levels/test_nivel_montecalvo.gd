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
