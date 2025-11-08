extends Node2D

@onready var layer: TileMapLayer = $RoomLayer
const SRC := 0              # <-- set to your actual TileSet source id
const ATLAS := Vector2i(3,3) # <-- atlas coords inside that source

var grid: AStarGrid2D
var cells: Array[Vector2i]    # path in MAP COORDS (no pixels)

func _ready() -> void:
	# --- Build grid (grid coords, not pixels) ---
	grid = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(128, 128))
	grid.cell_size = Vector2(64, 64)              # only affects debug scale / world conversion
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	layer.has
	grid.set_point_solid(Vector2i(1, 1), true)

	# Array[Vector2i] (grid coords)
	cells = grid.get_id_path(Vector2i(0, 0), Vector2i(40, 20))

	# --- Paint those exact cells into the TileMapLayer ---
	# If your grid.region starts at (0,0), do NOT add anything. If not, add region.position.
	for c in cells:
		layer.set_cell(c, SRC, ATLAS)
	# Force a visual refresh in case your layer is large
	layer.notify_runtime_tile_data_update()

	# Debug: print first 10 cells so you see it’s not a single straight line
	print("First few painted cells: ", cells.slice(0, min(10, cells.size())))

	_draw() # draw the overlay

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
