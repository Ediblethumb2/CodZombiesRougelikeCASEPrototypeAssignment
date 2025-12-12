extends ColorRect

@export var player_path: NodePath
@export var cam_path: NodePath  # assign your active Camera2D here in the inspector
@export var use_mouse_aim := true

@onready var player: Node2D = get_node(player_path)
@onready var cam: Camera2D = get_node(cam_path)
@onready var mat: ShaderMaterial = material

func _ready() -> void:
	# Fullscreen overlay
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	if cam == null or player == null: 
		return

	var vp_size: Vector2 = get_viewport_rect().size
	mat.set_shader_parameter("viewport_size", vp_size)
	mat.set_shader_parameter("world_per_px", cam.zoom)  # CRUCIAL for world-space radii
	print(cam.zoom)

	var player_px := _world_to_screen_px(player.global_position, cam, vp_size)
	mat.set_shader_parameter("player_screen_pos", player_px)

	var facing_vec: Vector2
	if use_mouse_aim:
		var mouse_px := get_viewport().get_mouse_position()
		facing_vec = (mouse_px - player_px).normalized()
	else:
		# "Ahead" in world → pixels
		var ahead_world := player.global_position + Vector2.RIGHT.rotated(player.global_rotation)
		var ahead_px := _world_to_screen_px(ahead_world, cam, vp_size)
		facing_vec = (ahead_px - player_px).normalized()

	if facing_vec.is_zero_approx():
		facing_vec = Vector2.RIGHT
	mat.set_shader_parameter("facing", facing_vec)

func _world_to_screen_px(world: Vector2, camera: Camera2D, vp_size: Vector2) -> Vector2:
	# Map world → viewport pixels using camera center, rotation, zoom
	var center_w := camera.get_screen_center_position()    # world pos at screen center
	var right := Vector2.RIGHT.rotated(camera.rotation)
	var down  := Vector2.DOWN.rotated(camera.rotation)
	var rel := world - center_w
	var x_px := rel.dot(right) / camera.zoom.x + vp_size.x * 0.5
	var y_px := rel.dot(down)  / camera.zoom.y + vp_size.y * 0.5
	return Vector2(x_px, y_px)
