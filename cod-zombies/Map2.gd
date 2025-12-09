extends Node2D

# Preloading all room scenes so they can be instanced quickly during procedural generation
var Room = load("res://Room.tscn")
var FourWay = load("res://Hallway4Way.tscn")
var Wall = load("res://Wall.tscn")
var Shop = load("res://shop.tscn")
var TreasureRoom = load("res://TreasureRoom.tscn")
var CardShop = load("res://CardShop.tscn")
var DeadEnd1 = preload("res://DeadEnd.tscn")

# Arrays of different room types that get cloned as the dungeon expands
var Hallways = [Room, FourWay]
var SpecialRoom = [Shop, TreasureRoom]
var DeadEnds = [DeadEnd1, Wall]

# Controls how often each special room can spawn (used as "weights" for randomness)
var SpecialRoomWeighting = {"Shop": 10, "TreasureRoom": 35}

# Camera used for the game-over pan across the generated dungeon
@onready var GameOverCamera: Camera2D = $GameOverCamera

# Helper polygon node used to visualise collision polygons during generation
@onready var Polygon2Dd = get_node("Polygon2D")

# Stores the collision polygons of all placed rooms, to prevent overlapping placements
var CollisionShapeRects = []

# Graph-related data for rooms (IDs, adjacency, depths)
var NextRoomID = 0                      # Next unique ID to assign to a new room
@export var SuccessfulRooms = 0         # How many rooms successfully got placed
var IDByRoomlayer = {}                  # Maps RoomLayer node -> room ID
var RoomLayerByID = {}                  # Maps room ID -> RoomLayer node
var Edges = {}                          # Graph edges: room ID -> array of connected room IDs
var Depth = {}                          # BFS distance from the starting room

const INF = 1_000_000_000               # "Infinity" value to mark unvisited rooms
var STARTID := -1                       # ID of the starting room (set in _ready)
var Clause = 1    # kevin               # Random debug/testing variable, not used in logic

# TileMap reference + constants for drawing/debugging
@onready var Layer: TileMapLayer = $RoomLayer
const SRC := 0                          # Tile source ID inside the TileSet
const ATLAS := Vector2i(3, 3)           # Atlas coords of the tile (if using atlases)

# ----------------------------------------
# ROOM LOOKUP / CAMERA PATH HELPERS
# ----------------------------------------

func GetRoomIdFromPosition(Pos: Vector2) -> int:
	# Given a world position, loop over all known rooms and
	# find which room's collision polygon contains that point.
	for Id in RoomLayerByID.keys():
		var RoomLayer: Node2D = RoomLayerByID[Id]
		var PolyLocal: PackedVector2Array = RoomLayer.get_node("OverlapPolygon").polygon
		var PolyWorld := XformPoly(RoomLayer.global_transform, PolyLocal)
		
		if Geometry2D.is_point_in_polygon(Pos, PolyWorld):
			return Id
	
	# If no room contains this position, return -1 so we can handle it safely
	return -1  # not found


func BuildRoomVisitOrder(StartId: int) -> Array[int]:
	# Builds a BFS order of room IDs starting from StartId.
	# This is used to decide the order the camera pans through on death.
	var Order: Array[int] = []
	if StartId == -1 or not RoomLayerByID.has(StartId):
		return Order

	var Visited := {}
	var Queue: Array[int] = [StartId]

	Visited[StartId] = true

	while not Queue.is_empty():
		var U: int = Queue.pop_front()
		Order.append(U)

		for V in Edges.get(U, []):
			V += 4  # Offset used to line up with how IDs/graph are structured in this project
			if not Visited.has(V) and RoomLayerByID.has(V):
				Visited[V] = true
				Queue.append(V)
				
	# Limit the path so the camera doesn't try to visit too many rooms
	var MaxRooms := 15
	if Order.size() > MaxRooms:
		Order = Order.slice(0, MaxRooms)

	return Order


func BuildCameraPath(StartId: int) -> Array[Vector2]:
	# Converts a list of room IDs into a list of world positions
	# that the game-over camera should tween through.
	var Ids := BuildRoomVisitOrder(StartId)
	var Path: Array[Vector2] = []

	for Id in Ids:
		var RoomLayer: Node2D = RoomLayerByID[Id]
		var Target := RoomLayer.get_node_or_null("CameraTarget")
		if Target:
			# If the room has a dedicated CameraTarget, use that point
			Path.append(Target.global_position)
		else:
			# Otherwise fallback to the room's own position
			Path.append(RoomLayer.global_position)

	return Path


