extends ColorRect

# --- sizes in WORLD units (or tiles * tile_px) ---
@export var reveal_inner_world := 96.0
@export var reveal_outer_world := 160.0
@export var aura_inner_world   := 24.0
@export var aura_outer_world   := 48.0
@export var use_tiles := true
@export var tile_px   := 64.0

@export var use_mouse_aim := true
@export var persist_exploration := true   # <-- set true if you want “revealed stays” forever

@export var player_path: NodePath
@export var minimap_vp_path: NodePath      # <-- the SubViewport your MINIMAP camera renders into

@onready var player: Node2D        = get_node(player_path)
@onready var minimap_vp: SubViewport = get_node(minimap_vp_path)
@onready var mat: ShaderMaterial   = material

func _ready() -> void:
	# fill
	anchor_left = 0.0; anchor_top = 0.0; anchor_right = 1.0; anchor_bottom = 1.0
	offset_left = 0.0; offset_top = 0.0; offset_right = 0.0; offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# mask viewport = the viewport this ColorRect lives in
	var mask_vp := get_viewport() as SubViewport
	mask_vp.transparent_bg = true
	mask_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	if persist_exploration:
		# accumulate forever (revealed stays)
		mask_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		await get_tree().physics_frame
		mask_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	else:
		# no persistence: clear every frame so nothing lingers
		mask_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

func _process(_dt: float) -> void:
        var mask_vp := get_viewport() as SubViewport
        if mask_vp and mask_vp.size != minimap_vp.size:
                mask_vp.size = minimap_vp.size

        _update_fog_scale()  # scales with minimap zoom

        # Convert world -> MINIMAP pixels (uses the MINIMAP viewport’s canvas transform!)
        var to_minimap: Transform2D = minimap_vp.get_canvas_transform()

	var player_px: Vector2 = to_minimap * player.global_position

	var facing_vec := Vector2.RIGHT
	if use_mouse_aim:
		var main_vp := player.get_viewport()
		var mouse_world := main_vp.get_canvas_transform().affine_inverse() * main_vp.get_mouse_position()
		var dir_world := (mouse_world - player.global_position).normalized()
		facing_vec = to_minimap.basis_xform(dir_world).normalized()
	else:
		var dir_world := Vector2.RIGHT.rotated(player.global_rotation)
		facing_vec = to_minimap.basis_xform(dir_world).normalized()
	if not facing_vec.is_finite() or facing_vec.length_squared() < 1e-6:
		facing_vec = Vector2.RIGHT

	mat.set_shader_parameter("player_screen_pos", player_px)
	mat.set_shader_parameter("viewport_size", Vector2(get_viewport().size))
	mat.set_shader_parameter("facing", facing_vec)

func _update_fog_scale() -> void:
	# IMPORTANT: use the MINIMAP viewport (with the minimap Camera2D) — not the mask viewport.
	var T: Transform2D = minimap_vp.get_canvas_transform()

	# pixels-per-world-unit (accounts for minimap camera zoom)
	var px_per_world := 0.5 * (T.x.length() + T.y.length())

	var riw := reveal_inner_world
	var row := reveal_outer_world
	var aiw := aura_inner_world
	var aow := aura_outer_world
	if use_tiles:
		riw *= tile_px; row *= tile_px; aiw *= tile_px; aow *= tile_px

	mat.set_shader_parameter("inner_radius", riw * px_per_world)
	mat.set_shader_parameter("outer_radius", row * px_per_world)
	mat.set_shader_parameter("aura_inner",  aiw * px_per_world)
	mat.set_shader_parameter("aura_outer",  aow * px_per_world)
