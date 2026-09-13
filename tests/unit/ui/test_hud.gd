extends GutTest
## T036: test de `scenes/ui/HUD.tscn` + `scenes/ui/hud.gd` — cubre FR-015
## ("mostrar al jugador la cantidad de munición recolectada disponible") y
## FR-011 ("impedir... e informar al jugador de esta restricción",
## `spec.md` User Story 2 Acceptance Scenario 4), vía `contracts/signals.md`
## (`EconomyManager.ammo_pool_changed` / `deploy_or_reload_rejected`).
##
## EconomyManager es un autoload real (`project.godot`, T010) compartido en
## el mismo proceso GUT entre TODOS los archivos de test — cualquier test que
## mute `collected_ammo` (directamente o vía `add_ammo`/`try_spend_ammo`)
## restaura su valor original al final, mismo patrón que
## `tests/unit/units/test_soldado.gd` y `tests/unit/levels/test_nivel_montecalvo.gd`.
##
## Se accede a los miembros internos con prefijo `_` del HUD (`_ammo_label`,
## `_rejection_label`, `_rejection_message_timer`) directamente desde el
## test, mismo patrón ya usado en el proyecto para verificar estado interno
## de un autoload (`test_game_state_manager.gd` con `_current_state`) — en
## GDScript el guion bajo es solo convención, no impone visibilidad real, y
## no hay una API pública alternativa para leer el texto mostrado en un
## `Label` de una escena concreta (no reutilizable) como esta.
##
## T045 (más abajo): mismas convenciones para las dos responsabilidades que
## agrega esa tarea (`spec.md` User Story 3) — aviso de "oleada por llegar"
## (`WaveManager.wave_started`) y pantalla de victoria/derrota
## (`GameStateManager.game_won`/`game_lost`).
##
## `WaveManager` y `GameStateManager` son también autoloads reales
## compartidos entre archivos de test (`project.godot`, T010/T040). A
## diferencia de `EconomyManager.collected_ammo` (un simple `int` mutado y
## restaurado), aquí se emite la señal DIRECTAMENTE sobre el autoload real
## (`WaveManager.wave_started.emit(n)`, `GameStateManager.game_won.emit()`,
## `GameStateManager.game_lost.emit()`) en vez de pasar por el método que
## dispara la lógica de negocio real (`start_waves()`,
## `report_reached_defended_position()`, `_on_all_waves_completed()`) —
## mismo patrón ya usado más abajo para el segundo rechazo de munición
## (`EconomyManager.deploy_or_reload_rejected.emit(...)`). Esto aísla el
## test del HUD de la lógica de esos otros autoloads (ya cubierta por
## `test_wave_manager.gd`/`test_game_state_manager.gd`) y evita dejar al
## autoload real en un estado mutado que afecte a otros archivos de test:
## emitir la señal a mano no cambia `current_wave_index` ni `_current_state`
## internos, así que no requiere restaurar nada al terminar.

const HUD_SCENE_PATH := "res://scenes/ui/HUD.tscn"

var _hud: Node


func before_each() -> void:
	_hud = null


func _spawn_hud() -> Node:
	_hud = load(HUD_SCENE_PATH).instantiate()
	add_child_autofree(_hud)
	return _hud


## --- Contador de munición al instanciar (FR-015) ---

