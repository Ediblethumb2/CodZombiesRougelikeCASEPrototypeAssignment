extends CharacterBody2D


const Speed = 600.0
const JumpVelocity = -400.0
var Direction = Vector2.ZERO
var Bullet = preload("res://Bullet.tscn")
var target
var shot = false
@export var Equipped = 	""
var LastEquipped = ""
var WeaponsDict = {"AssaultRifle":AssaultRifle,"Pistol":Pistol}
var Inventory = ["Pistol","AssaultRifle"]
func AssaultRifle():
	print("a")
	var gun = find_child(Equipped)
	gun.Enabled = true
	gun.find_child("Gun").visible = true

func Pistol():
	var gun = find_child(Equipped)
	gun.Enabled = true
	gun.find_child("Gun").visible = true 
				
func _input(event: InputEvent) -> void:
	if event.is_action("PrimaryEquip"):
		if Equipped != "" && Equipped != Inventory[0]:
			find_child(Equipped).Enabled = false 
			find_child(Equipped).find_child("Gun").visible = false
		Equipped = Inventory[0]
	if event.is_action("SecondaryEquip"):
		if Equipped != "" && Equipped != Inventory[1]:
			find_child(Equipped).Enabled = false 
			find_child(Equipped).find_child("Gun").visible = false
		Equipped = Inventory[1]
	
	
func _physics_process(delta: float) -> void:
	
	if Equipped == LastEquipped:
		pass
	elif Equipped != LastEquipped:
		print("Changed")
		LastEquipped = Equipped
		WeaponsDict[Equipped].call()
	
	
	
	var gun = find_child(Equipped)
	var input_direction = Vector2.ZERO
	if Equipped !=  "":
		gun.look_at(get_global_mouse_position())
		gun.rotate(-PI/1000)
	
	

			
	if Input.is_action_pressed("W"):
		input_direction.y -= 1
	if Input.is_action_pressed("S"):
		input_direction.y += 1
	if Input.is_action_pressed("A"):
		input_direction.x -= 1
	if Input.is_action_pressed("D"):
		input_direction.x += 1

	input_direction.x = clamp(input_direction.x, -1, 1)
	input_direction.y = clamp(input_direction.y, -1, 1)

	Direction = input_direction.normalized()
	
	velocity = Direction * Speed

	move_and_slide()

		
		
	
	
	
	
