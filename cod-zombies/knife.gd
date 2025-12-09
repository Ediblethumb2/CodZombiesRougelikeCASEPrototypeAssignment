extends Node2D
@export var Enabled  = false
@export var Cooldown = 0.6
@export var Damage = 100

var AlreadyHit = []
var OnlyOnce = false 
func _physics_process(delta: float) -> void:
	if Enabled == true && OnlyOnce == false:
		AlreadyHit.clear()
		OnlyOnce = true
	if OnlyOnce == true && Enabled == false:
		OnlyOnce = false
	if Enabled == true:
		for area2d in $Sprite2D/Area2D.get_overlapping_areas():
			
			if area2d.name == "Hitbox":
			
				
				if area2d.get_parent().get("Health") && Enabled == true && AlreadyHit.find(area2d.get_parent()) == -1 :
					area2d.get_parent().Health -= Damage
					print(AlreadyHit.find(area2d.get_parent()) )
					AlreadyHit.append(area2d.get_parent())

func _on_area_2d_area_entered(area: Area2D) -> void:
	
	if area.name == "Hitbox":
		pass
	


func _on_area_2d_area_exited(area: Area2D) -> void:
	pass # Replace with function body.
