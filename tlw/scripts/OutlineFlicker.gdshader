shader_type canvas_item;

uniform float flicker_speed = 0.8;      // overall tempo
uniform float flicker_strength = 0.03;  // brightness range
uniform float grain_scale = 60.0;       // density of the noise pattern
uniform float grain_speed = 0.8;        // how fast it shifts

// Simple random generator
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    // Sample base texture
    vec4 tex_color = texture(TEXTURE, UV);

    // Grainy random flicker pattern that moves slowly
    float noise = rand(UV * grain_scale + TIME * grain_speed);
    float flicker = (noise - 0.5) * 2.0 * flicker_strength; // centered ±strength

    // Apply grain shimmer to brightness
    tex_color.rgb *= 1.0 + flicker;

    // Respect modulate / fade animations
    COLOR = tex_color * COLOR;
}
