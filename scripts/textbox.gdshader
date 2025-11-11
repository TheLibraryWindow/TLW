shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.0, 0.12, 0.0, 1.0);
uniform float static_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float scan_speed = 0.5;
uniform float metallic_highlight = 0.25;
uniform float depth_shade = 0.3;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;

    // --- CRT static base ---
    float n = hash(floor(uv * 300.0 + TIME * 0.7));
    vec3 col = base_color.rgb + vec3(n) * static_intensity;

    // --- Subtle horizontal scan shimmer (like signal noise) ---
    float scan = sin((uv.y + TIME * scan_speed) * 500.0) * 0.05;
    col += vec3(scan * 0.5, scan * 0.8, scan * 0.3);

    // --- Bevel depth: edges darker, centre brighter ---
    vec2 edge_dist = abs(uv - 0.5);
    float shade = smoothstep(0.3, 0.0, max(edge_dist.x, edge_dist.y));
    col += vec3(shade * metallic_highlight);
    col -= vec3((1.0 - shade) * depth_shade);

    // --- Fade to black at extreme edges ---
    float edge_fade = smoothstep(0.45, 0.5, max(edge_dist.x, edge_dist.y));
    col *= (1.0 - edge_fade);

    COLOR = vec4(col, 1.0);
}
