extends Node2D

#Preloading all rooms for instancing when generating procedurally
var Room = load("res://Room.tscn")
var FourWay = load("res://Hallway4Way.tscn")
var Wall = load("res://Wall.tscn")
var Shop = load("res://shop.tscn")
var TreasureRoom = load("res://TreasureRoom.tscn")
var CardShop = load("res://CardShop.tscn")
var DeadEnd1 = preload("res://DeadEnd.tscn")
#Array of rooms to then be duped later on in procedural generation
var hallways = [Room,FourWay]
var SpecialRoom = [Shop,TreasureRoom]
var DeadEnds = [DeadEnd1,Wall]
#Dictionary for the rarity of the special rooms 
var SpecialRoomWeighting = {"Shop" : 10,"TreasureRoom" : 35}
@onready var game_over_camera: Camera2D = $GameOverCamera
@onready var Polygon2Dd = get_node("Polygon2D")
var CollisionShapeRects = []
var NextRoomID = 0
@export var SuccessfulRooms = 0  
var IDByRoomlayer = {}
var RoomLayerByID = {}
var Edges = {}
var Depth = {}
const INF = 1_000_000_000 
var STARTID := -1
var clause = 1    # kevin
@onready var layer: TileMapLayer = $RoomLayer
const SRC := 0              # <-- source id
const ATLAS := Vector2i(3,3) # <-- atlas coords inside that source
func get_room_id_from_position(pos: Vector2) -> int:
	# Loop all known rooms and see whose polygon contains the point
	for id in RoomLayerByID.keys():
		var room_layer: Node2D = RoomLayerByID[id]
		var poly_local: PackedVector2Array = room_layer.get_node("CollisionPolygon2D").polygon
		var poly_world := _xform_poly(room_layer.global_transform, poly_local)
		
		if Geometry2D.is_point_in_polygon(pos, poly_world):
			return id
	
	return -1  # not found
func build_room_visit_order(start_id: int) -> Array[int]:
	var order: Array[int] = []
	if start_id == -1 or not RoomLayerByID.has(start_id):
		return order

	var visited := {}
	var queue: Array[int] = [start_id]

	visited[start_id] = true

	while not queue.is_empty():
		var u: int = queue.pop_front()
		order.append(u)

		for v in Edges.get(u, []):
			if not visited.has(v) and RoomLayerByID.has(v):
				visited[v] = true
				queue.append(v)


	var max_rooms := 10000000000
	if order.size() > max_rooms:
		order = order.slice(0, max_rooms)

	return order
func build_camera_path(start_id: int) -> Array[Vector2]:
	var ids := build_room_visit_order(start_id)
	var path: Array[Vector2] = []

	for id in ids:
		var room_layer: Node2D = RoomLayerByID[id]
		var target := room_layer.get_node_or_null("CameraTarget")
		if target:
			path.append(target.global_position)
		else:
			# Fallback: use RoomLayer position if no CameraTarget
			path.append(room_layer.global_position)

	return path
func start_game_over_pan(start_room_id: int, death_pos: Vector2) -> void:
	# Build ordered list of positions
	var path := build_camera_path(start_room_id)
	if path.is_empty():
		return

	# Start camera at exact death position
	game_over_camera.global_position = death_pos
	game_over_camera.enabled = true

	var travel_time := 1.4  # seconds between rooms
	var hold_time := 0.8    # seconds to pause on each room

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Move from death pos -> centre of first room
	tween.tween_property(
		game_over_camera,
		"global_position",
		path[0],
		travel_time
	)

	# Then room to room
	for i in range(1, path.size()):
		tween.tween_interval(hold_time)
		tween.tween_property(
			game_over_camera,
			"global_position",
			path[i],
			travel_time
		)

	# Hold on last room, then finish
	tween.tween_interval(hold_time)
	tween.tween_callback(Callable(self, "_on_game_over_pan_finished"))
func OnPlayerDied(death_pos: Vector2) -> void:
	
	
	
	# Figure out which room they died in
	var room_id := get_room_id_from_position(death_pos)
	if room_id == -1:
		room_id = STARTID  # fallback so it still runs

	start_game_over_pan(room_id, death_pos)
