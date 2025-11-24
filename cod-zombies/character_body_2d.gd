extends CharacterBody2D


var  Speed = 600.0
const JumpVelocity = -400.0
var Direction = Vector2.ZERO
var Bullet = preload("res://Bullet.tscn")
var target
var shot = false

@export var Dosh = 1000
@export var Equipped = 	""
var LastEquipped = ""
var WeaponsDict = {"AssaultRifle":AssaultRifle,"Pistol":Pistol}
var Inventory = []

func set_limits(rect: Rect2):
	$Camera2D.limit_left   = int(rect.position.x)
	$Camera2D.limit_top    = int(rect.position.y)
	$Camera2D.limit_right  = int(rect.position.x + rect.size.x)
	$Camera2D.limit_bottom = int(rect.position.y + rect.size.y)

func Fog():
	
	if get_meta("NoFog") != PreviousNoFog:
		
		if get_meta("NoFog") == true:
			
			for i in range(0,11,1):
				
				var i2:float = float(i)/10
				
				
				$CanvasLayer/FlashlightRect.set_instance_shader_parameter("ambient",i2)
				await get_tree().process_frame
			PreviousNoFog = true
		if get_meta("NoFog") == false:
			for i in range(11,-1,-1):
				var i2:float = float(i)/10
				print(i2)
				$CanvasLayer/FlashlightRect.set_instance_shader_parameter("ambient",i2)
				await get_tree().process_frame
			PreviousNoFog = false
	

var SlidingOnce = false
var SlideCooldown = false
var SlotUsing = 0 
func AssaultRifle():

	var gun = find_child(Equipped)
	gun.Enabled = true
	gun.find_child("Gun").visible = true
func Pistol():
	var gun = find_child(Equipped)
	gun.Enabled = true
	gun.find_child("Gun").visible = true 
var  sliding = false
func _swing_knife() -> void:
	Knife.Enabled = true
	Knife.visible = true

	# Direction from player/knife to mouse
	var dir: Vector2 = get_global_mouse_position() - Knife.global_position
	var angle_rad: float = dir.angle()
	var angle_deg: float = rad_to_deg(angle_rad)


	var start_angle: float = angle_deg - 90.0
	var end_angle: float = angle_deg + 90.0



	# Start the knife at the beginning of the arc
	Knife.rotation_degrees = start_angle

	tween = create_tween()
	tween.tween_property(Knife, "rotation_degrees", end_angle, 0.2)

	tween.finished.connect(func ():
		Knife.Enabled = false
		Knife.visible = false
	)
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Melee")  && not Knife.Enabled :
		_swing_knife()
		print("fwiufuiwfwiuefwiufiwfyiuwefyv")
		
		
		


		
	
		
		
		
		
		
		
		
	if event.is_action("PrimaryEquip") && Inventory.size() > 0:
		if Equipped != "" && Equipped != Inventory[0]:
			find_child(Equipped).Enabled = false 
			find_child(Equipped).find_child("Gun").visible = false	
		Equipped = Inventory[0]
		SlotUsing = 0
	if event.is_action("Slide") && sliding == false && SlideCooldown == false && input_direction.length() > 0 :

		sliding = true
		SlideCooldown  = true
		SlideCOoldownDelay(5)

				
		
	if get_meta("Shop") == true && event.is_action_pressed("Interact") :
			var mouse_pos: Vector2 = get_global_mouse_position()
			var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

			var params := PhysicsPointQueryParameters2D.new()
			params.position = mouse_pos
			params.collision_mask = collision_mask          # or 0xFFFFFFFF to hit everything
			params.collide_with_areas = true
			params.collide_with_bodies = true

			var results: Array = space_state.intersect_point(params, 32)
			for hit in results:
				print(hit.collider.get_parent())
				if hit.collider.get_parent().get("Cost"):
					if Dosh >= hit.collider.get_parent().Cost:
						Dosh -= hit.collider.get_parent().Cost
					
						print("fiwefiweg")
						if Inventory.size() == 2:
							
							find_child(Equipped).Enabled = false
							find_child(Equipped).find_child("Gun").visible - false
							Inventory[SlotUsing] = hit.collider.get_parent().GunName
							Equipped = hit.collider.get_parent().GunName
							find_child(Equipped).Enabled = true
							find_child(Equipped).find_child("Gun").visible = true
						else:
							Inventory.append(hit.collider.get_parent().GunName)
				

				
				
				
			
		
		
	if event.is_action_released("Slide"):
	
		sliding = false
		SlidingOnce = false
		
	if event.is_action("SecondaryEquip"):
		if Inventory.size() >=2:
			if Equipped != "" && Equipped != Inventory[1]:
				find_child(Equipped).Enabled = false 
				find_child(Equipped).find_child("Gun").visible = false
			SlotUsing = 1
				
			Equipped = Inventory[1]
	