# ----------------------------------------
# GAME OVER CAMERA PAN LOGIC
# ----------------------------------------

func StartGameOverPan(StartRoomId: int, DeathPos: Vector2) -> void:
	# Builds an ordered list of positions and starts a tween to pan the camera across them.
	var Path := BuildCameraPath(StartRoomId)
	if Path.is_empty():
		return

	# Start camera at the exact position where the player died
	GameOverCamera.global_position = DeathPos
	GameOverCamera.enabled = true

	var TravelTime := 2   # Time taken to move between rooms
	var HoldTime := 0.3   # How long to pause on each room

	var PanTween := create_tween()
	PanTween.set_trans(Tween.TRANS_SINE)
	PanTween.set_ease(Tween.EASE_IN_OUT)

	# Move from death position -> centre of the first room in the path
	PanTween.tween_property(
		GameOverCamera,
		"global_position",
		Path[1],
		TravelTime
	)

	# Then move from room to room through the rest of the path
	for I in range(2, Path.size()):
		PanTween.tween_interval(HoldTime)
		PanTween.tween_property(
			GameOverCamera,
			"global_position",
			Path[I],
			TravelTime
		)
	
	# Hold on the last room, then call the "finished" callback
	PanTween.tween_interval(HoldTime)
	print("gwufgwef")
	PanTween.tween_callback(Callable(self, "OnGameOverPanFinished"))


# Called when all the camera tweens are done (end of game over sequence)
func OnGameOverPanFinished():
	get_tree().reload_current_scene()


func OnPlayerDied(DeathPos: Vector2) -> void:
	# Called by the player script when they die.
	# Tries to work out which room they died in, then starts the pan from there.
	var RoomId := GetRoomIdFromPosition(DeathPos)
	if RoomId == -1:
		# If we can't find the room by position, fall back to the STARTID.
		RoomId = STARTID  # fallback so it still runs

	StartGameOverPan(RoomId, DeathPos)


# ----------------------------------------
# ROOM GRAPH: ADDING ROOMS + EDGES
# ----------------------------------------

func AddRoom(RoomLayer):
	# Registers a RoomLayer in the graph and gives it a unique ID.
	# If it's already known, just return the existing ID.
	if RoomLayer in IDByRoomlayer:
		return IDByRoomlayer[RoomLayer]
	var Id = NextRoomID	
	NextRoomID += 1
	IDByRoomlayer[RoomLayer] = Id
	RoomLayerByID[Id] = RoomLayer
	Edges[Id] = []
	Depth[Id] = INF
	RoomLayer.set_meta("RoomId", Id)
	return Id


func Connect(AId: int, BId: int):
	# Connects two rooms together in the graph (bidirectional edge).
	if not Edges.has(AId):
		Edges[AId] = []
	if not Edges.has(BId):
		Edges[BId] = []
	if BId not in Edges[AId]:
		Edges[AId].append(BId)
	if AId not in Edges[BId]:
		Edges[BId].append(AId)


func ComputeDepths(StartId: int) -> void:
	# Performs a BFS from the starting room to work out how "deep" each room is.
	for Id in Edges.keys():
		Depth[Id] = INF
	Depth[StartId] = 0
	var Q: Array = [StartId]
	var Head := 0
	while Head < Q.size():
		var U = Q[Head]
		Head += 1
		for V in Edges[U]:
			if Depth[V] == INF:
				Depth[V] = Depth[U] + 1
				Q.append(V)


func _ready() -> void:
	# At the start of the scene, register the initial RoomLayer as the starting room.
	# This will be the root of the dungeon graph.
	pass
	
	var StartLayer := $Hallway/RoomLayer
	STARTID = AddRoom(StartLayer)


# ----------------------------------------
# FINALISING DUNGEON AFTER GENERATION
# ----------------------------------------

func FinalizeDungeon() -> void:
	# Runs once generation is finished.
	# Computes depths from STARTID and sets metadata on each room
	# so other systems (like difficulty scaling) can use it.
	ComputeDepths(STARTID)
	for RoomLayer in IDByRoomlayer.keys():
		var Id = IDByRoomlayer[RoomLayer]
		RoomLayer.set_meta("depth", Depth[Id])
		RoomLayer.set_meta("Budget", DepthBudgetCurve(Depth[Id]))


