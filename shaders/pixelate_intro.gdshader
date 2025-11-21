shader_type canvas_item;

uniform float pixelate_amount : hint_range(1.0, 128.0) = 16.0;

void fragment() {
	vec2 grid = floor(UV * pixelate_amount) / pixelate_amount;
	COLOR = texture(TEXTURE, grid) * COLOR;
}
