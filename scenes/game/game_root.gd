## Composición de la sesión: el menú no monta una partida en segundo plano.
extends Node

@export var level_scene: PackedScene = preload("res://scenes/levels/Nivel_MonteCalvo.tscn")
@export var intro_scene: PackedScene = preload("res://scenes/ui/IntroPlayer.tscn")
@export var intro_sequence: Resource = preload("res://resources/narrative/la_carta.tres")

var intro_progress: RefCounted

var _current_level: Node
var _transition_pending: bool = false
var _generation: int = 0
var _retry_callback: Callable
var _menu_callback: Callable
var _current_intro: Control
var _intro_from_start: bool = false
var _intro_waiting_start: bool = false
var _intro_completed: bool = false
var _intro_finished_callback: Callable
var _intro_start_callback: Callable

@onready var _menu = $MenuLayer/MainMenu


func _ready() -> void:
	GameStateManager.enter_menu()
	if intro_progress == null:
		intro_progress = IntroProgress.new()
	_menu.play_requested.connect(request_start)
	_menu.intro_requested.connect(request_intro)


func request_start() -> void:
	if _transition_pending or is_instance_valid(_current_level) or is_instance_valid(_current_intro) \
			or GameStateManager._current_state != GameStateManager.GameState.MENU:
		return
	_transition_pending = true
	_menu.set_start_enabled(false)
	# El gesto y su ráfaga terminan sobre la UI, antes de montar el tablero.
	if intro_progress.has_seen(intro_sequence.version):
		_start_match.call_deferred()
	else:
		_open_intro.call_deferred(true)


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


func request_intro() -> void:
	if _transition_pending or is_instance_valid(_current_level) or is_instance_valid(_current_intro) \
			or GameStateManager._current_state != GameStateManager.GameState.MENU:
		return
	_transition_pending = true
	_menu.set_start_enabled(false)
	_open_intro.call_deferred(false)


func request_intro_start() -> void:
	if _transition_pending or not _intro_waiting_start or not is_instance_valid(_current_intro):
		return
	_transition_pending = true
	_intro_waiting_start = false
	_retire_intro.call_deferred(true)


func get_current_intro() -> Node:
	return _current_intro if is_instance_valid(_current_intro) else null


func _open_intro(from_start: bool) -> void:
	if is_queued_for_deletion():
		return
	_generation += 1
	_intro_from_start = from_start
	_intro_waiting_start = false
	_intro_completed = false
	_current_intro = intro_scene.instantiate() as Control
	_intro_finished_callback = _on_intro_finished.bind(_generation)
	_intro_start_callback = _on_intro_start_requested.bind(_generation)
	_current_intro.connect("finished", _intro_finished_callback)
	_current_intro.connect("start_requested", _intro_start_callback)
	$MenuLayer.add_child(_current_intro)
	_menu.hide()
	_transition_pending = false
	_current_intro.play(intro_sequence)


func _on_intro_finished(_skipped: bool, generation: int) -> void:
	if generation != _generation or _intro_completed or not is_instance_valid(_current_intro):
		return
	# Guard previo a persistir o emitir otras intenciones síncronas.
	_intro_completed = true
	var save_error: Error = intro_progress.mark_seen(intro_sequence.version)
	if save_error != OK:
		push_warning("La carta no pudo recordarse en este dispositivo; se puede seguir jugando.")
	if _intro_from_start:
		_intro_waiting_start = true
		_show_intro_start.call_deferred(generation)
	else:
		_transition_pending = true
		_retire_intro.call_deferred(false)


func _show_intro_start(generation: int) -> void:
	if generation == _generation and _intro_waiting_start and is_instance_valid(_current_intro):
		_current_intro.show_start_prompt()


func _on_intro_start_requested(generation: int) -> void:
	if generation == _generation:
		request_intro_start()


func _retire_intro(start_match: bool) -> void:
	if not is_instance_valid(_current_intro):
		return
	_generation += 1
	var previous := _current_intro
	previous.close_intro()
	previous.disconnect("finished", _intro_finished_callback)
	previous.disconnect("start_requested", _intro_start_callback)
	_current_intro = null
	previous.get_parent().remove_child(previous)
	previous.queue_free()
	if start_match:
		_start_match()
	else:
		_menu.show_menu()
		_transition_pending = false