func _input(InputEvent) -> void:
	# Currently not used, but left in case we want to manually trigger dead-end filling for debugging.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pass
		#FillDeadEnd()


# ----------------------------------------
# POLYGON / COLLISION HELPERS
# ----------------------------------------

@onready var Rects = [$Hallway/RoomLayer/OverlapPolygon.polygon]

# Opposite connector names for aligning corridor pieces (not heavily used here but useful conceptually)
var Opposite := {
	"ConnR": "ConnL",
	"ConnL": "ConnR",
	"ConnU": "ConnD",
	"ConnD": "ConnU",
}

# Mapping from rect "types" to scene names if we want different hallway layouts
var RectToScene := {
	"Hallway3": "hallway3",
	"Hallway4": "hallway4",
}

var DeadEndSearches = 0   # How many dead-end markers we need to resolve later

# Creates a local rectangle polygon, mainly used for generating room shapes if needed.
func RoomLocalPoly(HalfSize: Vector2) -> PackedVector2Array:
	# Counter-clockwise rect centered at origin
	return PackedVector2Array([
		-HalfSize,                                 # (-w/2, -h/2)
		Vector2(HalfSize.x, -HalfSize.y),         # ( w/2, -h/2)
		HalfSize,                                  # ( w/2,  h/2)
		Vector2(-HalfSize.x, HalfSize.y)          # (-w/2,  h/2)
	])


# Applies a Transform2D to every point in a polygon and returns the result.
func XformPoly(T: Transform2D, Poly: PackedVector2Array) -> PackedVector2Array:
	var Out := PackedVector2Array()
	Out.resize(Poly.size())
	for I in Poly.size():
		Out[I] = T * Poly[I]
	return Out


# Uses Godot's built-in polygon intersection function to check if two polygons overlap.
func PolysOverlap(A: PackedVector2Array, B: PackedVector2Array) -> bool:
	# Precise check (returns Array of intersection polygons; empty means no overlap)
	var Inter := Geometry2D.intersect_polygons(A, B)
	return Inter.size() > 0


# ----------------------------------------
# DEBUG/VISUALISATION STATE
# ----------------------------------------

# Variables used mostly for debugging the generation and drawing helper polygons
var DrawingRect = Rect2(0, 0, 0, 0)
var Overlapped = false 
var Points = []
var Drawable = false
var Markerrunning = false
var Placing = false
var Spawning := false
var SpecialRooms = 0   # How many special rooms have been placed so far


# Stores which room the player is currently in (set externally from player logic)
var CurrentRoomId: int = -1

func SetCurrentRoom(Id: int) -> void:
	CurrentRoomId = Id


# ----------------------------------------
# DEAD-END FILLING PHASE
# ----------------------------------------

