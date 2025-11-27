shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float warp_amount : hint_range(0.0, 0.15) = 0.045;
uniform float wobble_speed : hint_range(0.0, 2.0) = 0.45;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.65;
uniform float chroma_amount : hint_range(0.0, 2.0) = 0.65;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.22;
uniform float static_strength : hint_range(0.0, 0.8) = 0.16;
uniform float effect_mix : hint_range(0.0, 1.0) = 0.9;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv * 2.0 - 1.0;
	float barrel = dot(centered, centered);

	vec2 warped_uv = uv + centered * barrel * warp_amount;
	warped_uv.x += sin((uv.y + TIME * wobble_speed) * 6.2831) * warp_amount * 0.3;
	warped_uv.y += sin((uv.x * 1.4 + TIME * (wobble_speed * 0.7)) * 6.2831) * warp_amount * 0.4;

	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	float jitter = noise(vec2(TIME * 0.9, warped_uv.y * resolution.y * 0.25)) - 0.5;
	warped_uv.x += jitter * warp_amount * 0.35;
	warped_uv = clamp(warped_uv, vec2(0.001), vec2(0.999));

	vec4 warped_sample = textureLod(SCREEN_TEXTURE, warped_uv, 0.0);
	vec4 original_sample = textureLod(SCREEN_TEXTURE, uv, 0.0);

	vec2 chroma = chroma_amount * SCREEN_PIXEL_SIZE * 140.0;
	float red = textureLod(SCREEN_TEXTURE, clamp(warped_uv + chroma, vec2(0.0), vec2(1.0)), 0.0).r;
	float blue = textureLod(SCREEN_TEXTURE, clamp(warped_uv - chroma, vec2(0.0), vec2(1.0)), 0.0).b;
	warped_sample.r = mix(warped_sample.r, red, 0.75);
	warped_sample.b = mix(warped_sample.b, blue, 0.75);

	float scan = sin((warped_uv.y * resolution.y) * 3.1415 + TIME * 9.0) * 0.5 + 0.5;
	float scan_mix = mix(1.0, scan, scanline_strength);
	warped_sample.rgb *= scan_mix;

	float vignette = smoothstep(0.2, 1.0, barrel * 1.3);
	warped_sample.rgb *= mix(1.0, 1.0 - vignette, vignette_strength);

	float static_noise = noise(vec2(warped_uv * resolution * 0.4 + TIME * 1.6));
	warped_sample.rgb += (static_noise - 0.5) * static_strength;

	float glow = smoothstep(0.35, 1.0, 1.0 - barrel) * glow_strength;
	warped_sample.rgb += glow * vec3(0.18, 0.28, 0.3);

	vec4 final_color = mix(original_sample, warped_sample, effect_mix);
	COLOR = final_color;
}
