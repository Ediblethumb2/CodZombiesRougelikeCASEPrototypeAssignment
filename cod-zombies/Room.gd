extends Node2D
@export var A := TileMapLayer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if A.has_meta("Budget"):
		A.find_child("RichTextLabel").text = str($RoomLayer.get_meta("Budget"))
		set_process(false)
		
