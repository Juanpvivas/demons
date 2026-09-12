extends GutTest
## T010: verifica que `EconomyManager` y `GameStateManager` están registrados
## como autoloads en `project.godot` y son realmente accesibles como
## singleton global en runtime — no solo que el `.gd` parsea sin error.
##
## A diferencia de `test_economy_manager.gd`/`test_game_state_manager.gd`
## (que hasta T010 cargaban el script vía `load(...).new()` porque el
## autoload todavía no existía), este archivo referencia `EconomyManager` y
## `GameStateManager` directamente por su nombre global, exactamente como lo
## haría cualquier otro script del juego (`soldado.gd`, `hud.gd`, etc.). Si
## `project.godot` tuviera la ruta del script mal escrita, un typo en el
## nombre del singleton, o el autoload no cargara por cualquier otra razón,
## estas referencias fallarían en tiempo de parseo/análisis del propio test
## script (identificador desconocido) o el objeto no tendría los miembros
## esperados — la sola presencia de la línea en `[autoload]` no lo garantiza.

func test_economy_manager_is_accessible_as_global_singleton() -> void:
	# Given/When: el proyecto arrancó con EconomyManager en [autoload] de
	# project.godot. Then: el identificador global EconomyManager resuelve a
	# una instancia real de Node en el árbol, no null ni una referencia rota.
	assert_not_null(
		EconomyManager,
		"EconomyManager debe existir como singleton global accesible por nombre (registrado en [autoload])"
	)
	assert_true(
		EconomyManager is Node,
		"el singleton global EconomyManager debe ser un Node"
	)


func test_economy_manager_singleton_is_in_scene_tree() -> void:
	# Un autoload real vive en el árbol de escena (accesible vía
	# get_tree().root), no es simplemente una variable global desconectada.
	assert_true(
		EconomyManager.is_inside_tree(),
		"el singleton EconomyManager debe estar dentro del árbol de escena (autoload real, no una instancia suelta)"
	)


func test_economy_manager_singleton_exposes_expected_state_and_signals() -> void:
	# Confirma que el singleton cargado vía autoload es la misma clase
	# esperada (mismo campo/señales que definió T008), no un stub vacío.
	assert_eq(
		EconomyManager.collected_ammo, 0,
		"el singleton EconomyManager debe exponer collected_ammo inicializado en 0"
	)
	assert_true(
		EconomyManager.has_signal("ammo_pool_changed"),
		"el singleton EconomyManager debe exponer la señal ammo_pool_changed"
	)
	assert_true(
		EconomyManager.has_signal("ammo_pickup_spawned"),
		"el singleton EconomyManager debe exponer la señal ammo_pickup_spawned"
	)


func test_game_state_manager_is_accessible_as_global_singleton() -> void:
	assert_not_null(
		GameStateManager,
		"GameStateManager debe existir como singleton global accesible por nombre (registrado en [autoload])"
	)
	assert_true(
		GameStateManager is Node,
		"el singleton global GameStateManager debe ser un Node"
	)


func test_game_state_manager_singleton_is_in_scene_tree() -> void:
	assert_true(
		GameStateManager.is_inside_tree(),
		"el singleton GameStateManager debe estar dentro del árbol de escena (autoload real, no una instancia suelta)"
	)


func test_game_state_manager_singleton_exposes_expected_state_and_signals() -> void:
	assert_eq(
		GameStateManager._current_state, GameStateManager.GameState.PLAYING,
		"el singleton GameStateManager debe iniciar en GameState.PLAYING"
	)
	assert_true(
		GameStateManager.has_signal("game_won"),
		"el singleton GameStateManager debe exponer la señal game_won"
	)
	assert_true(
		GameStateManager.has_signal("game_lost"),
		"el singleton GameStateManager debe exponer la señal game_lost"
	)
	assert_true(
		GameStateManager.has_signal("game_state_changed"),
		"el singleton GameStateManager debe exponer la señal game_state_changed"
	)


func test_economy_manager_and_game_state_manager_are_distinct_singleton_instances() -> void:
	# Edge case: dos autoloads distintos no deben resolver accidentalmente al
	# mismo nodo (ej. copy-paste error en project.godot apuntando ambos
	# nombres al mismo script/instancia).
	assert_ne(
		EconomyManager.get_instance_id(), GameStateManager.get_instance_id(),
		"EconomyManager y GameStateManager deben ser instancias de autoload distintas"
	)


func test_economy_manager_state_persists_across_reference_accesses() -> void:
	# Confirma que EconomyManager es un singleton (misma instancia
	# persistente), no algo que Godot re-crea por cada acceso: mutar el
	# estado a través de una referencia debe ser visible en un acceso
	# posterior por nombre.
	var original_value := EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 42

	assert_eq(
		EconomyManager.collected_ammo, 42,
		"el estado mutado en el singleton EconomyManager debe persistir entre accesos (misma instancia global)"
	)

	# Cleanup: restaurar para no afectar otros tests que compartan runtime.
	EconomyManager.collected_ammo = original_value