var grid: AStarGrid2D
var cells: Array[Vector2i]    # path in MAP COORDS (no pixels)
func AddRoom(RoomLayer):
	if RoomLayer in IDByRoomlayer:
		return IDByRoomlayer[RoomLayer]
	var ID = NextRoomID	
	NextRoomID+= 1
	IDByRoomlayer[RoomLayer] = ID
	RoomLayerByID[ID] = RoomLayer
	Edges[ID] = []
	Depth[ID] = INF
	RoomLayer.set_meta("RoomId",ID)
	return ID
func Connect(a_id: int, b_id: int):
	if not Edges.has(a_id): Edges[a_id] = []
	if not Edges.has(b_id): Edges[b_id] = []
	if b_id not in Edges[a_id]: Edges[a_id].append(b_id)
	if a_id not in Edges[b_id]: Edges[b_id].append(a_id)
func ComputeDepths(start_id: int) -> void:
	for id in Edges.keys(): Depth[id] = INF
	Depth[start_id] = 0
	var q: Array = [start_id]
	var head := 0
	while head < q.size():
		var u = q[head]; head += 1
		for v in Edges[u]:
			if Depth[v] == INF:
				Depth[v] = Depth[u] + 1
				q.append(v)
	
func SetupGridFromTileMap() -> void:
	grid = AStarGrid2D.new()
	grid.cell_size = Vector2i(64, 64)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN

	var used: Rect2i = layer.get_used_rect()  # cells
	var pad := Vector2i(4, 4)
	if used.size == Vector2i.ZERO:
		# Fallback: approximate region from placed rooms/connectors if tilemap isn't filled yet.
		var min_c := Vector2i(  1<<29,  1<<29)
		var max_c := Vector2i(-(1<<29), -(1<<29))
		for h in get_children():
			if h is Node2D:
				var ctrl := h.get_node_or_null("RoomLayer/Control")
				if ctrl:
					for m in ctrl.get_children():
						if m is Node2D:
							var c := layer.local_to_map(layer.to_local(m.global_position))
							min_c.x = min(min_c.x, c.x)
							min_c.y = min(min_c.y, c.y)
							max_c.x = max(max_c.x, c.x)
							max_c.y = max(max_c.y, c.y)
		if min_c.x > max_c.x:
			min_c = Vector2i(-16, -16); max_c = Vector2i(16, 16) # tiny safe default
		used = Rect2i(min_c, (max_c - min_c) + Vector2i(1,1))

	grid.region = Rect2i(used.position - pad, used.size + pad*2)
	print(grid.region)
	grid.update()


func _ready() -> void:
	pass
	
	var start_layer := $Node2D/RoomLayer
	STARTID = AddRoom(start_layer)

func SetupGrid():
	grid.region = Rect2i(-2500, -2500, 5000,5000)
	grid.cell_size = Vector2i(64,64)
	grid.update()
func ShowPath(Start,End):
	Start  = $TileMapLayer.local_to_map(Vector2i(Start))
	End  = $TileMapLayer.local_to_map(Vector2i(End))
	var PathTaken  = grid.get_id_path(Start,End)
	
	for cell in PathTaken:
		
		$TileMapLayer.set_cell(cell,0,Vector2(2,0))
	
func FinalizeDungeon() -> void:
	ComputeDepths(STARTID)
	for room_layer in IDByRoomlayer.keys():
		var ID = IDByRoomlayer[room_layer]
		room_layer.set_meta("depth", Depth[ID])
		room_layer.set_meta("Budget",DepthBudgetCurve(Depth[ID]))
		

func _draw() -> void:
	if cells.is_empty(): return

	var pts := PackedVector2Array()

	for c in cells:
		var px := layer.map_to_local(c) - layer.tile_set.tile_size / 2.0
		draw_rect(Rect2(px, layer.tile_set.tile_size), Color(1,0,0,0.25), true)
		pts.append(layer.map_to_local(c))

	draw_polyline(pts, Color(1,0,1), 3.0, true)
	draw_circle(pts[0], 6.0, Color(0,1,0))
	draw_circle(pts[pts.size()-1], 6.0, Color(1,1,0))
func _input(InputEvent) -> void:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			pass
			#FillDeadEnd()
@onready var Rects = [$Node2D/RoomLayer/CollisionPolygon2D.polygon]
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
var DeadEndSearches = 0
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

var markerrunning = false

