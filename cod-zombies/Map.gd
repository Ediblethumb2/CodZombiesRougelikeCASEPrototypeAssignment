extends Node2D


var Room = preload("res://Room.tscn")

var hallways = [Room]

var Polygons =[Room.instantiate().find_child("RoomLayer").find_child("CollisionPolygon2D").polygon]
@onready var Polygon2Dd = get_node("Polygon2D")


var clause = 1    # kevin

func _input(InputEvent) -> void:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			FillMap()
var Rects = []
var opposite := {
		"ConnR": "ConnL",
		"ConnL": "ConnR",
		"ConnU": "ConnD",
		"ConnD": "ConnU",
}
var RectToScene := {
		"Hallway3": "hallway3",
		"Hallway4": "hallway4",
}

# Helpers
func _room_local_poly(half_size: Vector2) -> PackedVector2Array:
	# Counter-clockwise rect centered at origin
	return PackedVector2Array([
		-half_size,                                 # (-w/2,-h/2)
		Vector2( half_size.x, -half_size.y),        # ( w/2,-h/2)
		half_size,                                  # ( w/2, h/2)
		Vector2(-half_size.x,  half_size.y)         # (-w/2, h/2)
	])

func _xform_poly(T: Transform2D, poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i in poly.size():
	
		out[i] = T * poly[i]
	return out

func _polys_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	# Precise check (returns Array of intersection polygons; empty means no overlap)
	var inter := Geometry2D.intersect_polygons(a, b)

	return inter.size() > 0
# Called when the node enters the scene tree for the first time.
var DrawingRect = Rect2(0,0,0,0)
var overlapped = false 
var points = []
var drawable  = false
func _draw() -> void:
#	var Hallwayy = Rect2(find_child("Hallway3").find_child(	"RoomLayer").global_position.x - 170,find_child("Hallway3").find_child(	"RoomLayer").global_position.y + 150,260,260)
		queue_redraw()
		if drawable == true:
			Polygon2Dd.polygon = points
			
		pass
var markerrunning = false
var successfulrooms = 0
var placing = false
var _spawning := false

func FillMap() -> void:
	if _spawning:
		return
	_spawning = true


	for Hallway in get_children():
		if not (Hallway is Node2D):
			continue

		var control := Hallway.get_node("RoomLayer/Control")
		if control == null:
			continue

		# gather only free markers
		var free_markers : Array[Node2D] = []
		for m in control.get_children():
			if not m.get_meta("Occupied", false):
				free_markers.append(m)
		if free_markers.is_empty():
			continue

		var marker : Node2D = free_markers.pick_random()

		# pick a room/hallway scene
		var room_packed : PackedScene = hallways.pick_random()
		var obj := room_packed.instantiate() as Node2D

		# pick a free connector on the new room
		var new_ctrl := obj.find_child("RoomLayer").find_child("Control")
		var free_conns : Array[Node2D] = []
		for c in new_ctrl.get_children():
			if not c.get_meta("Occupied", false):
				free_conns.append(c)
		if free_conns.is_empty():
			obj.queue_free()
			continue
		var new_conn : Node2D = free_conns.pick_random()

		# compute transform to glue connectors (180° flip)
		var T_marker := Transform2D(marker.global_rotation, marker.global_position + Vector2(0,70))
		
	
		var T_conn   := Transform2D(new_conn.rotation, new_conn.position)
		var R_180    := Transform2D(PI, Vector2.ZERO)
		var T_roomlayer := T_marker * R_180 * T_conn.affine_inverse()
		# collision polygon in world-space
		var local_poly : PackedVector2Array = Polygons[hallways.find(room_packed)]
		var world_poly := _xform_poly(T_roomlayer, local_poly)

		# overlap test against all placed polys
		var overlaps := false
		points = world_poly
		Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
		drawable = true
		_draw()
		for placed in Rects:
			if _polys_overlap(placed, world_poly):
				overlaps = true
				break

		if overlaps:
			marker.set_meta("Occupied", true)  # mark this connector closed
			obj.queue_free()
			_spawning = false 
			break

		# place it
		obj.find_child("RoomLayer").global_position = T_roomlayer.origin
	
		obj.find_child("RoomLayer").global_rotation = T_roomlayer.get_rotation()
		obj.scale = Vector2.ONE

		# add to tree deferred (avoid mid-iteration churn) & update caches
		add_child(obj)
		Rects.append(world_poly)
		successfulrooms += 1

		marker.set_meta("Occupied", true)
		new_conn.set_meta("Occupied", true)
		_spawning = false 
		break  # only one placement per FillMap() call

			

						
	
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if successfulrooms < 20:
		
		#FillMap()
		
	#else:
		pass
		#await FillDeadEnd()

		
	#pass
