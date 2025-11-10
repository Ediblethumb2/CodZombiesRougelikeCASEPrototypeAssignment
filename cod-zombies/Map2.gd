extends Node2D


var Room = preload("res://Room.tscn")
var FourWay = preload("res://Hallway4Way.tscn")
var Wall = preload("res://Wall.tscn")
var Shop = preload("res://shop.tscn")
var TreasureRoom = preload("res://TreasureRoom.tscn")
var hallways = [Room,FourWay]
var SpecialRoom = [Shop,TreasureRoom]
var SpecialRoomPolygons = [Shop.instantiate().find_child("RoomLayer").find_child("CollisionPolygon2D").polygon,TreasureRoom.instantiate().find_child("RoomLayer").find_child("CollisionPolygon2D").polygon]
var SpecialRoomWeighting = {"Shop" : 20,"TreasureRoom" : 20}
var DeadEnd1 = preload("res://DeadEnd.tscn")
var DeadEnds = [DeadEnd1,Wall]
var PolygonsDeadEnds= [DeadEnd1.instantiate().find_child("RoomLayer").find_child("CollisionPolygon2D").polygon,Wall.instantiate().find_child("RoomLayer").find_child("CollisionPolygon2D").polygon]
var Polygons =[Room.instantiate().find_child("RoomLayer").find_child("CollisionPolygon2D").polygon,FourWay.instantiate().find_child("RoomLayer").find_child("CollisionPolygon2D").polygon]
@onready var Polygon2Dd = get_node("Polygon2D")
var CollisionShapeRects = []
var NextRoomID = 0 
var IDByRoomlayer = {}
var RoomLayerByID = {}
var Edges = {}
var Depth = {}
const INF = 1_000_000_000 
var STARTID := -1
var clause = 1    # kevin
@onready var layer: TileMapLayer = $RoomLayer
const SRC := 0              # <-- set to your actual TileSet source id
const ATLAS := Vector2i(3,3) # <-- atlas coords inside that source

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
	RoomLayer.set_meta("RoomID",ID)
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
	
	
func _ready() -> void:
	grid = AStarGrid2D.new()
	var start_layer := $Node2D/RoomLayer
	STARTID = AddRoom(start_layer)
# Player.gd (_ready)

func FinalizeDungeon() -> void:
	ComputeDepths(STARTID)
	for room_layer in IDByRoomlayer.keys():
		var ID = IDByRoomlayer[room_layer]
		room_layer.set_meta("depth", Depth[ID])

func _draw() -> void:
	if cells.is_empty(): return

	# Draw per-cell debug rects from the SAME map coords
	# Convert map->local (pixels) using the TileMapLayer helper
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
			FillMap()
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
var successfulrooms = 0
var placing = false
var _spawning := false
var SpecialRooms = 0
func FillDeadEnd():
	if _spawning:
		return
	_spawning = true

	var DeadEndDupe = DeadEnds.duplicate()
	var PolygonsDeadEndsDupe = PolygonsDeadEnds.duplicate()
	for Hallway in get_children():
		if not (Hallway is Node2D):
			continue

		var control := Hallway.get_node("RoomLayer/Control")
		if control == null:
			continue

		# gather only free markers
		var free_markers : Array[Node2D] = []
		for m in control.get_children():
			if m.get_meta("Occupied") == false || m.get_meta("Searchable") == true:
				free_markers.append(m)
		if free_markers.is_empty():
			continue
		
		var marker : Node2D = free_markers.pick_random()
		

		# pick a room/hallway scene
		

		# pick a free connector on the new room

		while true:
			await get_tree().physics_frame
			var room_packed : PackedScene = DeadEndDupe.pick_random()
			var obj := room_packed.instantiate() as Node2D
		
		
			var new_ctrl := obj.find_child("RoomLayer").find_child("Control")
			var free_conns : Array[Node2D] = []
			for c in new_ctrl.get_children():
				if  c.get_meta("Occupied") == false || c.get_meta("Searchable") == true:
					free_conns.append(c)
			if free_conns.is_empty():
				obj.queue_free()
				continue
			var new_conn : Node2D = free_conns.pick_random()
		# compute transform to glue connectors (180° flip)
			var T_marker := Transform2D(marker.global_rotation, marker.global_position)
			
		
			var T_conn   := Transform2D(new_conn.rotation, new_conn.position)
			var R_180    := Transform2D(PI, Vector2.ZERO)
			var T_roomlayer := T_marker * R_180 * T_conn.affine_inverse()
			# collision polygon in world-space
			var local_poly : PackedVector2Array = PolygonsDeadEndsDupe[DeadEndDupe.find(room_packed)]
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
				
				marker.set_meta("Occupied",true)
				marker.set_meta("Searchable",true)
			
				obj.queue_free()
			
				DeadEndDupe.erase(DeadEndDupe.find(room_packed))
				PolygonsDeadEndsDupe.erase(DeadEndDupe.find(room_packed))
				continue
				

			# place it
			obj.find_child("RoomLayer").global_position = T_roomlayer.origin
		
			obj.find_child("RoomLayer").global_rotation = T_roomlayer.get_rotation()
			
			obj.scale = Vector2.ONE
			
			# add to tree deferred (avoid mid-iteration churn) & update caches
			add_child(obj)
			
			Rects.append(world_poly)
			CollisionShapeRects.append(obj.find_child("RoomLayer"))
			successfulrooms += 1
			
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


