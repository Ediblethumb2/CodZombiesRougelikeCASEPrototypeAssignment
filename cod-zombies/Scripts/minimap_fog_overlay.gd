extends Node2D
@export var question_font: Font
@export var font_size := 24
@export var fill_color := Color(0, 0, 0, 0.9)   # mask alpha
@export var border_width := 2.0

# Keep this overlay above the map inside the SubViewport.
func _ready() -> void:
	z_index = 9999
	z_as_relative = false

func _centroid(pts: PackedVector2Array) -> Vector2:
	if pts.is_empty(): return Vector2.ZERO
	var c := Vector2.ZERO
	for p in pts: c += p
	return c / float(pts.size())

class RoomMask:
	var id: int
	var pts: PackedVector2Array        # overlay-local points (cached)
	var centroid: Vector2
	var alpha: float = 1
	var discovered: bool = false

var _rooms: Array[RoomMask] = []
var _tw_by_id := {}

# Provide your Polygon2D or CollisionPolygon2D nodes here after generation.
func set_from_polygon_nodes(nodes) -> void:
	_rooms.clear()
	_tw_by_id.clear()
	print("aaawefwefefa")
	var rid := 0
	for n in nodes:
		var poly = n
		if poly.is_empty():
			continue

		# Convert each vertex to THIS overlay's local space (so drawing aligns with the minimap camera).
		var pts := PackedVector2Array()
		for p in poly:
			pts.append(to_local(p))

		var rm := RoomMask.new()
		rm.id = rid
		rm.pts = pts
		rm.centroid = _centroid(pts)
		rm.alpha = fill_color.a
		rm.discovered = false
		_rooms.append(rm)

		# Store id back on the room if you like:
		rid += 1

	queue_redraw()
func mark_discovered(room_id: int, discovered := true, dur := 0.25) -> void:
	for r in _rooms:
		if r.id != room_id: continue
		if r.discovered == discovered: return
		r.discovered = discovered

		if _tw_by_id.has(room_id) and _tw_by_id[room_id].is_running():
			_tw_by_id[room_id].kill()

			var from := r.alpha
			var to: float
			if discovered:
				to = 0
			else:
				to = fill_color.a
			
			
			var tw := get_tree().create_tween()
			_tw_by_id[room_id] = tw
			tw.tween_method(
				func(a:float) -> void:
					r.alpha = a
					queue_redraw()
					,
					from,to,dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				
				
				
			
			return

func _draw() -> void:
	for r in _rooms:
		
		if r.discovered and r.alpha <= 0.001:
			continue
		
		var col := Color(0,0,0, r.alpha)
		
		# Draw the polygon mask. Works for convex/concave (no holes).
		draw_colored_polygon(r.pts, col, PackedVector2Array(), null)
	
		# Draw a centered "?"
		if question_font and r.alpha > 0.05:
			var q := "?"
			var sz := question_font.get_string_size(q, font_size)
			var pos := r.centroid - sz * 0.5
			draw_string(question_font, pos, q, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1,1,1,min(1.0, r.alpha + 0.05)))
