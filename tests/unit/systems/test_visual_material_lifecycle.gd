extends GutTest
## T033: semántica del Material compartido e inmutable, independiente del
## shader/arte final. No certifica contraste ni píxeles renderizados.
const Fixtures := preload("res://tests/unit/units/visual_test_fixtures.gd")
const Visual := preload("res://scenes/units/soldado_visual.gd")
const EffectScene := preload("res://scenes/visuals/DeathVisualEffect.tscn")


func _style() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float fixture_value = 0.65; void fragment() { COLOR.rgb *= fixture_value; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("fixture_value", 0.65)
	return material


func _visual(style: Material) -> SoldadoVisual:
	var visual := Visual.new()
	visual.sprite_frames = Fixtures.frames()
	visual.scale = Vector2(0.5, 0.5)
	visual.offset = Vector2(0, -3)
	visual.material = style
	add_child_autofree(visual)
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	return visual


func _snapshot(style: Material) -> Dictionary:
	var snapshot := Fixtures.snapshot()
	snapshot["visual_material"] = style
	return snapshot


func test_snapshot_keeps_authored_style_and_neutral_transform_during_hit_and_morale() -> void:
	var style := _style()
	var visual := _visual(style)
	visual.play_confirmed_hit()
	visual.play_confirmed_morale()
	await wait_seconds(0.04)
	assert_ne(visual.modulate, Color.WHITE, "Control: impacto transitorio activo")
	assert_gt(visual.scale.x, 0.5, "Control: pulso transitorio activo")
	var snapshot := visual.capture_defeat_snapshot(Vector2(320, 240))
	assert_has(snapshot, "visual_material", "Material nullable es parte del snapshot")
	assert_same(snapshot.get("visual_material"), style, "Misma referencia de estilo autorado inmutable")
	assert_eq(snapshot.size(), 9, "Sin campos de tinte/progreso/gameplay")
	assert_eq(snapshot["visual_scale"], Vector2(0.5, 0.5))
	assert_eq(snapshot["visual_offset"], Vector2(0, -3))
	assert_almost_eq(style.get_shader_parameter("fixture_value"), 0.65, 0.0001)
	for value in snapshot.values():
		assert_false(value is Node or value is Callable)
	var next := visual.capture_defeat_snapshot(Vector2(640, 480))
	snapshot["visual_material"] = null
	assert_same(next.get("visual_material"), style, "Diccionarios independientes, recurso compartido")


func test_presenter_reset_and_deactivate_restore_authored_material_instead_of_previous_style() -> void:
	var authored := _style()
	var visual := _visual(authored)
	var foreign := CanvasItemMaterial.new()
	visual.material = foreign
	assert_same(visual.capture_defeat_snapshot(Vector2.ZERO).get("visual_material"), authored)
	visual.deactivate_visual()
	assert_same(visual.material, authored, "Inactividad restaura estilo autorado")
	visual.material = foreign
	visual.reset_visual(Soldado.SoldierMode.MELEE)
	assert_same(visual.material, authored, "Reaparición no hereda otro estilo")
	assert_eq(visual.modulate, Color.WHITE)
	assert_eq(visual.scale, Vector2(0.5, 0.5))


func test_nullable_authored_material_is_explicit_and_restores_to_null() -> void:
	var visual := _visual(null)
	var snapshot := visual.capture_defeat_snapshot(Vector2.ZERO)
	assert_has(snapshot, "visual_material")
	assert_null(snapshot.get("visual_material"))
	visual.material = _style()
	visual.reset_visual(Soldado.SoldierMode.RIFLE)
	assert_null(visual.material, "Una escena sin material no hereda estilo anterior")


func test_two_presenters_share_only_immutable_style_not_hit_or_morale_state() -> void:
	var style := _style()
	var first := _visual(style)
	var second := _visual(style)
	first.play_confirmed_hit()
	first.play_confirmed_morale()
	await wait_seconds(0.04)
	assert_eq(second.modulate, Color.WHITE)
	assert_eq(second.scale, Vector2(0.5, 0.5))
	assert_same(first.material, second.material)
	assert_almost_eq(style.get_shader_parameter("fixture_value"), 0.65, 0.0001, "Feedback no muta uniforms compartidos")
	assert_same(first.capture_defeat_snapshot(Vector2.ZERO).get("visual_material"), style)
	assert_same(second.capture_defeat_snapshot(Vector2.ONE).get("visual_material"), style)


func test_real_soldier_defeat_captures_material_before_immediate_retirement() -> void:
	var style := _style()
	var soldier: Soldado = load("res://scenes/units/Soldado.tscn").instantiate()
	var visual: AnimatedSprite2D = soldier.get_node("AnimatedSprite2D")
	visual.sprite_frames = Fixtures.frames()
	visual.material = style
	add_child_autofree(soldier)
	var snapshots: Array = []
	soldier.defeat_visual_requested.connect(func(snapshot: Dictionary): snapshots.append(snapshot))
	soldier.take_damage(soldier.stats.max_health)
	assert_eq(snapshots.size(), 1)
	assert_true(soldier.is_queued_for_deletion(), "El material no retrasa la muerte")
	if not snapshots.is_empty():
		assert_same(snapshots[0].get("visual_material"), style)
	assert_almost_eq(style.get_shader_parameter("fixture_value"), 0.65, 0.0001)


func test_effect_applies_style_reference_then_clears_it_for_nullable_snapshot() -> void:
	var style := _style()
	var effect: DeathVisualEffect = add_child_autofree(EffectScene.instantiate())
	effect.on_pool_acquired()
	effect.play_snapshot(_snapshot(style))
	var sprite: AnimatedSprite2D = effect.get_node("AnimatedSprite2D")
	assert_same(sprite.material, style, "Caída conserva el estilo capturado")
	effect.play_snapshot(_snapshot(null))
	assert_null(sprite.material, "Snapshot null borra material del uso previo")
	assert_eq(sprite.modulate, Color.WHITE)


func test_release_and_acquire_clear_material_even_before_first_ready() -> void:
	var effect: DeathVisualEffect = autofree(EffectScene.instantiate())
	var sprite: AnimatedSprite2D = effect.get_node("AnimatedSprite2D")
	sprite.material = _style()
	effect.on_pool_released()
	assert_null(sprite.material, "Release pre-ready elimina material residual")
	sprite.material = _style()
	effect.on_pool_acquired()
	assert_null(sprite.material, "Acquire pre-ready elimina material residual")


func test_ten_pool_reuses_alternate_material_and_null_and_ignore_stale_callbacks() -> void:
	var style := _style()
	var pool := ObjectPool.new(EffectScene, 1)
	add_child_autofree(pool)
	var first_instance: DeathVisualEffect = null
	for cycle in 10:
		var effect := pool.acquire() as DeathVisualEffect
		if first_instance == null:
			first_instance = effect
		assert_same(effect, first_instance)
		effect.play_snapshot(_snapshot(style))
		var sprite: AnimatedSprite2D = effect.get_node("AnimatedSprite2D")
		assert_same(sprite.material, style, "Uso con estilo " + str(cycle))
		var old_activation := effect.get_activation_id()
		sprite.modulate = Color.RED
		pool.release(effect)
		assert_null(sprite.material, "Release limpia referencia " + str(cycle))
		var reused := pool.acquire() as DeathVisualEffect
		reused.play_snapshot(_snapshot(null))
		watch_signals(reused)
		reused.complete_activation(old_activation)
		assert_same(reused, first_instance)
		assert_null(sprite.material)
		assert_eq(sprite.modulate, Color.WHITE)
		assert_true(reused.visible)
		assert_signal_not_emitted(reused, "finished", "Callback anterior no completa activación actual")
		assert_eq(pool.in_use_count(), 1)
		assert_almost_eq(style.get_shader_parameter("fixture_value"), 0.65, 0.0001)
		pool.release(reused)
