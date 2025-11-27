extends Node2D
@export var Enabled  = false
@export var Cooldown = 1
@export var Damage = 100
func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.has_meta("Health") && Enabled == true:
		body.set_meta("Health",body.get_meta("Health")-	Damage)
	
