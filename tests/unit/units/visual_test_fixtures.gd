extends RefCounted
## Arte sintético: prueba semántica de presentación, no certifica estética.

static func frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	var texture := GradientTexture2D.new()
	texture.width = 48
	texture.height = 48
	for entry: Array in [[&"rifle_idle", 1.0, true], [&"rifle_shot", 25.0, false], [&"melee_idle", 1.0, true], [&"melee_attack", 16.666667, false], [&"defeat", 10.0, false]]:
		result.add_animation(entry[0])
		result.set_animation_speed(entry[0], entry[1])
		result.set_animation_loop(entry[0], entry[2])
		for index in 4:
			result.add_frame(entry[0], texture)
	# 005/T048: datos sintéticos, sin implementar la transición observadora.
	for pose: StringName in [&"melee_march", &"returning", &"returning_idle"]:
		result.add_animation(pose)
		result.set_animation_speed(pose, 8.0)
		result.set_animation_loop(pose, true)
		for index in 4:
			result.add_frame(pose, texture)
	return result

static func snapshot(position := Vector2(320, 240)) -> Dictionary:
	# T033 añade el material nullable al contrato; no cambia el arte sintético.
	return {"world_position":position, "sprite_frames":frames(), "defeat_animation":&"defeat", "visual_scale":Vector2.ONE, "visual_offset":Vector2(0, -2), "flip_h":false, "flip_v":false, "visual_z":2, "visual_material":null}
