shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

const int MAX_WAVES = 3;

uniform int wave_count = 0;
uniform vec2 wave_centers[MAX_WAVES];
uniform float wave_angles[MAX_WAVES];
uniform float wave_amplitudes[MAX_WAVES];
uniform float wave_radius[MAX_WAVES];
uniform float wave_pinch[MAX_WAVES];
uniform float wave_aspect[MAX_WAVES];
uniform float wave_progress[MAX_WAVES];
uniform float wave_dispersion[MAX_WAVES];
uniform float global_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float edge_safety : hint_range(0.0, 0.1) = 0.01;
uniform float chroma_shift : hint_range(0.0, 1.0) = 0.18;

vec2 rotate(vec2 v, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

float envelope(float distance, float travel, float spread, float radius) {
	float band = abs(distance - travel);
	float gaussian = exp(-band * spread);
	float dome = smoothstep(radius, 0.0, distance);
	return gaussian * dome;
}

vec4 sample_screen(vec2 uv) {
	return texture(SCREEN_TEXTURE, uv);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 warped = uv;

	for (int i = 0; i < MAX_WAVES; i++) {
		if (i >= wave_count) {
			break;
		}

		float progress = clamp(wave_progress[i], 0.0, 1.0);
		if (progress <= 0.0001) {
			continue;
		}

		vec2 center = wave_centers[i];
		float radius = max(0.001, wave_radius[i]);
		float angle = wave_angles[i];
		float aspect = max(0.1, wave_aspect[i]);
		float spread = max(0.5, wave_dispersion[i]);

		vec2 dir = vec2(cos(angle), sin(angle));
		vec2 ortho = vec2(-dir.y, dir.x);

		vec2 rel = warped - center;
		float along = dot(rel, dir);
		float across = dot(rel, ortho) * aspect;

		float radial = length(vec2(along, across));
		float travel = progress * radius;

		float env = envelope(radial, travel, spread, radius);
		if (env <= 0.0001) {
			continue;
		}

		float wave = sin((along - travel) * spread * 5.0) * wave_amplitudes[i];

		vec2 offset = dir * wave;
		vec2 pinch_dir = normalize(rel + dir * 0.0001);
		float pinch = wave_pinch[i] * smoothstep(radius, 0.0, radial);

		offset += pinch_dir * pinch;

		warped += offset * env * global_intensity;
	}

	vec2 safe_uv = clamp(warped, vec2(-edge_safety), vec2(1.0 + edge_safety));
	vec4 base = sample_screen(safe_uv);

	if (chroma_shift > 0.0) {
		vec2 diff = warped - uv;
		vec2 shift = diff * chroma_shift * 0.5;
		float r = sample_screen(safe_uv + shift).r;
		float g = base.g;
		float b = sample_screen(safe_uv - shift).b;
		base.rgb = vec3(r, g, b);
	}

	COLOR = base;
}
