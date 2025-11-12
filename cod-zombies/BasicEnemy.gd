extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var Goal: Node = null
@export var Spawn: Node = null
@export var  MovementSpeed = 400
func _ready():
	set_physics_process(false)
var Direction = Vector2(0,0)
var State = ""
func _physics_process(delta: float) -> void:
	
	if get_meta("Health") <= 0:
		queue_free() 
	if get_meta("Fast") == true:
		MovementSpeed = 800
		$RichTextLabel.text = "Fast"
	if get_meta("Tanky") == true:
		set_meta("Health",160.0) 
		
		$RichTextLabel.text = "Tank"
	if !$NavigationAgent2D.is_target_reached():
	
		var NavPointDirection = to_local($NavigationAgent2D.get_next_path_position()).normalized()
		if NavPointDirection.x > NavPointDirection.y:
			if NavPointDirection.x < 0:
				Direction = Vector2(-1,0)
			if NavPointDirection.x > 0:
				Direction = Vector2(1,0)
		if NavPointDirection.y > NavPointDirection.x:
			if NavPointDirection.y >0:
				Direction = Vector2(0,1)
			if NavPointDirection.y < 0:
				Direction = Vector2(0,-1)
		State = "Run"
		if State == "Run" && Direction == Vector2(-1,0):
			$AnimatedSprite2D.play("RunLR")
			$AnimatedSprite2D.flip_h = false
		if State == "Run" && Direction == Vector2(-1,0):
			$AnimatedSprite2D.play("RunLR")
			$AnimatedSprite2D.flip_h = true
		if State == "Run" && Direction == Vector2(0,-1):
			$AnimatedSprite2D.play("RunU")
		if State == "Run" && Direction == Vector2(0,1):
			$AnimatedSprite2D.play("RunD")
		
		
			
				
			
		velocity = NavPointDirection * MovementSpeed 
		
		move_and_slide()
	


func _on_timer_timeout() -> void:
		
		
	$NavigationAgent2D.target_position  = Goal.global_position


func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.name == "Player":
		Goal = body
		print("wfwfe")
		
		set_physics_process(true)
		$Timer.autostart = true
		$Timer.start()
	


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		print(Spawn)
		Goal = Spawn
		#Goal = Spawn
