extends Node2D


const Speed = 600.0
const JumpVelocity = -400.0
var Direction = Vector2.ZERO
var Bullet = preload("res://Bullet.tscn")
var target
var shot = false
@export var Cooldown = 0.2
@export var Damage = 20
@export var MagazineReserve = 200
@export var MaxMag = 30
@export var Mag = 30
@export var MagazineMaxReserve = 200
@export var Enabled = false
var OnlyOnce = false
var CanShoot = true 
func _input(event):
	pass
				
func ShootCooldown():
	if shot == true:
		await get_tree().create_timer(Cooldown).timeout
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
		if $AssaultRifleReload.playing == true:
			$ProgressBar.value = $AssaultRifleReload.get_playback_position()
		if Input.is_action_just_pressed('Reload') && MagazineReserve > 0 && Mag < MaxMag && $"AssaultRifleReload".playing == false :
			$"AssaultRifleReload".play()
			CanShoot = false
			$ProgressBar.max_value = $AssaultRifleReload.stream.get_length()

			$ProgressBar.visible = true
		

		if $"AssaultRifleReload".playing == true && $"AssaultRifleReload".get_playback_position() >= 2.5 && OnlyOnce == false:
			OnlyOnce = true
			if MagazineReserve >= MaxMag:
				MagazineReserve -= MaxMag - Mag
			
				Mag = MaxMag
				
			else:
					Mag = MagazineReserve
					MagazineReserve -= MagazineReserve
			
		

			
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && shot == false && Mag > 0 && CanShoot == true:
					shot = true
					Mag -= 1
					var randomnumber  =  randi() %2
					var sign = 0
					$AssaultRifleGunshot.play()
					
					if randomnumber == 1:
						sign = -1
					else:
						sign = 1
						
					var NewObject = Bullet.instantiate()
					NewObject.Damage = Damage
					var mouse_vp = get_viewport().get_mouse_position()
					var player_vp = get_global_transform_with_canvas().get_origin()
					var dir = (mouse_vp - player_vp)
					dir = dir.normalized()
					var normal = Vector2(-dir.y,dir.x)
					target = mouse_vp + normal * (60 * sign)
					ShootCooldown()
					
		#if shot == true:
		#	await get_tree().create_timer(1).timeout
			#shot = false
					NewObject.set_meta("DirX",dir.x)
					NewObject.set_meta("DirY",dir.y)
					NewObject.global_position = find_child("Gun").global_position + (dir * 50)
					
					get_parent().get_parent().get_parent().add_child(NewObject)
				
					
		if target:
			Input.warp_mouse(get_viewport().get_mouse_position().move_toward(target,10000*delta))
	
			if (get_viewport().get_mouse_position()-target).length() <= 4:
			
				target = null

		
			
			
		
		
		


func _on_assault_rifle_reload_finished() -> void:
	CanShoot = true
	OnlyOnce = false
	$ProgressBar.visible = false
