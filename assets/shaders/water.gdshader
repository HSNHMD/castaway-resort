shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

uniform float wave_speed : hint_range(0.1, 3.0) = 0.7;
uniform float wave_scale : hint_range(0.5, 20.0) = 5.0;
uniform vec4 color_shallow : source_color = vec4(0.22, 0.82, 0.76, 0.70);
uniform vec4 color_deep    : source_color = vec4(0.02, 0.14, 0.26, 0.88);
uniform float depth_scale  : hint_range(1.0, 120.0) = 16.0;

varying float v_dist;

void vertex() {
	v_dist = clamp(length(VERTEX.xz) / depth_scale, 0.0, 1.0);
}

void fragment() {
	float t  = TIME * wave_speed;
	vec2  uv = UV * wave_scale;

	// three overlapping sine waves at different angles
	float w1 = sin(uv.x          + t        ) * 0.5 + 0.5;
	float w2 = sin(uv.y * 1.3    + t * 0.8  ) * 0.5 + 0.5;
	float w3 = sin((uv.x + uv.y) * 0.7 - t * 0.6) * 0.5 + 0.5;
	float wave = (w1 + w2 + w3) / 3.0;

	// shallow (center) → deep (edge) color gradient
	vec4 col = mix(color_shallow, color_deep, v_dist);

	// brighten crests slightly
	col.rgb += vec3(wave * 0.05);

	ALBEDO = col.rgb;
	ALPHA  = col.a;
	ROUGHNESS = 0.05;
	METALLIC  = 0.05;

	// animated normal for surface ripple
	float nx = sin(uv.x * 2.0 + t       ) * 0.15;
	float nz = sin(uv.y * 2.0 + t * 0.85) * 0.15;
	NORMAL_MAP       = vec3(nx * 0.5 + 0.5, nz * 0.5 + 0.5, 1.0);
	NORMAL_MAP_DEPTH = 0.8;
}
