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
## No declara `class_name`: igual que `nivel_monte_calvo.gd`, es una
## instancia concreta única por nivel (un solo HUD vivo por partida), no un
## tipo reutilizable instanciado múltiples veces desde otro script — a
## diferencia de `Soldado`/`AmmoPickup`, que sí lo declaran por
## instanciarse muchas veces en runtime.
extends CanvasLayer

@onready var _ammo_label: Label = $Root/Info/AmmoLabel
@onready var _rejection_label: Label = $Root/Info/RejectionLabel
@onready var _rejection_message_timer: Timer = $RejectionMessageTimer


func _ready() -> void:
	# Conexión de señales de autoload solo en `_ready()`
	# (`docs/ARCHITECTURE.md` §4.2), mismo patrón que `soldado.gd`.
	EconomyManager.ammo_pool_changed.connect(_on_ammo_pool_changed)
	EconomyManager.deploy_or_reload_rejected.connect(_on_deploy_or_reload_rejected)
	_rejection_message_timer.timeout.connect(_on_rejection_message_timer_timeout)

	# Estado inicial mostrado sin esperar el primer cambio: el pool global
	# ya puede tener un valor != 0 si este HUD se instancia después de que
	# el jugador recolectó munición (`ammo_pool_changed` solo se emite ante
	# cambios posteriores, nunca al conectar).
	_update_ammo_label(EconomyManager.collected_ammo)
	_rejection_label.visible = false


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
