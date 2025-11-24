# RoomCamera2D.gd
class_name RoomCamera2D
extends Camera2D

@export var target: Node2D   # drag your Player here in the inspector

@export var LimitsRect: Rect2 = Rect2()
@export var HasLimits: bool = false

func _ready() -> void:
	make_current()
