extends Node2D
@export var Enabled  = false
func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.has_meta("Health") && Enabled == true:
		body.set_meta("Health",body.get_meta("Health")-100)
	
