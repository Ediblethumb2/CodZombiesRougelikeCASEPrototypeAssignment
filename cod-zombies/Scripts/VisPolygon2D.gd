extends Polygon2D

@export var player_path: NodePath
@export var collision_mask: int = 1        # walls' collision layer(s)
@export var max_distance: float = 1200.0
@export var fov: float = 3.0               # ~ 2 * shader half_angle
@export var ray_count: int = 256

var player: Node2D
var facing_angle: float = 0.0   # will be set from outside

func _ready() -> void:
	player = get_node(player_path) as Node2D
	color = Color(1, 1, 1, 1)   # white area = visible
	set_process(true)

func _process(delta: float) -> void:
	if player == null:
		return

	# centre polygon in the middle of LOSViewport texture
	var vp_size = get_viewport().size
	position = vp_size * 0.5

	var origin_world := player.global_position
	var space_state := get_world_2d().direct_space_state

	var pts: Array[Vector2] = []
	pts.append(Vector2.ZERO)  # centre of the fan

	for i in range(ray_count):
		var t := float(i) / float(ray_count - 1)
		var angle := facing_angle - fov * 0.5 + fov * t
		var dir := Vector2.RIGHT.rotated(angle)
		var target := origin_world + dir * max_distance

		var query := PhysicsRayQueryParameters2D.create(origin_world, target)
		query.collision_mask = collision_mask
		query.exclude = [player]

		var result := space_state.intersect_ray(query)
		var dist := max_distance
		if result:
			dist = (result.position - origin_world).length()

		# build polygon in local (screen-like) space
		pts.append(dir * dist)

	polygon = PackedVector2Array(pts)