func FillMap() -> void:
	if _spawning:
		return
	_spawning = true

	var HallwayDupe = hallways.duplicate()
	var HallwayDupePolygons  = Polygons.duplicate()
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
		if SpecialRooms < 10 && (marker.global_position - $Node2D/RoomLayer.global_position).length() > 5000:
			SpecialRoomWeighting = {"Shop" : 5,"TreasureRoom" : 10}
		else:
			SpecialRoomWeighting = {"Shop" : 25,"TreasureRoom" : 25}
			
			
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
						CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
						Rects.append(world_poly)
						successfulrooms += 1
						
						marker.set_meta("Occupied", true)
						marker.set_meta("Searchable",false)
						new_conn.set_meta("Occupied", true)
						new_conn.set_meta("Searchable",false)
						_spawning = false
						_spawning = false
						SpecialRoomPlacing = false
						overlapsspecialroom   = false 
					
						break  # only one placement per FillMap() call
			
		if SpecialRooms < 25 && overlapsspecialroom == false && SpecialRoomPlacing == false:
			var SpecialRoomDupe = SpecialRoom.duplicate()
			var SpecialRoomDupePolygons = SpecialRoomPolygons.duplicate()
			var RoomPack = SpecialRoomDupe.pick_random()
			SpecialRoomObj = RoomPack.instantiate() as Node2D
			var Weighting = SpecialRoomWeighting[SpecialRoomObj.name]
			
			if randi() % Weighting == 1:

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
				var local_poly : PackedVector2Array = SpecialRoomDupePolygons[SpecialRoomDupe.find(RoomPack)]
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
				print(SpecialRoomObj.name)
				SpecialRoomObj.scale = Vector2.ONE
				print("aaaa")
					# add to tree deferred (avoid mid-iteration churn) & update caches
				add_child(SpecialRoomObj)
				CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
				Rects.append(world_poly)
				successfulrooms += 1
					
				marker.set_meta("Occupied", true)
				marker.set_meta("Searchable",false)
				new_conn.set_meta("Occupied", true)
				new_conn.set_meta("Searchable",false)
				_spawning = false
				_spawning = false
				SpecialRoomPlacing = false
				overlapsspecialroom   = false 
				
				break  # only one placement per FillMap() call
			
					
				
		if SpecialRoomPlacing == false:
			while HallwayDupe.size() > 0:
				await get_tree().physics_frame
				
				var room_packed : PackedScene = HallwayDupe.pick_random()
				var obj := room_packed.instantiate() as Node2D
			
			
				var new_ctrl := obj.find_child("RoomLayer").find_child("Control")
				var free_conns : Array[Node2D] = []
				for c in new_ctrl.get_children():
					if  c.get_meta("Occupied") == false :
						free_conns.append(c)
				if free_conns.is_empty():
					obj.queue_free()
					continue
				var new_conn : Node2D = free_conns.pick_random()
			# compute transform to glue connectors (180° flip)
				var T_marker := Transform2D(marker.global_rotation, marker.global_position)
				
			
				var T_conn   := Transform2D(new_conn.rotation, new_conn.position)
				var R_180    := Transform2D(PI, Vector2.ZERO)
				var T_roomlayer := T_marker * R_180 * T_conn.affine_inverse()
				# collision polygon in world-space
				var local_poly : PackedVector2Array = HallwayDupePolygons[HallwayDupe.find(room_packed)]
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
					
					marker.set_meta("Occupied",true)
					marker.set_meta("Searchable",true)
				
					obj.queue_free()
			
					HallwayDupe.erase(room_packed)
					HallwayDupePolygons.erase(local_poly)
					continue
					

				# place it
				#var fwd := Vector2.RIGHT.rotated(marker.global_rotation)
				#if fwd.y == 1:
				#	print("cgewuc	")
				#	T_roomlayer.origin += Vector2(-6,0)
				#if fwd.y == -1:
					#T_roomlayer.origin += Vector2(6,0)
				#if fwd.x == 1:
				#	T_roomlayer.origin += Vector2(0,8)
				#if fwd.x == -1:
					#T_roomlayer.origin += Vector2(0,-6)
					
								
					
				obj.find_child("RoomLayer").global_position = T_roomlayer.origin
			
				obj.find_child("RoomLayer").global_rotation = T_roomlayer.get_rotation()
				print(obj.name)
				obj.scale = Vector2.ONE
				print("aaaa")
				# add to tree deferred (avoid mid-iteration churn) & update caches
				add_child(obj)
				var SRCRoomLayer := Hallway.find_child("RoomLayer")
				var SRCID = AddRoom(SRCRoomLayer)    
				var NewRoomLayer := obj.find_child("RoomLayer")
				var NewID = AddRoom(NewRoomLayer)
				Connect(SRCID,NewID)
				CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
				Rects.append(world_poly)
				successfulrooms += 1

					
				marker.set_meta("Occupied", true)
				marker.set_meta("Searchable",false)
				new_conn.set_meta("Occupied", true)
				new_conn.set_meta("Searchable",false)
				_spawning = false 
			
				break  # only one placement per FillMap() call
			if HallwayDupe.size() == 0 :
					print("ZERO")
					DeadEndSearches += 1
			
			_spawning = false
			break
				

						
func _to_cell(world_pos: Vector2) -> Vector2i:
		return layer.local_to_map(layer.to_local(world_pos))
var onlyonce = false
var free_markersfinal : Array[Node2D] = []
var CheckingMarker = null
var LoopLayer = null
var a_id = null
var b_id = null
var region =  null
var SuccessfulDeadEnds = 0
func _process(delta: float) -> void:
	if successfulrooms < 100:
		pass 
		FillMap()
	
		
	else:
		
		if SuccessfulDeadEnds < DeadEndSearches:
			FillDeadEnd()
		else:
			FinalizeDungeon()
			
	
	
		
			

		
					
				
				
			

		
	#pass
