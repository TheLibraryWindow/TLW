shader_type canvas_item;

uniform float density        : hint_range(0.5, 6.0) = 3.0; // stars per 100x100 area
uniform float twinkle_speed  : hint_range(0.1, 6.0) = 1.8;
uniform float glow           : hint_range(0.5, 3.0)  = 1.4;
uniform float brightness     : hint_range(0.0, 2.0)  = 1.2;
uniform vec2  parallax       = vec2(0.0, 0.0);
uniform float seed           = 12.345;
uniform vec3  star_color     : source_color = vec3(0.3, 1.0, 0.6); // green tint
uniform vec2  screen_size    = vec2(1280.0, 720.0); // will auto-update from code

float hash12(vec2 p){
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p){
	float n = sin(dot(p, vec2(127.1, 311.7))) * 43758.5453;
	return fract(vec2(n, n*1.2154));
}

void fragment() {
	// use UV directly scaled by uniform screen_size
	vec2 screen_px = UV * screen_size + parallax;

	float cell = 110.0 / density;
	vec2 cell_id = floor((screen_px + seed) / cell);
	vec2 rnd2 = hash22(cell_id + seed);
	vec2 star_pos = (cell_id + rnd2) * cell;

	float d = distance(screen_px, star_pos);
	float r = mix(0.6, 1.8, rnd2.x);

	float phase = rnd2.y * 6.28318;
	float rate  = mix(0.7, 1.3, hash12(cell_id + 99.0));
	float tw = 0.5 + 0.5 * sin(TIME * twinkle_speed * rate + phase);

	float core  = smoothstep(r, 0.0, d);
	float halo  = smoothstep(r*glow, r, d);
	float star  = core * 0.7 + halo * 0.3;

	float spawn = step(0.65, hash12(cell_id + 7.0));
	float alpha = brightness * tw * star * spawn;

	COLOR = vec4(star_color, alpha);
}
