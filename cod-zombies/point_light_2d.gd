extends PointLight2D

@export var tex_size: int = 256
@export var half_angle_degrees: float = 35.0
@export var max_radius_factor: float = 0.9

func _ready() -> void:
	# IMPORTANT: this must be INSIDE a function, not at top level
	self.texture = _make_cone_texture()
	self.offset = Vector2.ZERO    # light centered on its texture


func _make_cone_texture() -> Texture2D:
	var size := tex_size
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)


	var center := Vector2(size * 0.5, size * 0.5)
	var max_r := (size * 0.5) * max_radius_factor
	var half_angle := deg_to_rad(half_angle_degrees)

	for y in range(size):
		for x in range(size):
			var p := Vector2(x, y)
			var v := p - center
			var r := v.length()

			if r > max_r:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			if r == 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
				continue

			var angle := atan2(v.y, v.x)
			var a = abs(angle)

			if a > half_angle:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			var radial := 1.0 - (r / max_r)
			radial = clamp(radial, 0.0, 1.0)

			var angular = 1.0 - (a / half_angle)
			angular = clamp(angular, 0.0, 1.0)

			var intensity = radial * angular
			intensity = pow(intensity, 0.7)

			img.set_pixel(x, y, Color(1, 1, 1, intensity))

	return ImageTexture.create_from_image(img)
	
func _process(_dt: float) -> void:
	var dir = (get_global_mouse_position() - global_position).angle()
	rotation = dir
	print("f8eyfuiwf")
