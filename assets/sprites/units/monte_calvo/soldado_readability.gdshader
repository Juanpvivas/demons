shader_type canvas_item;
render_mode unshaded, blend_mix;

// Recursos de estilo compartidos, sin parámetros de daño/moral por actor.
uniform float midtone_lift : hint_range(0.0, 0.25) = 0.10;
uniform float edge_width_texels : hint_range(0.0, 6.0) = 3.0;
uniform vec4 edge_color : source_color = vec4(0.09, 0.08, 0.06, 0.65);

varying vec4 actor_modulate;

void vertex() {
	actor_modulate = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec2 half_texel = TEXTURE_PIXEL_SIZE * 0.5;
	vec2 uv_min = REGION_RECT.xy + half_texel;
	vec2 uv_max = REGION_RECT.xy + abs(REGION_RECT.zw) - half_texel;
	vec2 step_uv = TEXTURE_PIXEL_SIZE * edge_width_texels;
	float left_alpha = texture(TEXTURE, clamp(UV - vec2(step_uv.x, 0.0), uv_min, uv_max)).a;
	float right_alpha = texture(TEXTURE, clamp(UV + vec2(step_uv.x, 0.0), uv_min, uv_max)).a;
	float top_alpha = texture(TEXTURE, clamp(UV - vec2(0.0, step_uv.y), uv_min, uv_max)).a;
	float bottom_alpha = texture(TEXTURE, clamp(UV + vec2(0.0, step_uv.y), uv_min, uv_max)).a;
	float neighbor_alpha = min(min(left_alpha, right_alpha), min(top_alpha, bottom_alpha));
	float inner_edge = clamp(texel.a - neighbor_alpha, 0.0, 1.0);
	vec3 lifted = texel.rgb + midtone_lift * 4.0 * texel.rgb * (vec3(1.0) - texel.rgb);
	vec3 painted = mix(lifted, edge_color.rgb, inner_edge * edge_color.a);
	// No se amplía alfa; el tinte por instancia sigue llegando a toda la figura.
	COLOR = vec4(painted, texel.a) * actor_modulate;
}
