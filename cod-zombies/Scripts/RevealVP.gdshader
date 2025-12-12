shader_type canvas_item;
render_mode blend_add;

uniform vec2  player_screen_pos;
uniform vec2  viewport_size;
uniform vec2  facing = vec2(1.0, 0.0);
uniform vec2  world_per_px = vec2(1.0, 1.0); // feed cam.zoom

uniform float inner_radius_w = 5.0;
uniform float outer_radius_w = 10.0;
uniform float half_angle = 0.45;
uniform float cone_softness = 0.25;

uniform float aura_inner_w = 2.0;
uniform float aura_outer_w = 4.0;
uniform float aura_strength = 0.35;

void fragment() {
    vec2 frag_px = UV * viewport_size;

    vec2 v_px = frag_px - player_screen_pos;
    vec2 v_w  = v_px * world_per_px;
    float d_w = length(v_w);

    // Hard cutoff: outside max radius, skip writing entirely
    float max_r_w = max(outer_radius_w, aura_outer_w);
    if (d_w > max_r_w) { discard; }

    // Radial fade (world space)
    float radial = 1.0 - smoothstep(inner_radius_w, outer_radius_w, d_w);

    // Angular fade (use pixel-space dir so facing feels natural)
    float d_px = length(v_px);
    vec2  dir  = (d_px > 0.0) ? v_px / d_px : vec2(1.0, 0.0);
    vec2  f    = normalize(facing);
    if (length(f) < 1e-6) f = vec2(1.0, 0.0);

    float c = clamp(dot(dir, f), -1.0, 1.0);
    float edge_in  = cos(half_angle);
    float edge_out = cos(half_angle * (1.0 + cone_softness));
    float ang = smoothstep(edge_out, edge_in, c);

    float vis_cone = radial * ang;
    float vis_aura = (1.0 - smoothstep(aura_inner_w, aura_outer_w, d_w)) * aura_strength;
    float vis = max(vis_cone, vis_aura);

    // Don’t add tiny values (prevents additive speckle)
    if (vis < 1e-3) { discard; }

    COLOR = vec4(vec3(vis), vis);
}