func FillDeadEnd():
	# This function tries to attach "dead-end" rooms onto connectors
	# that were left as "Searchable" but not used in the main phase.
	Spawning = true

	var DeadEndDupe = DeadEnds.duplicate()
	for Hallway in get_children():
		if not (Hallway is Node2D):
			continue

		var control := Hallway.get_node("RoomLayer/Control")
		if control == null:
			continue

		# Gather markers that are marked as dead-end candidates
		var FreeMarkers: Array[Node2D] = []
		for M in control.get_children():
			if M.get_meta("Searchable") == true and M.get_meta("Occupied", false) == false:
				FreeMarkers.append(M)
			
		if FreeMarkers.is_empty():
			continue
		
		var Marker: Node2D = FreeMarkers.pick_random()
		
		while true:
			await get_tree().physics_frame
			if DeadEndDupe.is_empty():
				# If no dead-end prefabs can fit here, stop searching this marker.
				Marker.set_meta("Searchable", false)
				Spawning = false
				break

			var RoomPacked: PackedScene = DeadEndDupe.pick_random()
			var Obj := RoomPacked.instantiate() as Node2D
		
			var NewCtrl := Obj.find_child("RoomLayer").find_child("Control").get_children()
			var NewConn: Node2D = NewCtrl.pick_random()
			# Compute transform to glue connectors (180° flip)
			var TMarker := Transform2D(Marker.global_rotation, Marker.global_position)
			var TConn := Transform2D(NewConn.rotation, NewConn.position)
			var R180 := Transform2D(PI, Vector2.ZERO)
			var TRoomlayer := TMarker * R180 * TConn.affine_inverse()
			# Collision polygon in world-space
			var LocalPoly: PackedVector2Array = Obj.get_node("RoomLayer").get_node("OverlapPolygon").polygon
			var WorldPoly := XformPoly(TRoomlayer, LocalPoly)

			# Check if this new dead-end overlaps any existing room
			var Overlaps := false
			Points = WorldPoly
			Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
			Polygon2Dd.polygon = Points
			Drawable = true
			
			for Placed in Rects:
				if PolysOverlap(Placed, WorldPoly):
					Overlaps = true
					break

			if Overlaps:
				# If it overlaps, remove this option from the list and try another dead-end prefab
				Obj.queue_free()
				DeadEndDupe.erase(DeadEndDupe.find(RoomPacked))
				continue

			# If there's no overlap, place the dead-end room
			Obj.find_child("RoomLayer").global_position = TRoomlayer.origin
			Obj.find_child("RoomLayer").global_rotation = TRoomlayer.get_rotation()
			Obj.scale = Vector2.ONE
			
			# Add the room to the tree + update graph data
			add_child(Obj)
			var SRCRoomLayer := Hallway.find_child("RoomLayer")
			var SRCID = AddRoom(SRCRoomLayer)    
			var NewRoomLayer := Obj.find_child("RoomLayer")
			var NewID = AddRoom(NewRoomLayer)
			Connect(SRCID, NewID)
			
			Rects.append(WorldPoly)
			CollisionShapeRects.append(Obj.find_child("RoomLayer"))
			SuccessfulRooms += 1
			
			# Mark both connectors as used now
			Marker.set_meta("Occupied", true)
			Marker.set_meta("Searchable", false)
			NewConn.set_meta("Occupied", true)
			NewConn.set_meta("Searchable", false)
			SuccessfulDeadEnds += 1
			
			Spawning = false 
			break  # only one placement per FillDeadEnd() call
		break


# ----------------------------------------
# SPECIAL ROOM PLACEMENT FLAGS
# ----------------------------------------

var SpecialRoomPlacing = false        # True while we're in the middle of placing a special room
var Overlapsspecialroom = false      # Tracks if the special room overlapped something
var ForcePlace = false               # Can be used later to force a room placement
var SpecialRoomObj = null            # Cached instance of the special room being placed
var FillFailStreak := 0
const MaxFillFails := 40             # Safety limit for how many failed attempts we allow
var MainPhaseDone := false           # True when hallway/special room phase is finished


# Returns how much "budget" a room gets based on its depth from STARTID.
# This is a logistic curve, so early rooms get low budget and deeper rooms get more.
func DepthBudgetCurve(Depth:int) -> float:
	var L := 1000    # Asymptote (late game budget ceiling)
	var K := 0.7     # Slope
	var M := 8.0     # Midpoint depth where budget ramps up
	return 12.0 + L / (1.0 + exp(-K * float(Depth - M)))


# Returns the connector's transform RELATIVE to the RoomLayer it belongs to.
func ConnXformRelToRoomlayer(Conn: Node2D) -> Transform2D:
	var Ctrl := Conn.get_parent() # "Control" under the RoomLayer
	# Ctrl.transform is local-to-RoomLayer; Conn.transform is local-to-Control
	return Ctrl.transform * Conn.transform


# Build the world transform for the RoomLayer that makes Conn meet Marker (flipped 180°).
func SolveRoomlayerXform(Marker: Node2D, Conn: Node2D) -> Transform2D:
	var TMarker := Marker.global_transform
	var TConnRel := ConnXformRelToRoomlayer(Conn)
	var R180 := Transform2D(PI, Vector2.ZERO)
	# RoomLayer_world * TConnRel = TMarker * R180
	return TMarker * R180 * TConnRel.affine_inverse()


# Counts how many markers can become dead ends after main generation is done.
func CountDeadEndMarkers() -> int:
	var Count := 0
	for H in get_children():
		if H is Node2D:
			var ControlNode := H.get_node_or_null("RoomLayer/Control")
			if ControlNode:
				for M in ControlNode.get_children():
					# Searchable + not occupied = dead-end candidate
					if M.get_meta("Searchable") == true and M.get_meta("Occupied", false) == false:
						Count += 1
	return Count


# ----------------------------------------
# MAIN ROOM FILL PHASE (HALLWAYS + SPECIAL ROOMS)
# ----------------------------------------