var placing = false
var _spawning := false
var SpecialRooms = 0
func FindPaths():
	for Hallway in get_children():
		if not Hallway.get_class() == "Node2D":
			continue 
		var free_markers : Array[Node2D] = []
		
		var control = Hallway.get_node("RoomLayer/Control")
		for m in control.get_children():
			if m.get_meta("Occupied") == false || m.get_meta("Searchable") == true:
				free_markers.append(m)
		if free_markers.is_empty():
			continue
		var marker : Node2D = free_markers.pick_random()
		for Hallway2 in get_children():
			if not Hallway2.get_class() == "Node2D":
				continue 
			if Hallway == Hallway2:
				continue
			var free_markers2 : Array[Node2D] = []
	
			var control2 = Hallway2.get_node("RoomLayer/Control")
			for m in control2.get_children():
				for m2 in free_markers:
					if (m.get_meta("Occupied") == false) || (m.get_meta("Searchable") == true && Vector2(m.global_position-m2.global_position).length() < 1000):
						free_markers2.append(m2)
					
						Hallway.find_child("RoomLayer").find_child("RichTextLabel").text = " CONNECTING"
						Hallway2.find_child("RoomLayer").find_child("RichTextLabel").text = " CONNECTING"
						ShowPath(m.global_position,m2.global_position)
						break
			if free_markers2.is_empty():
				continue
			
		
var current_room_id: int = -1

func set_current_room(id: int) -> void:
	current_room_id = id			
func FillDeadEnd():

	_spawning = true

	var DeadEndDupe = DeadEnds.duplicate()
	for Hallway in get_children():
		if not (Hallway is Node2D):
			continue

		var control := Hallway.get_node("RoomLayer/Control")
		if control == null:
			continue

		# gather only free markers
		var free_markers : Array[Node2D] = []
		for m in control.get_children():
			if m.get_meta("Searchable") == true and m.get_meta("Occupied", false) == false:
				free_markers.append(m)
			
		if free_markers.is_empty():
			continue
		
		var marker : Node2D = free_markers.pick_random()
		

		while true:
			await get_tree().physics_frame
			if DeadEndDupe.is_empty():
					# Nothing fits here, give up on this marker
					marker.set_meta("Searchable", false)
					_spawning = false
					break

			var room_packed : PackedScene = DeadEndDupe.pick_random()
			var obj := room_packed.instantiate() as Node2D
		
		
			var new_ctrl := obj.find_child("RoomLayer").find_child("Control").get_children()
			var new_conn : Node2D = new_ctrl.pick_random()
		# compute transform to glue connectors (180° flip)
			var T_marker := Transform2D(marker.global_rotation, marker.global_position)
			
		
			var T_conn   := Transform2D(new_conn.rotation, new_conn.position)
			var R_180    := Transform2D(PI, Vector2.ZERO)
			var T_roomlayer := T_marker * R_180 * T_conn.affine_inverse()
			# collision polygon in world-space
			var local_poly : PackedVector2Array = obj.get_node("RoomLayer").get_node("CollisionPolygon2D").polygon
			var world_poly := _xform_poly(T_roomlayer, local_poly)

			# overlap test against all placed polys
			var overlaps := false
			points = world_poly
			Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
			Polygon2Dd.polygon = points
			drawable = true
			
		
			for placed in Rects:
			
				if _polys_overlap(placed, world_poly):
					
					overlaps = true
					
					break

			if overlaps:
				
				obj.queue_free()
				DeadEndDupe.erase(DeadEndDupe.find(room_packed))
	 
				continue
				

			# place it
			obj.find_child("RoomLayer").global_position = T_roomlayer.origin
		
			obj.find_child("RoomLayer").global_rotation = T_roomlayer.get_rotation()
			
			obj.scale = Vector2.ONE
			
			# add to tree deferred (avoid mid-iteration churn) & update caches
			add_child(obj)
			var SRCRoomLayer := Hallway.find_child("RoomLayer")
			var SRCID = AddRoom(SRCRoomLayer)    
			var NewRoomLayer := obj.find_child("RoomLayer")
			var NewID = AddRoom(NewRoomLayer)
			Connect(SRCID,NewID)
			
			Rects.append(world_poly)
			CollisionShapeRects.append(obj.find_child("RoomLayer"))
			SuccessfulRooms += 1
			
			marker.set_meta("Occupied", true)
			marker.set_meta("Searchable",false)
			new_conn.set_meta("Occupied", true)
			new_conn.set_meta("Searchable",false)
			SuccessfulDeadEnds += 1
			
			_spawning = false 
		
			break  # only one placement per FillMap() call
		break
