extends Node2D

@export var fog_sprite: Sprite2D
@export var player: Node2D

# Use the same value as your shader's half_angle (in radians)
@export var half_angle: float = 0.6

# World-space cone length (roughly match outer_radius visually)
@export var cone_length: float = 800.0

@export var ray_count: int = 80
@export var step_distance: float = 16.0

# Bounds of your whole level in world space
@export var world_min: Vector2 = Vector2(-2000, -2000)
@export var world_max: Vector2 = Vector2( 2000,  2000)

@export var tex_size: Vector2i = Vector2i(1024, 1024)

# Set this to the same value you use in the flashlight script
@export var use_mouse_aim: bool = true

var fog_image: Image
var fog_texture: ImageTexture


func _ready() -> void:
	# 1) Create an RGBA texture, fully opaque black (full fog)
	fog_image = Image.create(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0, 0, 0, 1)) # black, alpha = 1 (fully foggy)

	fog_texture = ImageTexture.create_from_image(fog_image)
	fog_sprite.texture = fog_texture

	# 2) Align the fog sprite with your world coordinates
	fog_sprite.centered = false
	fog_sprite.position = world_min

	var world_size: Vector2 = world_max - world_min
	fog_sprite.scale = Vector2(
		world_size.x / float(tex_size.x),
		world_size.y / float(tex_size.y)
	)

	fog_sprite.modulate = Color(0, 0, 0, 1)


func _process(delta: float) -> void:
	_reveal_from_flashlight()


func _reveal_from_flashlight() -> void:
	if player == null:
		return

	var origin: Vector2 = player.global_position

	# --- MATCH YOUR FLASHLIGHT AIM LOGIC ---

	var dir_world: Vector2

	if use_mouse_aim:
		# Same idea as: facing_vec = (mouse - player_screen).normalized()
		# but directly in world space
		dir_world = (get_global_mouse_position() - origin).normalized()
	else:
		# Same as your "ahead_world" direction:
		# Vector2.RIGHT.rotated(player.global_rotation)
		dir_world = Vector2.RIGHT.rotated(player.global_rotation).normalized()

	# Direction angle in world space
	var dir_angle: float = atan2(dir_world.y, dir_world.x)

	# Cone angles
	var start_angle: float = dir_angle - half_angle
	var end_angle: float = dir_angle + half_angle

	var world_size: Vector2 = world_max - world_min

	# --- RAYCAST THROUGH THE CONE AND ERASE FOG ---

	for i in range(ray_count):
		var t := float(i) / float(ray_count - 1)
		var a = lerp(start_angle, end_angle, t)
		var ray_dir := Vector2(cos(a), sin(a))

		var dist := 0.0
		while dist < cone_length:
			var p_world := origin + ray_dir * dist

			# World -> [0,1] UV in fog texture space
			var uv := (p_world - world_min) / world_size
			if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
				break

			var x := int(uv.x * float(tex_size.x - 1))
			var y := int(uv.y * float(tex_size.y - 1))

			# Make this pixel transparent forever
			var col := fog_image.get_pixel(x, y)
			if col.a > 0.0:
				fog_image.set_pixel(x, y, Color(0, 0, 0, 0))

			dist += step_distance

	# Push modified image to GPU
	fog_texture.update(fog_image)
