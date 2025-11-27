shader_type canvas_item;

uniform float reveal : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    float tex_w = float(textureSize(TEXTURE, 0).x);
    float step = floor(reveal * tex_w) / tex_w;
    if (UV.x <= step) {
        COLOR = texture(TEXTURE, UV) * COLOR;
    } else {
        discard;
    }
}