var SpecialRoomPlacing  = false 
var overlapsspecialroom = false
var ForcePlace = false
var SpecialRoomObj = null
var fill_fail_streak := 0
const MAX_FILL_FAILS := 40  
var main_phase_done := false
func DepthBudgetCurve(depth:int) -> float:
	var L := 1000    # asymptote (late game budget ceiling)
	var k := 0.7    # slope
	var m := 8.0       # midpoint depth
	return 12.0 + L / (1.0 + exp(-k * float(depth - m)))
# Returns the connector's transform RELATIVE to the RoomLayer it belongs to.
func _conn_xform_rel_to_roomlayer(conn: Node2D) -> Transform2D:
	var ctrl := conn.get_parent() # "Control" under the RoomLayer
	# ctrl.transform is local-to-RoomLayer; conn.transform is local-to-Control
	return ctrl.transform * conn.transform

# Build the world transform for the RoomLayer that makes conn meet marker (flipped 180°).
func _solve_roomlayer_xform(marker: Node2D, conn: Node2D) -> Transform2D:
	var T_marker := marker.global_transform
	var T_conn_rel := _conn_xform_rel_to_roomlayer(conn)
	var R_180 := Transform2D(PI, Vector2.ZERO)
	# RoomLayer_world * T_conn_rel = T_marker * R_180
	return T_marker * R_180 * T_conn_rel.affine_inverse()
func CountDeadEndMarkers() -> int:
	var count := 0
	for h in get_children():
		if h is Node2D:
			var control := h.get_node_or_null("RoomLayer/Control")
			if control:
				for m in control.get_children():
					# Occupied AND still searchable = blocked connector (dead-end candidate)
					if m.get_meta("Searchable") == true and m.get_meta("Occupied", false) == false:
						count += 1
	return count

