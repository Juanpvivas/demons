## Interfaz de navegación de 007; las transiciones se implementan tras RED.
extends Node

@export var level_scene: PackedScene = preload("res://scenes/levels/Nivel_MonteCalvo.tscn")


func request_start() -> void:
	pass


func request_retry() -> void:
	pass


func request_menu() -> void:
	pass


func get_current_level() -> Node:
	return null