func FillMap() -> bool:
	# Main generator step:
	# Attempts to attach either a hallway segment or a special room
	# to one free connector. Returns true if something was placed this frame.
	Spawning = true
	
	var HallwayDupe = Hallways.duplicate()
	var PlacedSomething := false

	for Hallway in get_children():
		if not (Hallway is Node2D):
			continue

		var ControlNode:= Hallway.get_node("RoomLayer/Control")
		if ControlNode == null:
			continue
	
		# Gather only markers that are free (not occupied, not marked searchable for dead-ends)
		var FreeMarkers: Array[Node2D] = []
		for M in ControlNode.get_children():
			if not M.get_meta("Occupied", false) and not M.get_meta("Searchable", false):
				FreeMarkers.append(M)

		if FreeMarkers.is_empty():
			continue
		
		var Marker: Node2D = FreeMarkers.pick_random()

		# Adjust special room weighting depending on distance from the start room (logic is same in both branches now)
		if SpecialRooms < 10 and (Marker.global_position - $Hallway/RoomLayer.global_position).length() > 5000:
			SpecialRoomWeighting = {"Shop": 10, "TreasureRoom": 35}
		else:
			SpecialRoomWeighting = {"Shop": 10, "TreasureRoom": 35}
	
		# If we previously failed to place a special room due to overlap, try again here
		if Overlapsspecialroom == true and SpecialRoomPlacing == true:
			var NewCtrl = SpecialRoomObj.find_child("RoomLayer").find_child("Control")
			var FreeConns: Array[Node2D] = []
			for C in NewCtrl.get_children():
				if C.get_meta("Occupied") == false:
					FreeConns.append(C)
			if FreeConns.is_empty():
				SpecialRoomObj.queue_free()
				continue

			var NewConn: Node2D = FreeConns.pick_random()
			# Compute transform to glue connectors (180° flip)
			var TMarker := Transform2D(Marker.global_rotation, Marker.global_position)
			var TConn := Transform2D(NewConn.rotation, NewConn.position)
			var R180 := Transform2D(PI, Vector2.ZERO)
			var TRoomlayer := TMarker * R180 * TConn.affine_inverse()
					
			# Collision polygon in world-space
			var LocalPoly: PackedVector2Array = SpecialRoomObj.find_child("RoomLayer").find_child("OverlapPolygon").polygon
			var WorldPoly := XformPoly(TRoomlayer, LocalPoly)

			# Test if special room overlaps anything
			Points = WorldPoly
			Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
			Polygon2Dd.polygon = Points
			Drawable = true
					
			for Placed in Rects:
				if PolysOverlap(Placed, WorldPoly):
					Overlapsspecialroom = true
					break
				Overlapsspecialroom = false

			# If we found a valid spot with no overlap, place the special room
			if Overlapsspecialroom == false:
				SpecialRoomObj.find_child("RoomLayer").global_position = TRoomlayer.origin
				SpecialRoomObj.find_child("RoomLayer").global_rotation = TRoomlayer.get_rotation()
				SpecialRoomObj.scale = Vector2.ONE
						
				# Add to tree and update graph
				add_child(SpecialRoomObj)
				var SRCRoomLayer := Hallway.find_child("RoomLayer")
				var SRCID = AddRoom(SRCRoomLayer)    
				var NewRoomLayer = SpecialRoomObj.find_child("RoomLayer")
				var NewID = AddRoom(NewRoomLayer)
				Connect(SRCID, NewID)
				CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
				Rects.append(WorldPoly)
				SuccessfulRooms += 1
						
				Marker.set_meta("Occupied", true)
				Marker.set_meta("Searchable", false)
				NewConn.set_meta("Occupied", true)
				NewConn.set_meta("Searchable", false)
				Spawning = false
					
				SpecialRoomPlacing = false
				Overlapsspecialroom = false 
				PlacedSomething = true

		# Try to spawn a new special room if we are below the cap and not currently placing one
		if SpecialRooms < 50 and Overlapsspecialroom == false and SpecialRoomPlacing == false:
			var SpecialRoomDupe = SpecialRoom.duplicate()
			var RoomPack = SpecialRoomDupe.pick_random()
			SpecialRoomObj = RoomPack.instantiate() as Node2D
			var Weighting = SpecialRoomWeighting[SpecialRoomObj.name]
			
			# Random roll based on weighting
			if randi() % Weighting == 1:
				# Extra roll to maybe upgrade a Shop into a CardShop
				if SpecialRoomObj.name == "Shop":
					var Chance = randi() % 5
					if Chance == 1:
						SpecialRoomObj = CardShop.instantiate() as Node2D
						
				SpecialRoomPlacing = true
		
				var NewCtrl2 = SpecialRoomObj.find_child("RoomLayer").find_child("Control")
				var FreeConns2: Array[Node2D] = []
				for C in NewCtrl2.get_children():
					if C.get_meta("Occupied") == false:
						FreeConns2.append(C)
				if FreeConns2.is_empty():
					SpecialRoomObj.queue_free()
					continue

				var NewConn2: Node2D = FreeConns2.pick_random()
				# Compute transform to glue connectors (180° flip)
				var TMarker2 := Transform2D(Marker.global_rotation, Marker.global_position)	
				var TConn2 := Transform2D(NewConn2.rotation, NewConn2.position)
				var R180_2 := Transform2D(PI, Vector2.ZERO)
				var TRoomlayer2 := TMarker2 * R180_2 * TConn2.affine_inverse()
				# Collision polygon in world-space
				var LocalPoly2: PackedVector2Array = SpecialRoomObj.find_child("OverlapPolygon").polygon
				var WorldPoly2 := XformPoly(TRoomlayer2, LocalPoly2)

				# Overlap test against all placed polygons
				Points = WorldPoly2
				Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
				Polygon2Dd.polygon = Points
				Drawable = true
					
				for Placed2 in Rects:
					if PolysOverlap(Placed2, WorldPoly2):
						Overlapsspecialroom = true
						break

				if Overlapsspecialroom:
					continue

				# No overlap -> place the special room now
				SpecialRoomObj.find_child("RoomLayer").global_position = TRoomlayer2.origin
				SpecialRoomObj.find_child("RoomLayer").global_rotation = TRoomlayer2.get_rotation()
				SpecialRoomObj.scale = Vector2.ONE
			
				# Add to tree and update graph data
				add_child(SpecialRoomObj)
				var SRCRoomLayer2 := Hallway.find_child("RoomLayer")
				var SRCID2 = AddRoom(SRCRoomLayer2)    
				var NewRoomLayer2 = SpecialRoomObj.find_child("RoomLayer")
				var NewID2 = AddRoom(NewRoomLayer2)
				Connect(SRCID2, NewID2)
				CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
				Rects.append(WorldPoly2)
				SuccessfulRooms += 1
					
				Marker.set_meta("Occupied", true)
				Marker.set_meta("Searchable", false)
				NewConn2.set_meta("Occupied", true)
				NewConn2.set_meta("Searchable", false)
				Spawning = false
			
				SpecialRoomPlacing = false
				Overlapsspecialroom = false 
				PlacedSomething = true
				break  # only one placement per FillMap() call
		
		# If we aren't placing a special room, try to place a normal hallway room instead
		if SpecialRoomPlacing == false:
			while HallwayDupe.size() > 0:
				await get_tree().physics_frame
				
				var RoomPacked2: PackedScene = HallwayDupe.pick_random()
				var Obj2 := RoomPacked2.instantiate() as Node2D
			
				var NewCtrl3 := Obj2.find_child("RoomLayer").find_child("Control")
				var FreeConns3: Array[Node2D] = []
				for C3 in NewCtrl3.get_children():
					# Default false so unset meta is treated as "free"
					if C3.get_meta("Occupied", false) == false:
						FreeConns3.append(C3)

				if FreeConns3.is_empty():
					# If this hallway type has no free connectors, discard it
					Obj2.queue_free()
					HallwayDupe.erase(RoomPacked2)  # remove unusable type
					continue

				var NewConn3: Node2D = FreeConns3.pick_random()
				# Compute transform to glue connectors (180° flip)
				var TMarker3 := Transform2D(Marker.global_rotation, Marker.global_position)
				var TConn3 := Transform2D(NewConn3.rotation, NewConn3.position)
				var R180_3 := Transform2D(PI, Vector2.ZERO)
				var TRoomlayer3 := TMarker3 * R180_3 * TConn3.affine_inverse()
				# Collision polygon in world-space
				var LocalPoly3 = Obj2.get_node("RoomLayer").get_node("OverlapPolygon").polygon
				var WorldPoly3 := XformPoly(TRoomlayer3, LocalPoly3)

				# Check overlap with existing rooms
				var Overlaps2 := false
				Points = WorldPoly3
				Polygon2Dd.reparent(Hallway.find_child("RoomLayer"))
				Polygon2Dd.polygon = Points
				Drawable = true
				
				for Placed3 in Rects:
					if PolysOverlap(Placed3, WorldPoly3):
						Overlaps2 = true
						break

				if Overlaps2:
					# If it overlaps, discard this hallway type and try another
					Obj2.queue_free()
					HallwayDupe.erase(RoomPacked2)
					if HallwayDupe.is_empty():
						# If no hallway can be placed at this marker, mark it for the dead-end phase
						Marker.set_meta("Searchable", true)  
					continue

				# If no overlap, we can finally place this hallway room
				Obj2.find_child("RoomLayer").global_position = TRoomlayer3.origin
				Obj2.find_child("RoomLayer").global_rotation = TRoomlayer3.get_rotation()
				Obj2.scale = Vector2.ONE
			
				# Add to tree and update graph
				add_child(Obj2)
				var SRCRoomLayer3 := Hallway.find_child("RoomLayer")
				var SRCID3 = AddRoom(SRCRoomLayer3)    
				var NewRoomLayer3 := Obj2.find_child("RoomLayer")
				var NewID3 = AddRoom(NewRoomLayer3)
				Connect(SRCID3, NewID3)
				CollisionShapeRects.append(SpecialRoomObj.find_child("RoomLayer"))
				Rects.append(WorldPoly3)
				SuccessfulRooms += 1

				# Mark connectors as used
				Marker.set_meta("Occupied", true)
				Marker.set_meta("Searchable", false)
				NewConn3.set_meta("Occupied", true)
				NewConn3.set_meta("Searchable", false)
				Spawning = false 
				PlacedSomething = true
				break  # only one placement per FillMap() call

		if PlacedSomething == true:
			# Once we have successfully placed something this frame,
			# break out so _process can yield and we don't lock up.
			break
			
	return PlacedSomething