func FillMap() -> bool:

	_spawning = true
	
	var HallwayDupe = hallways.duplicate()

	var placed_something := false
	for Hallway in get_children():
		if not (Hallway is Node2D):
			continue

		var control := Hallway.get_node("RoomLayer/Control")
		if control == null:
			continue
		
		
		# gather only free markers
		var free_markers : Array[Node2D] = []
		for m in control.get_children():
			if not m.get_meta("Occupied", false) and not m.get_meta("Searchable", false):
				free_markers.append(m)

		if free_markers.is_empty():
			continue
		
		var marker : Node2D = free_markers.pick_random()
		if SpecialRooms < 10 && (marker.global_position - $Node2D/RoomLayer.global_position).length() > 5000:
			SpecialRoomWeighting = {"Shop" : 10,"TreasureRoom" : 35}
		else:
			SpecialRoomWeighting = {"Shop" : 10,"TreasureRoom" : 35}
	
		if overlapsspecialroom == true && SpecialRoomPlacing == true:
					
					var new_ctrl = SpecialRoomObj.find_child("RoomLayer").find_child("Control")
					var free_conns : Array[Node2D] = []
					for c in new_ctrl.get_children():
						if  c.get_meta("Occupied") == false :
							free_conns.append(c)
					if free_conns.is_empty():
						SpecialRoomObj.queue_free()
						continue
					var new_conn : Node2D = free_conns.pick_random()
				# compute transform to glue connectors (180° flip)
					var T_marker := Transform2D(marker.global_rotation, marker.global_position)
					

					var T_conn   := Transform2D(new_conn.rotation, new_conn.position)
					var R_180    := Transform2D(PI, Vector2.ZERO)
					var T_roomlayer := T_marker * R_180 * T_conn.affine_inverse()
					
					# collision polygon in world-space
					var local_poly : PackedVector2Array = SpecialRoomObj.find_child("RoomLayer").find_child("CollisionPolygon2D").polygon
					var world_poly := _xform_poly(T_roomlayer, local_poly)

					# overlap test against all placed polys
					
					points = world_poly
					Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
					Polygon2Dd.polygon = points
					drawable = true
					
					
					for placed in Rects:
					
						if _polys_overlap(placed, world_poly):
							
							overlapsspecialroom = true
							
							
							break
						overlapsspecialroom = false
						
					
							
							
				

					# place it
					
					if overlapsspecialroom == false:
						SpecialRoomObj.find_child("RoomLayer").global_position = T_roomlayer.origin
					
						SpecialRoomObj.find_child("RoomLayer").global_rotation = T_roomlayer.get_rotation()
				
						SpecialRoomObj.scale = Vector2.ONE
						
						# add to tree deferred (avoid mid-iteration churn) & update caches
						add_child(SpecialRoomObj)
						var SRCRoomLayer := Hallway.find_child("RoomLayer")
						var SRCID = AddRoom(SRCRoomLayer)    
						var NewRoomLayer = SpecialRoomObj.find_child("RoomLayer")
						var NewID = AddRoom(NewRoomLayer)
						Connect(SRCID,NewID)
						CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
						Rects.append(world_poly)
						SuccessfulRooms += 1
						
						marker.set_meta("Occupied", true)
						marker.set_meta("Searchable",false)
						new_conn.set_meta("Occupied", true)
						new_conn.set_meta("Searchable",false)
						_spawning = false
					
						SpecialRoomPlacing = false
						overlapsspecialroom   = false 
						placed_something = true
					
					

		if SpecialRooms < 50 && overlapsspecialroom == false && SpecialRoomPlacing == false:
			var SpecialRoomDupe = SpecialRoom.duplicate()

			var RoomPack = SpecialRoomDupe.pick_random()
			SpecialRoomObj = RoomPack.instantiate() as Node2D
			var Weighting = SpecialRoomWeighting[SpecialRoomObj.name]
			
			if randi() % Weighting == 1:
				if SpecialRoomObj.name == "Shop":
					
					var Chance = randi() &1
				
					if Chance == 0:
						
						SpecialRoomObj = CardShop.instantiate() as Node2D
						
						
				SpecialRoomPlacing = true
		
				
				var new_ctrl = SpecialRoomObj.find_child("RoomLayer").find_child("Control")
				var free_conns : Array[Node2D] = []
				for c in new_ctrl.get_children():
					if  c.get_meta("Occupied") == false :
						free_conns.append(c)
				if free_conns.is_empty():
					SpecialRoomObj.queue_free()
					continue
				var new_conn : Node2D = free_conns.pick_random()
				# compute transform to glue connectors (180° flip)
				var T_marker := Transform2D(marker.global_rotation, marker.global_position)	
					
				
				var T_conn   := Transform2D(new_conn.rotation, new_conn.position)
				var R_180    := Transform2D(PI, Vector2.ZERO)
				var T_roomlayer := T_marker * R_180 * T_conn.affine_inverse()
					# collision polygon in world-space
				var local_poly : PackedVector2Array = SpecialRoomObj.find_child("CollisionPolygon2D").polygon
				var world_poly := _xform_poly(T_roomlayer, local_poly)

					# overlap test against all placed polys
					
				points = world_poly
			
				Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
				Polygon2Dd.polygon = points
				drawable = true
					
				
				for placed in Rects:
					
					if _polys_overlap(placed, world_poly):
							
						overlapsspecialroom = true
							
						break
					#print(HallwayDupe.size())
				if overlapsspecialroom:
						
	
			
					
					continue
						

					# place it
				SpecialRoomObj.find_child("RoomLayer").global_position = T_roomlayer.origin
				
				SpecialRoomObj.find_child("RoomLayer").global_rotation = T_roomlayer.get_rotation()
				
				SpecialRoomObj.scale = Vector2.ONE
			
					# add to tree deferred (avoid mid-iteration churn) & update caches
				add_child(SpecialRoomObj)
				var SRCRoomLayer := Hallway.find_child("RoomLayer")
				var SRCID = AddRoom(SRCRoomLayer)    
				var NewRoomLayer = SpecialRoomObj.find_child("RoomLayer")
				var NewID = AddRoom(NewRoomLayer)
				Connect(SRCID,NewID)
				CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
				Rects.append(world_poly)
				SuccessfulRooms += 1
					
				marker.set_meta("Occupied", true)
				marker.set_meta("Searchable",false)
				new_conn.set_meta("Occupied", true)
				new_conn.set_meta("Searchable",false)
				_spawning = false
			
				SpecialRoomPlacing = false
				overlapsspecialroom   = false 
				placed_something = true
				break  # only one placement per FillMap() call
			
					
		
		
		if SpecialRoomPlacing == false:
			
			while HallwayDupe.size() > 0:
				await get_tree().physics_frame
				
				
				var room_packed : PackedScene = HallwayDupe.pick_random()
				var obj := room_packed.instantiate() as Node2D
			
			
				var new_ctrl := obj.find_child("RoomLayer").find_child("Control")
				var free_conns : Array[Node2D] = []
				for c in new_ctrl.get_children():
					# IMPORTANT: default false so unset meta is treated as free
					if c.get_meta("Occupied", false) == false:
						free_conns.append(c)

				if free_conns.is_empty():
					obj.queue_free()
					HallwayDupe.erase(room_packed)  # <-- remove unusable type
					continue
				var new_conn : Node2D = free_conns.pick_random()
			# compute transform to glue connectors (180° flip)
				var T_marker := Transform2D(marker.global_rotation, marker.global_position)
				
			
				var T_conn   := Transform2D(new_conn.rotation, new_conn.position)
				var R_180    := Transform2D(PI, Vector2.ZERO)
				var T_roomlayer := T_marker * R_180 * T_conn.affine_inverse()
				# collision polygon in world-space
				#var local_poly : PackedVector2Array = HallwayDupePolygons[HallwayDupe.find(room_packed)]
				var local_poly = obj.get_node("RoomLayer").get_node("CollisionPolygon2D").polygon
				var world_poly := _xform_poly(T_roomlayer, local_poly)

				# overlap test against all placed polys
				var overlaps := false
				points = world_poly
				Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
				Polygon2Dd.polygon = points
				drawable = true
				
			
				for placed in Rects:
				
					if _polys_overlap(placed, world_poly):
						
						overlaps = true
						
						
						break
				#print(HallwayDupe.size())
				if overlaps:
						obj.queue_free()
					
						HallwayDupe.erase(room_packed)
						
						if HallwayDupe.is_empty():
							
							marker.set_meta("Searchable", true)  
						continue


								
					
				obj.find_child("RoomLayer").global_position = T_roomlayer.origin
			
				obj.find_child("RoomLayer").global_rotation = T_roomlayer.get_rotation()
			
				obj.scale = Vector2.ONE
			
				# add to tree deferred (avoid mid-iteration churn) & update caches
				add_child(obj)
				var SRCRoomLayer := Hallway.find_child("RoomLayer")
				var SRCID = AddRoom(SRCRoomLayer)    
				var NewRoomLayer := obj.find_child("RoomLayer")
				var NewID = AddRoom(NewRoomLayer)
				Connect(SRCID,NewID)
				CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
				Rects.append(world_poly)
				SuccessfulRooms += 1

					
				marker.set_meta("Occupied", true)
				marker.set_meta("Searchable",false)
				
				new_conn.set_meta("Occupied", true)
				new_conn.set_meta("Searchable",false)
				_spawning = false 
				placed_something = true
			
				break  # only one placement per FillMap() call
			
		
	

			if placed_something == true:
				break
			
	return placed_something
			
		
		
		
				
