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
var ShopDict = {"AssaultRifle":AssaultRifleInfo,"Pistol":PistolInfo,"CooldownCard":CooldownInfo}
func CooldownInfo(Cost):
	$CanvasLayer/Description/Frame/Name.text = "CooldownCard"
	$CanvasLayer/Description/Frame/Description.text = ":o"
	$CanvasLayer/Description/Frame/Sprite2D.texture = load("res://Gun,CardSprites/02_kerenel_Cards.png")	
	$CanvasLayer/Description/Frame/Cost.text = "$" + str(Cost)
	ShowFrame($CanvasLayer/Description)
	
	
func PistolInfo(Cost):
	$CanvasLayer/Description/Frame/Name.text = "Pistol"
	$CanvasLayer/Description/Frame/Description.text = "ItsAight"
	$CanvasLayer/Description/Frame/Sprite2D.texture = load("res://Gun,CardSprites/Pistol.png")	
	$CanvasLayer/Description/Frame/Cost.text = "$" + str(Cost)
	ShowFrame($CanvasLayer/Description)
	
func ShowFrame(frame: Control) -> void:
	frame.visible = true

	# Target position = where it should sit normally
	var target_pos: Vector2 = FrameBasePos

	# Start position = off-screen to the right
	var start_pos := target_pos + Vector2(400, 0)
	frame.position = start_pos

	# Start fully transparent
	var start_modulate := frame.modulate
	start_modulate.a = 0.0
	frame.modulate = start_modulate

	var tween := get_tree().create_tween()
	tween.tween_property(frame, "position", target_pos, 0.35)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(frame, "modulate:a", 1.0, 0.35)
	print("ShowFrame:", frame.name, "visible:", frame.visible, "alpha:", frame.modulate.a)


func hide_description_frame() -> void:
	var frame := $CanvasLayer/Description
	if !frame.visible:
		return

	var end_pos = frame.position + Vector2(400, 0)

	var tween := get_tree().create_tween()
	tween.tween_property(frame, "position", end_pos, 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	tween.parallel().tween_property(frame, "modulate:a", 0.0, 0.25)
	# optional: tween.tween_callback(Callable(frame, "hide"))
func AssaultRifleInfo(Cost):
	$CanvasLayer/Description/Frame/Name.text = "AssaultRifle"
	$CanvasLayer/Description/Frame/Description.text = "Best gun"
	$CanvasLayer/Description/Frame/Sprite2D.texture = load("res://Gun,CardSprites/AK-removebg-preview.png")	
	$CanvasLayer/Description/Frame/Cost.text = "$" + str(Cost)
	ShowFrame($CanvasLayer/Description)
	
	
	
	
func CooldownCard():
	pass
var CardDict = {"CooldownCard":CooldownCard}
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
var OldMouseObject = null
var NewMouseObject = null
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
			params.collision_mask = 1 << 7        
			params.collide_with_areas = true
			#ShopDict[hit.collider.get_parent().name]
			var results: Array = space_state.intersect_point(params, 1)
			for hit in results:
				
				if hit.collider.get_parent().get("Cost"):
					if Dosh >= hit.collider.get_parent().Cost:
						Dosh -= hit.collider.get_parent().Cost
					
					
						if Inventory.size() == 2:
							
							find_child(Equipped).Enabled = false
							find_child(Equipped).find_child("Gun").visible = false
							Inventory[SlotUsing] = hit.collider.get_parent().GunName
							Equipped = hit.collider.get_parent().GunName
							find_child(Equipped).Enabled = true
							find_child(Equipped).find_child("Gun").visible = true
						else:
							Inventory.append(hit.collider.get_parent().GunName)
						hit.collider.get_parent().queue_free()
				

				
				
				
			
		
		
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
var FrameBasePos = null
func _ready() -> void:
	
	tween = create_tween()
	Knife = find_child("Knife")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_viewport().canvas_cull_mask = 1 << 0
	FrameBasePos = $CanvasLayer/Description/Frame.position
	$CanvasLayer/Description.hide()
	#get_viewport().canvas_cull_mask = 1 << 0

var input_direction = Vector2.ZERO
var SlideTween = null
var sliding_prev := false
func SlideCOoldownDelay(timeout):
	await get_tree().create_timer(timeout).timeout
	SlideCooldown = false
var gun = "a"

func _physics_process(delta: float) -> void:

	if get_meta("Shop") == false && $CanvasLayer/Description.visible == true:
		hide_description_frame()
		
		
			

		

	$CanvasLayer/SubViewportContainer/SubViewport.world_2d = get_tree().root.world_2d
	$CanvasLayer/SubViewportContainer/SubViewport/Camera2D.global_position = global_position
	if get_meta("Shop") :
		var mouse_pos: Vector2 = get_global_mouse_position()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collision_mask = 1 << 7
	params.collide_with_areas = true
	params.collide_with_bodies = true

	var results: Array = space_state.intersect_point(params, 1)

	var hovered = null
	if results.size() > 0:
		var hit = results[0]                 
		hovered = hit.collider.get_parent()     
	if hovered != NewMouseObject:
		OldMouseObject = NewMouseObject
		NewMouseObject = hovered

		# This stuff only runs when the mouse moves to a different object
		if NewMouseObject != null:
			print("Now hovering:", NewMouseObject.name)
			
			ShopDict[NewMouseObject.name].call(NewMouseObject.Cost)
		else:
			hide_description_frame()
			print("Not hovering any shop object")
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

	
	
	
