extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	$BarFrame/ProgressBar.value  =get_tree().current_scene.SuccessfulRooms
	var tween = get_tree().create_tween()
	
	if get_tree().current_scene.SuccessfulRooms  >= 100:
	
		tween.tween_property(self, "modulate:a", 0,1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property($BarFrame	, "modulate:a", 0,1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		
		
	
