## Composición de la sesión: el menú no monta una partida en segundo plano.
extends Node

@export var level_scene: PackedScene = preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
@export var intro_scene: PackedScene
@export var intro_sequence: Resource

var intro_progress: RefCounted

var _current_level: Node
var _transition_pending: bool = false
var _generation: int = 0
var _retry_callback: Callable
var _menu_callback: Callable

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
	_generation += 1
	_current_level = level_scene.instantiate()
	_retry_callback = _on_level_retry_requested.bind(_generation)
	_menu_callback = _on_level_menu_requested.bind(_generation)
	_current_level.connect("retry_requested", _retry_callback)
	_current_level.connect("menu_requested", _menu_callback)
	add_child(_current_level)
	_menu.hide()
	_transition_pending = false


func request_retry() -> void:
	_request_terminal_destination(true)


func request_menu() -> void:
	_request_terminal_destination(false)


func _request_terminal_destination(restart: bool) -> void:
	if _transition_pending or not is_instance_valid(_current_level) \
			or GameStateManager._current_state not in [
				GameStateManager.GameState.WON, GameStateManager.GameState.LOST]:
		return
	_transition_pending = true
	_generation += 1
	var previous := _current_level
	previous.disconnect("retry_requested", _retry_callback)
	previous.disconnect("menu_requested", _menu_callback)
	GameStateManager.enter_menu()
	WaveManager.cancel_waves()
	previous.close_match()
	_finish_attempt.call_deferred(previous, restart)


func _finish_attempt(previous: Node, restart: bool) -> void:
	# La UI sigue consumiendo la ráfaga hasta terminar el dispatch del botón.
	remove_child(previous)
	previous.queue_free()
	_current_level = null
	var tree := get_tree()
	# Espera una condición observable: ningún objeto del intento sigue vivo.
	while is_instance_valid(previous):
		await tree.process_frame
		if not is_instance_valid(self):
			return
	if is_queued_for_deletion() or not is_inside_tree():
		return
	if restart:
		_start_match()
	else:
		_menu.show_menu()
		_transition_pending = false


func _on_level_retry_requested(generation: int) -> void:
	if generation == _generation:
		request_retry()


func _on_level_menu_requested(generation: int) -> void:
	if generation == _generation:
		request_menu()


func get_current_level() -> Node:
	return _current_level if is_instance_valid(_current_level) else null


## Firmas neutrales de 013: todavía no alteran la entrada vigente.
func request_intro() -> void:
	pass


func request_intro_start() -> void:
	pass


func get_current_intro() -> Node:
	return null
