shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D reveal_texture;
uniform float fog_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float ambient_reveal : hint_range(0.0, 1.0) = 0.0;

void fragment() {
        vec2 uv = SCREEN_UV;
        float reveal = 0.0;
        if (reveal_texture != NULL_TEXTURE) {
                reveal = texture(reveal_texture, uv).a;
        }
        reveal = clamp(max(reveal, ambient_reveal), 0.0, 1.0);
        float fog = (1.0 - reveal) * fog_alpha;
        COLOR = vec4(vec3(0.0), fog);
}
