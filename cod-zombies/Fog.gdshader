shader_type canvas_item;

uniform vec2 player_screen_pos;           // pixels (feed each frame)
uniform vec2 viewport_size;               // pixels
uniform vec2 facing = vec2(1.0, 0.0);     // normalized screen-space aim

// Cone (flashlight) params
uniform float inner_radius = 280.0;       // bright center distance
uniform float outer_radius = 600.0;       // fully dark beyond this
uniform float half_angle = 0.6;          // radians (~26°)
uniform float cone_softness = 0.25;       // 0..1, softens cone edges

// Global ambient (tiny baseline visibility everywhere)
instance uniform float ambient = 0.0;              // 0..1

// --- New: local aura around player ---
uniform float aura_inner = 60.0;          // fully visible within this radius
uniform float aura_outer = 120.0;         // fades to dark by this radius
uniform float aura_strength = 0.35;       // 0..1 peak brightness of aura

void fragment() {
    vec2 frag_px = SCREEN_UV * viewport_size;
    vec2 v = frag_px - player_screen_pos;
    float d = length(v) + 1e-5;

    // Radial falloff for the cone's reach
    float radial = smoothstep(outer_radius, inner_radius, d);

    // Angular falloff for the cone
    vec2 dir = v / d;
    float a = acos(clamp(dot(dir, normalize(facing)), -1.0, 1.0));
    float ang = smoothstep(half_angle * (1.0 + cone_softness), half_angle, a);

    float vis_cone = radial * ang;

    // Aura: round glow near the player, independent of aim
    float vis_aura = smoothstep(aura_outer, aura_inner, d) * aura_strength;

    // Final visibility = max of ambient, cone, and aura
    float vis = max(ambient, max(vis_cone, vis_aura));
    float alpha = 1.0 - clamp(vis, 0.0, 1.0);

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
