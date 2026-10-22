## Composición de la sesión: el menú no monta una partida en segundo plano.
extends Node

@export var level_scene: PackedScene = preload("res://scenes/levels/Nivel_MonteCalvo.tscn")

var _current_level: Node
var _transition_pending: bool = false

@onready var _menu = $MenuLayer/MainMenu


func _ready() -> void:
	GameStateManager.enter_menu()
	_menu.play_requested.connect(request_start)


func request_start() -> void:
	if _transition_pending or is_instance_valid(_current_level) \
			or GameStateManager._current_state != GameStateManager.GameState.MENU:
		return
	_transition_pending = true
	_menu.set_start_enabled(false)
	# El gesto y su ráfaga terminan sobre la UI, antes de montar el tablero.
	_start_match.call_deferred()


func _start_match() -> void:
	if is_queued_for_deletion():
		return
	_current_level = level_scene.instantiate()
	add_child(_current_level)
	_menu.hide()
	_transition_pending = false


func request_retry() -> void:
	pass


func request_menu() -> void:
	pass


func get_current_level() -> Node:
	return _current_level if is_instance_valid(_current_level) else null
