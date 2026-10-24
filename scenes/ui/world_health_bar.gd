## Presenta la salud observada; nunca modifica los datos del combatiente.
class_name WorldHealthBar
extends ProgressBar

## Estilos inmutables compartidos por la escena; sólo cambia el override local.
@export var healthy_fill: StyleBoxFlat
@export var wounded_fill: StyleBoxFlat
@export var critical_fill: StyleBoxFlat


func set_health(current: int, maximum: int) -> void:
	if maximum <= 0 or current <= 0:
		clear()
		return
	max_value = float(maximum)
	value = float(clampi(current, 0, maximum))
	var proportion := value / max_value
	var fill := healthy_fill
	if proportion <= 0.25:
		fill = critical_fill
	elif proportion <= 0.5:
		fill = wounded_fill
	add_theme_stylebox_override(&"fill", fill)
	show()


func clear() -> void:
	value = 0.0
	hide()
