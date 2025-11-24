extends CharacterBody2D
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var Goal: Node =null
@export var Spawn: Node = null
@export var  MovementSpeed = 400
var ViewAngleDegrees = 90
var TILE_SIZE = 64
@export var KillMoney = 5
@export var BaseHealth: float = 100.0  
@export var view_distance = 6 * TILE_SIZE
var Debounce = false
func _ready():
	#set_physics_process(false)
	Goal = get_tree().get_current_scene().find_child("Player")
	HealthMultiplier()
	print("hEALTH IS " + str(get_meta("Health")))
	
var Direction = Vector2	(0,0)
var State = ""
var OnlyOnce = false
var Player = null
func can_see_player() -> bool:
	if Goal == null:
		return false

	# Vector from enemy to player
	var to_player: Vector2 = Goal.global_position - global_position
	var dist := to_player.length()
	if dist > view_distance:
		return false  # too far
	

	var dir_to_player := to_player / dist  # normalized

	# Enemy facing direction:
	var facing: Vector2
	if Direction != Vector2.ZERO:
		facing = Direction.normalized()
	else:
		facing = Vector2.DOWN  # default if standing still

	# Angle check (cone)
	var max_angle := deg_to_rad(ViewAngleDegrees) * 0.5
	var angle_to_player := facing.angle_to(dir_to_player)
	if abs(angle_to_player) > max_angle:
		return false  # outside cone

	# Line of sight check (raycast)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, Goal.global_position)
	query.exclude = [self]  # don't hit yourself

	var hit = space_state.intersect_ray(query)
	if hit.size() > 0 and hit.collider != Goal:
		# Something else (wall, obstacle) is in the way
		return false

	return true
var Chasing = false
var OnlyOnceTimer = false
var AttackingCooldown = false
var PlayerEntered = false
func HealthMultiplier():
	if get_meta("Depth") <= 9:
		set_meta("Health",BaseHealth + (100 * get_meta("Depth")))
	else: 
		var hp = 1000
		for i in range(10,get_meta("Depth")):
			hp *= 1.1
			set_meta("Health",hp)
	
	
		
	
func _physics_process(delta: float) -> void:
	if Goal == null:
		return

	var dist = (global_position - Goal.global_position).length()
	var can_see = dist < 300 and can_see_player()
	if Chasing == true && dist > 500:
		Chasing = false
		print("fALSE")
	if can_see || Chasing == true:
		if not OnlyOnceTimer:
			OnlyOnceTimer = true
			$Timer.autostart = true
			$Timer.start()
			print("Started chasing")
			Chasing = true

		# --- MOVEMENT SHOULD ALWAYS RUN WHILE WE SEE THE PLAYER ---
		if get_meta("Health") <= 0:
			queue_free()
			Player.Dosh += KillMoney

		if get_meta("Fast") == true and OnlyOnce == false:
			OnlyOnce = true
			MovementSpeed = 800
			$RichTextLabel.text = "Fast"
			KillMoney *= 2

		if get_meta("Tanky") == true and OnlyOnce == false:
			set_meta("Health", get_meta("Health") * 2)
			OnlyOnce = true
			$RichTextLabel.text = "Tank"
			KillMoney *= 5

		if not $NavigationAgent2D.is_target_reached():
			var NavPointDirection = ($NavigationAgent2D.get_next_path_position() - global_position).normalized()

			Direction = Vector2.ZERO
			if abs(NavPointDirection.x) > abs(NavPointDirection.y):
				Direction = Vector2(sign(NavPointDirection.x), 0)
			else:
				Direction = Vector2(0, sign(NavPointDirection.y))
			
			if PlayerEntered == true&& AttackingCooldown == false:
				if Direction == Vector2(-1, 0):
					$AnimatedSprite2D.play("AttackLR")
					$AnimatedSprite2D.flip_h = false
				elif Direction == Vector2(1, 0):
					$AnimatedSprite2D.play("AttackLR")
					$AnimatedSprite2D.flip_h = true
				elif Direction == Vector2(0, -1):
					$AnimatedSprite2D.play("AttackU")
				elif Direction == Vector2(0, 1):
					$AnimatedSprite2D.play("AttackD")
				State = "Attacking"
		
			if State != "Attacking":
				State = "Run"
				if Direction == Vector2(-1, 0):
					$AnimatedSprite2D.play("RunLR")
					$AnimatedSprite2D.flip_h = false
				elif Direction == Vector2(1, 0):
					$AnimatedSprite2D.play("RunLR")
					$AnimatedSprite2D.flip_h = true
				elif Direction == Vector2(0, -1):
					$AnimatedSprite2D.play("RunU")
				elif Direction == Vector2(0, 1):
					$AnimatedSprite2D.play("RunD")
			if AttackingCooldown == true && Debounce == false:
				$AttackTimer.start()
				Debounce = true
			if State != "Attacking":
				velocity = NavPointDirection * MovementSpeed
				move_and_slide()

			if State == "Attacking":
				velocity = NavPointDirection * MovementSpeed
				move_and_slide()
				
	else:
		# Lost sight / out of range -> stop timer + reset
		if OnlyOnceTimer && Chasing == false:
		
			$Timer.autostart = false
			$Timer.stop()
			OnlyOnceTimer = false
			velocity = Vector2.ZERO

		
		


func _on_timer_timeout() -> void:
		
		
	$NavigationAgent2D.target_position  = Goal.global_position


func _on_area_2d_body_entered(body: Node2D) -> void:
	
	
	if body.name == "Player":
		Goal = body
	
		PlayerEntered = true
		Player =  body
		
		#set_physics_process(true)
		pass
	


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		PlayerEntered = false
	
		#set_physics_process(false)

		#Goal = Spawn


func _on_animated_sprite_2d_frame_changed() -> void:
	
	if State == "Attacking" && $AnimatedSprite2D.frame == 4:
		if PlayerEntered == true:
			Goal.set_meta("Health",Goal.get_meta("Health")-10)


		
		
		
		
		


func _on_attack_timer_timeout() -> void:
	AttackingCooldown = false
	Debounce = false
	print("qfbowefwef")
	pass
	
		
		
	


func _on_animated_sprite_2d_animation_finished() -> void:
	if State == "Attacking":
		State = "Run"
		AttackingCooldown = true
