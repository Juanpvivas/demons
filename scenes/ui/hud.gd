## HUD global del nivel (`docs/ARCHITECTURE.md` §5: "instancia de HUD.tscn
## como CanvasLayer" dentro de `Nivel_MonteCalvo.tscn`). Dos
## responsabilidades en el alcance de T036 (`spec.md` User Story 2):
##
## - Contador de munición recolectada (FR-015, `contracts/signals.md` fila
##   `ammo_pool_changed`): refleja `EconomyManager.collected_ammo`,
##   inicializado al arrancar (no solo esperando el primer cambio) y
##   actualizado en cada `ammo_pool_changed`.
## - Mensaje de rechazo (FR-011, `contracts/signals.md` fila
##   `deploy_or_reload_rejected`): al recibir la señal con su `reason`, lo
##   muestra en un `Label` separado. No hay spec de UX detallada para el
##   MVP sobre cuánto debe durar un mensaje en pantalla, así que se opta
##   por el mecanismo más simple y explícito: un `Timer` `one_shot` que
##   oculta el mensaje al expirar (`RejectionMessageTimer`, `HUD.tscn`);
##   un nuevo rechazo mientras el anterior sigue visible reemplaza el texto
##   y reinicia el temporizador, dándole su propio tiempo completo de
##   lectura en vez de ocultarse a mitad de camino.
##
## T045 (`spec.md` User Story 3) agrega dos responsabilidades más, ambas
## por Principio III de `constitution.md` (prohíbe transiciones silenciosas):
##
## - Aviso de "oleada por llegar" (`contracts/signals.md` fila
##   `WaveManager.wave_started`): mismo mecanismo que el mensaje de
##   rechazo — `Label` (`WaveLabel`) + `Timer` `one_shot`
##   (`WaveMessageTimer`) independiente del de rechazo, para que ambos
##   avisos puedan solaparse sin pisarse el temporizador entre sí. Tampoco
##   hay spec de UX detallada aquí; se reutiliza el patrón ya validado en
##   T036 en vez de inventar uno nuevo.
## - Pantalla de victoria/derrota (`contracts/signals.md` filas
##   `GameStateManager.game_won`/`game_lost`): un único `Control`
##   (`GameOverScreen`) a pantalla completa, oculto por defecto, con un
##   `Label` (`GameOverLabel`) cuyo texto cambia según la señal recibida
##   ("VICTORIA"/"DERROTA") — se reutiliza el mismo nodo para ambos casos
##   porque el spec no pide presentación visual distinta entre victoria y
##   derrota para el MVP, y `GameStateManager` garantiza que el estado es
##   terminal (nunca se reciben ambas señales en la misma partida). Al
##   quedar visible, su `Control` por defecto (`mouse_filter` = `STOP`)
##   bloquea los clics de gameplay que llegan al tablero debajo (recolectar
##   munición, desplegar soldados) — supuesto de implementación: T045 pide
##   solo el feedback visual, no un flujo de game over completo (sin botón
##   de reinicio ni cambio de escena, fuera de alcance de esta tarea), pero
##   dejar el tablero clickeable detrás de un cartel de "VICTORIA"/"DERROTA"
##   sería confuso para el jugador.
##
## No declara `class_name`: igual que `nivel_monte_calvo.gd`, es una
## instancia concreta única por nivel (un solo HUD vivo por partida), no un
## tipo reutilizable instanciado múltiples veces desde otro script — a
## diferencia de `Soldado`/`AmmoPickup`, que sí lo declaran por
## instanciarse muchas veces en runtime.
extends CanvasLayer

@onready var _ammo_label: Label = $Root/Info/AmmoLabel
@onready var _rejection_label: Label = $Root/Info/RejectionLabel
@onready var _rejection_message_timer: Timer = $RejectionMessageTimer
@onready var _wave_label: Label = $Root/Info/WaveLabel
@onready var _wave_message_timer: Timer = $WaveMessageTimer
@onready var _game_over_screen: Control = $GameOverScreen
@onready var _game_over_label: Label = $GameOverScreen/CenterContainer/GameOverLabel


func _ready() -> void:
	# Conexión de señales de autoload solo en `_ready()`
	# (`docs/ARCHITECTURE.md` §4.2), mismo patrón que `soldado.gd`.
	EconomyManager.ammo_pool_changed.connect(_on_ammo_pool_changed)
	EconomyManager.deploy_or_reload_rejected.connect(_on_deploy_or_reload_rejected)
	_rejection_message_timer.timeout.connect(_on_rejection_message_timer_timeout)

	WaveManager.wave_started.connect(_on_wave_started)
	_wave_message_timer.timeout.connect(_on_wave_message_timer_timeout)

	GameStateManager.game_won.connect(_on_game_won)
	GameStateManager.game_lost.connect(_on_game_lost)

	# Estado inicial mostrado sin esperar el primer cambio: el pool global
	# ya puede tener un valor != 0 si este HUD se instancia después de que
	# el jugador recolectó munición (`ammo_pool_changed` solo se emite ante
	# cambios posteriores, nunca al conectar).
	_update_ammo_label(EconomyManager.collected_ammo)
	_rejection_label.visible = false
	_wave_label.visible = false
	_game_over_screen.visible = false


func _on_ammo_pool_changed(new_amount: int) -> void:
	_update_ammo_label(new_amount)


func _update_ammo_label(amount: int) -> void:
	_ammo_label.text = "Munición: %d" % amount


## FR-011: muestra el motivo del rechazo y (re)inicia el temporizador de
## ocultamiento.
func _on_deploy_or_reload_rejected(reason: String) -> void:
	_rejection_label.text = reason
	_rejection_label.visible = true
	_rejection_message_timer.start()


func _on_rejection_message_timer_timeout() -> void:
	_rejection_label.visible = false


## `contracts/signals.md` fila `WaveManager.wave_started` — Principio III
## de `constitution.md`: toda oleada nueva se anuncia explícitamente, nunca
## como transición silenciosa. Mismo mecanismo que
## `_on_deploy_or_reload_rejected()`: un nuevo `wave_started` mientras el
## aviso anterior sigue visible reemplaza el texto y reinicia el
## temporizador, dándole su propio tiempo completo de lectura.
func _on_wave_started(wave_number: int) -> void:
	_wave_label.text = "Oleada %d por llegar" % wave_number
	_wave_label.visible = true
	_wave_message_timer.start()


func _on_wave_message_timer_timeout() -> void:
	_wave_label.visible = false


## `contracts/signals.md` fila `GameStateManager.game_won`. Ver cabecera
## del archivo para el supuesto de implementación (pantalla compartida con
## `game_lost`, sin botón de reinicio ni cambio de escena — fuera de
## alcance de T045).
func _on_game_won() -> void:
	_show_game_over_screen("VICTORIA")


## `contracts/signals.md` fila `GameStateManager.game_lost`. Mismo
## mecanismo que `_on_game_won()`.
func _on_game_lost() -> void:
	_show_game_over_screen("DERROTA")


func _show_game_over_screen(message: String) -> void:
	_game_over_label.text = message
	_game_over_screen.visible = true
