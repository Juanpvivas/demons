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
