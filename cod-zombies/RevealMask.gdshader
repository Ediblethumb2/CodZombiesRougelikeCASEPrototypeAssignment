shader_type canvas_item;
render_mode blend_add; // add onto what was drawn last frame (accumulates)

uniform vec2 player_screen_pos;   // in RevealMaskVP pixels
uniform vec2 viewport_size;       // RevealMaskVP size in pixels
uniform vec2 facing = vec2(1.0, 0.0); // normalized direction in screen space

uniform float inner_radius = 10.0;   // full bright inside
uniform float outer_radius = 50.0;   // fades to 0 by here
uniform float half_angle   = 0.45;    // radians (~26°)
uniform float cone_softness = 0.25;   // 0..1 soft edge

uniform float aura_inner = 60.0;      // always-on aura near player
uniform float aura_outer = 120.0;
uniform float aura_strength = 0.35;   // 0..1

void fragment() {
    vec2 frag_px = UV * viewport_size;
    vec2 v = frag_px - player_screen_pos;
    float d = length(v);

    // radial falloff 1..0 from inner->outer
    float radial = smoothstep(outer_radius, inner_radius, d);

    // angular falloff around "facing" vector
    vec2 fn = normalize(facing);
    float cosang = dot(normalize(v), fn);
    cosang = clamp(cosang, -1.0, 1.0);
    float ang = acos(cosang);
    float soft = mix(0.0, half_angle * cone_softness, 1.0);
    float ang_term = smoothstep(half_angle + soft, half_angle - soft, ang);

    float cone = radial * ang_term;

    // local aura that’s not directional
    float aura = aura_strength * smoothstep(aura_outer, aura_inner, d);

    float brightness = clamp(cone + aura, 0.0, 1.0);

    // write white where revealed (accumulates with blend_add)
    COLOR = vec4(vec3(brightness), brightness);
}