func test_ammo_label_reflects_already_collected_ammo_immediately_on_ready() -> void:
	# Given: el pool global ya tiene munición recolectada ANTES de que el HUD
	# se instancie (ej. el HUD entra al árbol después de una recolección
	# previa; `ammo_pool_changed` solo se emite ante cambios posteriores, no
	# al conectar, así que el HUD debe leer el valor actual explícitamente)
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 17

	# When: se instancia el HUD y entra al árbol
	_spawn_hud()

	# Then: el contador de munición refleja ese valor ya existente sin
	# esperar ningún cambio posterior
	assert_string_contains(
		_hud._ammo_label.text, "17",
		"el Label de munición debe reflejar collected_ammo ya existente al instanciar el HUD (FR-015)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- Actualización del contador ante ammo_pool_changed (FR-015) ---

func test_ammo_label_updates_when_ammo_pool_changed_is_emitted() -> void:
	# Given: un HUD ya instanciado con un valor inicial conocido
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 2
	_spawn_hud()

	# When: el pool global cambia (ej. el jugador recolecta munición de un enemigo derrotado)
	EconomyManager.add_ammo(3)

	# Then: el contador refleja el nuevo total (2 + 3 = 5), no el valor inicial
	assert_string_contains(
		_hud._ammo_label.text, "5",
		"el Label de munición debe actualizarse al nuevo total tras ammo_pool_changed (FR-015)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- Mensaje de rechazo por munición insuficiente (FR-011, US2 Scenario 4) ---

func test_rejection_message_becomes_visible_with_reason_on_insufficient_funds() -> void:
	# Given: un HUD ya instanciado, con el pool global sin fondos suficientes
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 0
	_spawn_hud()
	assert_false(
		_hud._rejection_label.visible,
		"precondición del test: el mensaje de rechazo debe empezar oculto"
	)

	# When: el jugador intenta recargar o desplegar sin munición recolectada suficiente
	EconomyManager.try_spend_ammo(999)

	# Then: el sistema le informa de la restricción (FR-011) con un mensaje visible
	assert_true(
		_hud._rejection_label.visible,
		"el mensaje de rechazo debe volverse visible al recibir deploy_or_reload_rejected"
	)
	assert_eq(
		_hud._rejection_label.text, "Munición insuficiente",
		"el mensaje de rechazo debe mostrar el motivo (reason) recibido en la señal"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


func test_ammo_label_is_unaffected_by_a_rejected_spend() -> void:
	# Given: un HUD con un valor de munición conocido y sin fondos suficientes
	# para el próximo gasto
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 3
	_spawn_hud()

	# When: se rechaza un intento de gasto (EconomyManager no muta collected_ammo)
	EconomyManager.try_spend_ammo(999)

	# Then: el contador de munición sigue mostrando el mismo valor, sin cambios
	assert_string_contains(
		_hud._ammo_label.text, "3",
		"un gasto rechazado no debe alterar el contador de munición mostrado (no se emite ammo_pool_changed)"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- Ocultamiento automático del mensaje de rechazo ---
##
## `hud.gd` documenta que el mensaje se oculta al expirar
## `RejectionMessageTimer` (`one_shot`, 2.5s, `HUD.tscn`). En vez de esperar
## 2.5s reales de wall-clock (lento y potencialmente frágil en CI), se
## emite directamente la señal `timeout` del propio `Timer` del HUD ya
## instanciado — ejercita el handler real conectado en `_ready()`
## (`_on_rejection_message_timer_timeout`), sin depender de temporización
## real ni de un mecanismo de "fast-forward" de `Timer` (Godot no expone
## uno; `Timer.time_left` es de solo lectura).

func test_rejection_message_hides_when_rejection_timer_times_out() -> void:
	# Given: un HUD con el mensaje de rechazo ya visible
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 0
	_spawn_hud()
	EconomyManager.try_spend_ammo(999)
	assert_true(
		_hud._rejection_label.visible,
		"precondición del test: el mensaje de rechazo debe estar visible antes del timeout"
	)

	# When: el temporizador de ocultamiento expira
	_hud._rejection_message_timer.emit_signal("timeout")

	# Then: el mensaje de rechazo se oculta automáticamente
	assert_false(
		_hud._rejection_label.visible,
		"el mensaje de rechazo debe ocultarse cuando RejectionMessageTimer emite timeout"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## Nota sobre "un nuevo rechazo reinicia el temporizador completo" (descrito
## en el reporte de `dev-godot` sobre `hud.gd`): verificar el reinicio
## *desde un valor parcial* requeriría dejar transcurrir tiempo real de
## wall-clock antes del segundo rechazo (`Timer.time_left` es de solo
## lectura y no hay forma de fast-forward/simular su conteo interno de
## forma determinista en GUT) — el mismo tipo de dependencia frágil que
## `test_nivel_montecalvo.gd` documenta evitar deliberadamente para T035.
## Se omite esa verificación específica; el test siguiente sí cubre, sin
## depender de tiempo real, que un segundo rechazo mientras el mensaje
## anterior sigue visible no lo oculta y reemplaza su texto (el
## comportamiento observable que importa para FR-011).
func test_new_rejection_while_previous_message_still_visible_keeps_it_visible_and_replaces_text() -> void:
	# Given: un HUD con un primer mensaje de rechazo ya visible
	var original_collected_ammo: int = EconomyManager.collected_ammo
	EconomyManager.collected_ammo = 0
	_spawn_hud()
	EconomyManager.try_spend_ammo(999)
	assert_true(
		_hud._rejection_label.visible,
		"precondición del test: el primer mensaje de rechazo debe estar visible"
	)

	# When: ocurre un segundo rechazo antes de que el primer mensaje se oculte
	EconomyManager.deploy_or_reload_rejected.emit("Otro motivo de rechazo")

	# Then: el mensaje sigue visible (no se oculta a mitad de camino) y su
	# texto se reemplaza por el del rechazo más reciente
	assert_true(
		_hud._rejection_label.visible,
		"el mensaje de rechazo debe seguir visible tras un segundo rechazo mientras el anterior no expiró"
	)
	assert_eq(
		_hud._rejection_label.text, "Otro motivo de rechazo",
		"un nuevo rechazo debe reemplazar el texto del mensaje anterior"
	)

	# Cleanup: restaurar el pool global compartido entre tests/archivos.
	EconomyManager.collected_ammo = original_collected_ammo


## --- T045: estado inicial oculto (spec.md US3, Principio III de
## --- constitution.md — ningún aviso debe aparecer antes de que ocurra el
## --- evento que lo dispara) ---

func test_wave_label_starts_hidden_on_ready() -> void:
	_spawn_hud()

	assert_false(
		_hud._wave_label.visible,
		"el aviso de oleada por llegar debe empezar oculto en _ready()"
	)


func test_game_over_screen_starts_hidden_on_ready() -> void:
	_spawn_hud()

	assert_false(
		_hud._game_over_screen.visible,
		"la pantalla de victoria/derrota debe empezar oculta en _ready()"
	)


## --- T045: aviso de "oleada por llegar" (WaveManager.wave_started,
## --- contracts/signals.md, Principio III de constitution.md) ---

func test_wave_label_becomes_visible_with_wave_number_on_wave_started() -> void:
	# Given: un HUD ya instanciado, con el aviso de oleada oculto
	_spawn_hud()
	assert_false(
		_hud._wave_label.visible,
		"precondición del test: el aviso de oleada debe empezar oculto"
	)

	# When: WaveManager anuncia el comienzo de una nueva oleada
	WaveManager.wave_started.emit(3)

	# Then: el aviso se hace visible con el número de oleada (Principio III:
	# ninguna oleada nueva debe ser una transición silenciosa)
	assert_true(
		_hud._wave_label.visible,
		"el aviso de oleada debe volverse visible al recibir wave_started"
	)
	assert_string_contains(
		_hud._wave_label.text, "3",
		"el aviso de oleada debe mostrar el número de la oleada que comienza"
	)


func test_wave_label_hides_when_wave_message_timer_times_out() -> void:
	# Given: un HUD con el aviso de oleada ya visible
	_spawn_hud()
	WaveManager.wave_started.emit(1)
	assert_true(
		_hud._wave_label.visible,
		"precondición del test: el aviso de oleada debe estar visible antes del timeout"
	)

	# When: el temporizador de ocultamiento expira (mismo patrón que
	# RejectionMessageTimer: se emite `timeout` directamente sobre el propio
	# Timer del HUD ya instanciado, sin depender de tiempo real de wall-clock)
	_hud._wave_message_timer.emit_signal("timeout")

	# Then: el aviso se oculta automáticamente
	assert_false(
		_hud._wave_label.visible,
		"el aviso de oleada debe ocultarse cuando WaveMessageTimer emite timeout"
	)


## Mismo patrón discriminante que
## `test_new_rejection_while_previous_message_still_visible_keeps_it_visible_and_replaces_text`
## (T036): en vez de depender de tiempo real de wall-clock para verificar que
## el temporizador se reinicia desde un valor parcial (`Timer.time_left` es
## de solo lectura, sin forma determinista de fast-forward), se verifica el
## comportamiento observable que importa: un segundo `wave_started` mientras
## el aviso anterior sigue visible no lo oculta a mitad de camino, y
## reemplaza su texto por el de la oleada más reciente.
func test_new_wave_started_while_previous_message_still_visible_keeps_it_visible_and_replaces_text() -> void:
	# Given: un HUD con un primer aviso de oleada ya visible
	_spawn_hud()
	WaveManager.wave_started.emit(1)
	assert_true(
		_hud._wave_label.visible,
		"precondición del test: el primer aviso de oleada debe estar visible"
	)

	# When: comienza otra oleada antes de que el primer aviso se oculte
	WaveManager.wave_started.emit(2)

	# Then: el aviso sigue visible (no se oculta a mitad de camino) y su
	# texto se reemplaza por el de la oleada más reciente
	assert_true(
		_hud._wave_label.visible,
		"el aviso de oleada debe seguir visible tras un segundo wave_started mientras el anterior no expiró"
	)
	assert_string_contains(
		_hud._wave_label.text, "2",
		"un nuevo wave_started debe reemplazar el texto del aviso anterior con el número de oleada más reciente"
	)


## --- T045: pantallas de victoria/derrota (GameStateManager.game_won /
## --- game_lost, contracts/signals.md, spec.md US3 Acceptance Scenarios 2 y
## --- 3) ---

func test_game_over_screen_shows_victoria_on_game_won() -> void:
	# Given: un HUD ya instanciado, con la pantalla de fin de partida oculta
	_spawn_hud()
	assert_false(
		_hud._game_over_screen.visible,
		"precondición del test: la pantalla de fin de partida debe empezar oculta"
	)

	# When: GameStateManager anuncia la condición de victoria (spec.md US3
	# Acceptance Scenario 2: "todos los enemigos de todas las oleadas
	# programadas son derrotados... el jugador recibe una condición de
	# victoria")
	GameStateManager.game_won.emit()

	# Then: la pantalla de fin de partida se hace visible con el texto de
	# victoria
	assert_true(
		_hud._game_over_screen.visible,
		"la pantalla de fin de partida debe volverse visible al recibir game_won"
	)
	assert_eq(
		_hud._game_over_label.text, "VICTORIA",
		"la pantalla de fin de partida debe mostrar el mensaje de victoria"
	)


func test_game_over_screen_shows_derrota_on_game_lost() -> void:
	# Given: un HUD ya instanciado, con la pantalla de fin de partida oculta
	_spawn_hud()
	assert_false(
		_hud._game_over_screen.visible,
		"precondición del test: la pantalla de fin de partida debe empezar oculta"
	)

	# When: GameStateManager anuncia la condición de derrota (spec.md US3
	# Acceptance Scenario 3: "un enemigo alcanza la posición defendida... la
	# partida termina en derrota para el jugador")
	GameStateManager.game_lost.emit()

	# Then: la pantalla de fin de partida se hace visible con el texto de
	# derrota
	assert_true(
		_hud._game_over_screen.visible,
		"la pantalla de fin de partida debe volverse visible al recibir game_lost"
	)
	assert_eq(
		_hud._game_over_label.text, "DERROTA",
		"la pantalla de fin de partida debe mostrar el mensaje de derrota"
	)
