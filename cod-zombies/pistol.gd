extends Node2D


const Speed = 600.0
const JumpVelocity = -400.0
var Direction = Vector2.ZERO
var Bullet = preload("res://Bullet.tscn")
var target
var shot = false
@export var CooldownTime = 0.7
@export var Damage = 20
@export var Enabled = false
func _input(event):
	pass
				
func ShootCooldown():
	if shot == true:
		await get_tree().create_timer(CooldownTime).timeout
		shot = false	
				
				
	
	
func _physics_process(delta: float) -> void:


	
	if Enabled == true:
		var rotationabs  = abs(rotation_degrees)
		if rotationabs >= 360:
			rotation = 0
		if rotationabs >= 90:
			$Gun.flip_v = true
		if rotationabs >= 260:
			$Gun.flip_v = false
		if rotationabs < 90:
			$Gun.flip_v = false
		

		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && shot == false:
					shot = true
					print(get_global_mouse_position() + Vector2(0,50))
					var randomnumber  =  randi() %2
					var sign = 0
					
					if randomnumber == 1:
						sign = -1
					else:
						sign = 1
						
					var NewObject = Bullet.instantiate()
					var mouse_vp = get_viewport().get_mouse_position()
					var player_vp = get_global_transform_with_canvas().get_origin()
					var dir = (mouse_vp - player_vp)
					dir = dir.normalized()
					var normal = Vector2(-dir.y,dir.x)
					target = mouse_vp + normal * (200 * sign)
					ShootCooldown()
					
		#if shot == true:
		#	await get_tree().create_timer(1).timeout
			#shot = false
					NewObject.set_meta("DirX",dir.x)
					NewObject.set_meta("DirY",dir.y)
					NewObject.global_position = global_position + 100* ( get_global_mouse_position() - global_position).normalized()
					get_parent().get_parent().get_parent().get_parent().add_child(NewObject)
					
		if target:
			Input.warp_mouse(get_viewport().get_mouse_position().move_toward(target,10000*delta))
			print( get_viewport().get_mouse_position())
			print((get_viewport().get_mouse_position()-target).length())
			if (get_viewport().get_mouse_position()-target).length() <= 4:
			
				target = null

		
			
			
		
		
		
		
