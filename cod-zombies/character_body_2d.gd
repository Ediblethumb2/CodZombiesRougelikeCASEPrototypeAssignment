extends CharacterBody2D


var  Speed = 600.0
const JumpVelocity = -400.0
var Direction = Vector2.ZERO
var Bullet = preload("res://Bullet.tscn")
var target
var shot = false
@export var Equipped = 	""
var LastEquipped = ""
var WeaponsDict = {"AssaultRifle":AssaultRifle,"Pistol":Pistol}
var Inventory = ["Pistol","AssaultRifle"]



func Fog():
	if get_meta("NoFog") != PreviousNoFog:
		
		if get_meta("NoFog") == true:
			
			for i in range(0,11,1):
				
				var i2:float = float(i)/10
				
				
				$CanvasLayer/ColorRect.set_instance_shader_parameter("ambient",i2)
				await get_tree().process_frame
			PreviousNoFog = true
		if get_meta("NoFog") == false:
			for i in range(11,-1,-1):
				var i2:float = float(i)/10
				print(i2)
				$CanvasLayer/ColorRect.set_instance_shader_parameter("ambient",i2)
				await get_tree().process_frame
			PreviousNoFog = false
	

var SlidingOnce = false
var SlideCooldown = false
func AssaultRifle():
	print("a")
	var gun = find_child(Equipped)
	gun.Enabled = true
	gun.find_child("Gun").visible = true

func Pistol():
	var gun = find_child(Equipped)
	gun.Enabled = true
	gun.find_child("Gun").visible = true 
var  sliding = false
func _input(event: InputEvent) -> void:
	if event.is_action("PrimaryEquip"):
		if Equipped != "" && Equipped != Inventory[0]:
			find_child(Equipped).Enabled = false 
			find_child(Equipped).find_child("Gun").visible = false	
		Equipped = Inventory[0]
	if event.is_action("Slide") && sliding == false && SlideCooldown == false && input_direction.length() > 0 :

		sliding = true
		SlideCooldown  = true
		SlideCOoldownDelay(5)
		print("egbewgwhfuiwef")
		
		
	if event.is_action_released("Slide"):
	
		sliding = false
		SlidingOnce = false
		
	if event.is_action("SecondaryEquip"):
		if Equipped != "" && Equipped != Inventory[1]:
			find_child(Equipped).Enabled = false 
			find_child(Equipped).find_child("Gun").visible = false
			
		Equipped = Inventory[1]
	

func on_tween_finished():
	sliding = false 
	print("done")
var PreviousNoFog = false
func SetAmount(v:float):
	Speed = v


func _ready() -> void:
	pass
var input_direction = Vector2.ZERO
var SlideTween = null
var sliding_prev := false
func SlideCOoldownDelay(timeout):
	await get_tree().create_timer(timeout).timeout
	SlideCooldown = false
var gun = "a"
func _physics_process(delta: float) -> void:
	# --- remove these lines ---
	# SlideTween = create_tween().set_ease(...).set_trans(...).set_parallel(true)
	# SlideTween.connect("finished", on_tween_finished)

	$CanvasLayer/SubViewportContainer/SubViewport.world_2d = get_tree().root.world_2d
	$CanvasLayer/SubViewportContainer/SubViewport/Camera2D.global_position = global_position

	Fog()

	if Equipped != LastEquipped:
		LastEquipped = Equipped
		WeaponsDict[Equipped].call()
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

	
	
	
