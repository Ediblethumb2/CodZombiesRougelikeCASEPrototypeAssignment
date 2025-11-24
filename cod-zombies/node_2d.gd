extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	global_position += Vector2(get_meta("DirX"),get_meta("DirY"))* get_meta("Speed")
	print("wfhwiywioef")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player" :
		queue_free()
	
	if body.has_meta("Health"):
		body.set_meta("Health",body.get_meta("Health")- 10)
		
