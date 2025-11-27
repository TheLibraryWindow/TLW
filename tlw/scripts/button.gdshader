shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.0, 0.08, 0.0, 1.0);
uniform float static_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float pulse_speed = 1.0;
uniform float glow_strength = 0.1;
uniform float falloff = 2.2; // controls edge fade radius

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0; // center at (0,0)
    float dist = length(uv);

    // --- static noise ---
    float n = hash(floor(UV * 250.0 + TIME * 1.5));
    vec3 col = base_color.rgb + vec3(n) * static_intensity;

    // --- radial glow dome ---
    float dome = pow(1.0 - smoothstep(0.0, 1.0, dist), falloff);
    float pulse = sin(TIME * pulse_speed * 2.0) * 0.5 + 0.5;
    col += vec3(dome * (0.25 + pulse * glow_strength));

    // --- fade to black beyond circular shape ---
    float edge = smoothstep(0.5, 0.9, dist);
    col *= 1.0 - edge;

    COLOR = vec4(col, 1.0);
}
