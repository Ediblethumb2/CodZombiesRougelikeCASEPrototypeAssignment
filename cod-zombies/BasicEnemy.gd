extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var Goal: Node = null
@export var Spawn: Node = null
@export var  MovementSpeed = 400
func _ready():
	pass
var Direction = Vector2(0,0)
var State = ""
func _physics_process(delta: float) -> void:
	if get_meta("Health") <= 0:
		queue_free() 
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
	if body.is_class("CharacterBody2D"):
		Goal = body
	


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_class("CharacterBody2D"):
		pass
		#Goal = Spawn