# ----------------------------------------
# GLOBAL GENERATION STATE
# ----------------------------------------

var Attempts = 0
var MaxAttempts = 1000   # Safety limit on how many failed placement attempts we allow


# Converts from world-space position to tilemap cell coords
func ToCell(WorldPos: Vector2) -> Vector2i:
	return Layer.local_to_map(Layer.to_local(WorldPos))


# Extra debug/generation state variables
var Onlyonce = false
var FreeMarkersfinal: Array[Node2D] = []
var CheckingMarker = null
var LoopLayer = null
var AId = null
var BId = null
var Region = null
@export var SuccessfulDeadEnds = 0
var LastRoom = 0


func _process(Delta: float) -> void:
	# The generator runs in two phases:
	# 1. MainPhase: place hallways and special rooms.
	# 2. DeadEnd phase: fill any leftover connectors with dead-ends.

	if MainPhaseDone:
		# Once main phase is done, count how many dead-end markers exist (only once)
		if DeadEndSearches == 0:
			DeadEndSearches = CountDeadEndMarkers()
		# Keep filling dead ends until we've patched them all
		if SuccessfulDeadEnds < DeadEndSearches:
			FillDeadEnd()
			print("fewfiuwgfuiew")
		else:
			# When everything is filled, finalise the dungeon and stop processing
			FinalizeDungeon()
			set_process(false)
		return

	# Phase 1: main room filling
	# Procedural generation hard cap so the map doesn't grow forever
	if SuccessfulRooms < 100:
		# If somehow there are no free connectors but we haven't reached the cap,
		# mark main phase as done and restart (acts as a safety reset).
		if not HasAnyFreeConnector():
			MainPhaseDone = true
			get_tree().reload_current_scene()
			
		var Placed = await FillMap()
		if Placed == false:
			Attempts += 1
		
		# If we failed to place anything too many times in a row, reload the scene
		if Attempts >= MaxAttempts:
			get_tree().reload_current_scene()
	else:
		# If we hit the cap, move into the dead-end phase
		MainPhaseDone = true


# Returns true if there is at least one connector in the dungeon
# that is free (not occupied and not marked as a dead-end candidate).
func HasAnyFreeConnector() -> bool:
	for H in get_children():
		if H is Node2D:
			var ControlNode := H.get_node_or_null("RoomLayer/Control")
			if ControlNode:
				for M in ControlNode.get_children():
					if M.get_meta("Occupied") == false and M.get_meta("Searchable") == false: 
						return true
	return false