var Attempts = 0
var MaxAttempts = 10000

						
func _to_cell(world_pos: Vector2) -> Vector2i:
		return layer.local_to_map(layer.to_local(world_pos))
var onlyonce = false
var free_markersfinal : Array[Node2D] = []
var CheckingMarker = null
var LoopLayer = null
var a_id = null
var b_id = null
var region =  null
@export var SuccessfulDeadEnds = 0
var LastRoom = 0
func _process(delta: float) -> void:
	if main_phase_done:
		if DeadEndSearches == 0:
			DeadEndSearches = CountDeadEndMarkers()
		if SuccessfulDeadEnds < (DeadEndSearches):
			FillDeadEnd()
			print("fewfiuwgfuiew")
		
		else:

			FinalizeDungeon()
			set_process(false)
		return

# Phase 1: main room filling
	if SuccessfulRooms < 400:
		if not _has_any_free_connector():
			main_phase_done = true
			return

		var placed = await FillMap()
		if placed == false:
			Attempts += 1
		if Attempts >= MaxAttempts:
			get_tree().reload_current_scene()
	else:
		main_phase_done = true

func _has_any_free_connector() -> bool:
	for h in get_children():
		if h is Node2D:
			var control := h.get_node_or_null("RoomLayer/Control")
			if control:
				for m in control.get_children():
					if m.get_meta("Occupied") == false &&  m.get_meta("Searchable") == false: 
						return true
	return false
