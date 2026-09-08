shader_type canvas_item;

uniform vec2 scroll_speed = vec2(0.05, 0.02);

void fragment() {
    vec2 uv = UV + scroll_speed * TIME;
    vec4 tex_color = texture(TEXTURE, uv);
    COLOR = vec4(tex_color.rgb, tex_color.a * 0.5);
}