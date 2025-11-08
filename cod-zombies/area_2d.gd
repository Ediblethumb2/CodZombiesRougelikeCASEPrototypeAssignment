extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		body.set_meta("NoFog",true)
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
		tween.tween_property(get_parent().find_child("Polygon2D"),"color:a" ,0, 0.3)
		tween.play()
		



func _on_body_exited(body: Node2D) -> void:
	body.set_meta("NoFog",false)


		
