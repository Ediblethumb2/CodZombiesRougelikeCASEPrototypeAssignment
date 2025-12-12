extends ColorRect

@export var player_path: NodePath
@export var use_mouse_aim := true

@onready var player: Node2D = get_node(player_path)
@onready var mat: ShaderMaterial = material

func _ready():
		# Fill the entire viewport
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	# Let clicks pass through to the game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_dt):
	var cam := get_viewport().get_camera_2d()
	if cam == null: return

	# Player world → screen (to feed the shader)
	var player_screen = player.get_global_transform_with_canvas().origin
	
	
	material.set_shader_parameter("player_screen_pos", player_screen)
	material.set_shader_parameter("viewport_size", get_viewport_rect().size)
	
	# Facing vector in *screen* space
	var facing_vec: Vector2
	if use_mouse_aim:
		facing_vec = (get_viewport().get_mouse_position() - player_screen).normalized()
	else:
		# Build a point "ahead" of the player in world, then convert to screen
		var ahead_world := player.global_position + Vector2.RIGHT.rotated(player.global_rotation)
		var ahead_screen = cam.world_to_screen(ahead_world)
		facing_vec = (ahead_screen - player_screen).normalized()

	material.set_shader_parameter("facing", facing_vec)
