extends GutTest
## 011/T003: estado real de presentación, sin inspección de geometría dibujada.
const BAR_SCENE := preload("res://scenes/ui/WorldHealthBar.tscn")


func _bar() -> WorldHealthBar:
	return add_child_autofree(BAR_SCENE.instantiate()) as WorldHealthBar


func _fill_color(bar: ProgressBar) -> Color:
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	assert_not_null(fill, "El relleno del indicador es un StyleBoxFlat")
	return fill.bg_color if fill != null else Color.TRANSPARENT


func test_current_and_maximum_are_visible_before_and_after_ready(
		health = use_parameters([Vector2i(30, 30), Vector2i(15, 15), Vector2i(7, 28)])) -> void:
	var bar := BAR_SCENE.instantiate() as WorldHealthBar
	bar.set_health(health.x, health.y)
	assert_eq(bar.value, float(health.x), "La vida actual se presenta inmediatamente")
	assert_eq(bar.max_value, float(health.y), "El máximo procede de este combatiente")
	assert_true(bar.visible, "Un combatiente vivo se muestra incluso a vida completa")
	add_child_autofree(bar)
	assert_eq(bar.value, float(health.x), "Entrar al árbol no pierde el estado recibido")
	assert_eq(bar.max_value, float(health.y))
	assert_true(bar.is_visible_in_tree())


func test_damage_changes_the_proportion_without_waiting_for_a_frame() -> void:
	var bar := _bar()
	bar.set_health(20, 20)
	bar.set_health(7, 20)
	assert_eq(bar.value, 7.0)
	assert_eq(bar.max_value, 20.0)
	assert_eq(bar.value / bar.max_value, 0.35)
	assert_true(bar.visible)


func test_exact_half_and_quarter_belong_to_the_lower_color_band() -> void:
	var bar := _bar()
	bar.set_health(100, 100)
	var olive := _fill_color(bar)
	bar.set_health(51, 100)
	assert_eq(_fill_color(bar), olive, "Por encima del 50 % conserva oliva")
	bar.set_health(50, 100)
	var ochre := _fill_color(bar)
	assert_ne(ochre, olive, "El 50 % exacto ya usa ocre")
	bar.set_health(26, 100)
	assert_eq(_fill_color(bar), ochre, "Por encima del 25 % sigue en ocre")
	bar.set_health(25, 100)
	var red := _fill_color(bar)
	assert_ne(red, ochre, "El 25 % exacto ya usa rojo apagado")
	assert_ne(red, olive, "Los tres niveles son distinguibles")
	bar.set_health(1, 100)
	assert_eq(_fill_color(bar), red, "La vida crítica conserva rojo hasta la baja")


func test_two_combatants_keep_their_values_maxima_and_fill_independent() -> void:
	var first := _bar()
	var second := _bar()
	first.set_health(30, 30)
	var first_fill := _fill_color(first)
	second.set_health(5, 20)
	var second_fill := _fill_color(second)
	assert_eq(first.value, 30.0)
	assert_eq(first.max_value, 30.0)
	assert_eq(_fill_color(first), first_fill, "Herir al segundo no recolorea al primero")
	assert_ne(second_fill, first_fill)
	first.set_health(12, 30)
	assert_eq(second.value, 5.0)
	assert_eq(second.max_value, 20.0)
	assert_eq(_fill_color(second), second_fill, "Actualizar el primero no muta el estilo del segundo")


func test_health_above_the_maximum_cannot_overfill_the_bar() -> void:
	var bar := _bar()
	bar.set_health(99, 30)
	assert_eq(bar.value, 30.0)
	assert_eq(bar.max_value, 30.0)
	assert_true(bar.visible)


func test_death_and_invalid_maximum_clear_a_previously_visible_indicator(
		health = use_parameters([Vector2i(0, 30), Vector2i(-4, 30), Vector2i(10, 0), Vector2i(10, -2)])) -> void:
	var bar := _bar()
	# Estado UI previo válido; no depende de que set_health ya esté implementado.
	bar.max_value = 30.0
	bar.value = 9.0
	bar.show()
	bar.set_health(health.x, health.y)
	assert_false(bar.visible, "Sin vida o sin máximo válido no se muestra indicador")
	assert_eq(bar.value, 0.0, "No queda relleno negativo ni del combatiente anterior")


func test_clear_is_idempotent_even_before_ready() -> void:
	var bar := BAR_SCENE.instantiate() as WorldHealthBar
	autofree(bar)
	bar.max_value = 30.0
	bar.value = 9.0
	bar.show()
	bar.clear()
	assert_false(bar.visible)
	assert_eq(bar.value, 0.0)
	bar.clear()
	assert_false(bar.visible)
	assert_eq(bar.value, 0.0)


func test_indicator_has_no_numbers_focus_or_pointer_capture() -> void:
	var bar := _bar()
	assert_false(bar.show_percentage)
	assert_eq(bar.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(bar.focus_mode, Control.FOCUS_NONE)
	assert_eq(bar.fill_mode, ProgressBar.FILL_BEGIN_TO_END)