func on_tween_finished():
	sliding = false 
	print("done")
var PreviousNoFog = false
func SetAmount(v:float):
	Speed = v
var tween = null
var Knife = null
@export var SelectingGun = null
func _ready() -> void:
	
	tween = create_tween()
	Knife = find_child("Knife")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_viewport().canvas_cull_mask = 1 << 0
	#get_viewport().canvas_cull_mask = 1 << 0

var input_direction = Vector2.ZERO
var SlideTween = null
var sliding_prev := false
func SlideCOoldownDelay(timeout):
	await get_tree().create_timer(timeout).timeout
	SlideCooldown = false
var gun = "a"

func _physics_process(delta: float) -> void:

			
			

		

	$CanvasLayer/SubViewportContainer/SubViewport.world_2d = get_tree().root.world_2d
	$CanvasLayer/SubViewportContainer/SubViewport/Camera2D.global_position = global_position

	Fog()
	var current_fps = Engine.get_frames_per_second()

	#$CanvasLayer/RichTextLabel.text = "FPS: " + str(current_fps)
	$CanvasLayer/RichTextLabel.text = "Health: " + str(get_meta("Health"))
	$CanvasLayer/RichTextLabel2.text = "Dosh: " + str(Dosh)
	if Equipped != LastEquipped:
		LastEquipped = Equipped
		WeaponsDict[Equipped].call()

	if Equipped!= "" :
		if find_child(Equipped):
			gun = find_child(Equipped)
	if sliding == false:
		input_direction = Vector2.ZERO
	if Equipped != "":
		# Avoid incremental rotate drift:
		gun.rotation = (get_global_mouse_position() - gun.global_position).angle()

	# --- read input (your existing code) ---
	if sliding and not SlidingOnce:
		SlidingOnce = true
		if Input.is_action_pressed("W"): input_direction.y -= 1
		if Input.is_action_pressed("S"): input_direction.y += 1
		if Input.is_action_pressed("A"): input_direction.x -= 1
		if Input.is_action_pressed("D"): input_direction.x += 1
	if not sliding:
		if Input.is_action_pressed("W"): input_direction.y -= 1
		if Input.is_action_pressed("S"): input_direction.y += 1
		if Input.is_action_pressed("A"): input_direction.x -= 1
		if Input.is_action_pressed("D"): input_direction.x += 1

	input_direction.x = clamp(input_direction.x, -1, 1)
	input_direction.y = clamp(input_direction.y, -1, 1)
	Direction = input_direction.normalized()

	# --- only (re)create tween when the state flips ---
	if sliding != sliding_prev:
		sliding_prev = sliding
		
		if SlideTween: SlideTween.kill()
		SlideTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		# Godot 4 signal syntax:
	
		if sliding:
			
			SlideTween.tween_property(self, "Speed", 1200.0, 1)
			
			
		else:
			SlideTween.tween_property(self, "Speed", 600.0, 1)
		
	if Speed  == 1200:
		
		sliding = false 
	
		
			

	# --- use current Speed to move ---
	velocity.x = move_toward(velocity.x,Speed * input_direction.x,50)
	velocity.y = move_toward(velocity.y,Speed * input_direction.y,50)

	move_and_slide()

	
	
	
