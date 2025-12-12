extends Node2D


const Speed = 600.0
const JumpVelocity = -400.0
var Direction = Vector2.ZERO
var Bullet = preload("res://Bullet.tscn")
var target
var shot = false
@export var MagazineReserve = 10
@export var MaxMag = 1
@export var Mag = 1
@export var Cooldown = 2
@export var Damage = 20
@export var Enabled = false
@export var MaxJumps = 4
@export var MagazineMaxReserve = 200
var OnlyOnce = false 
func _input(event):
	pass
		
func ShootCooldown():
	if shot == true:
		await get_tree().create_timer(Cooldown).timeout
		shot = false	
				
func SpawnLightningSegment(FromPos: Vector2, ToPos: Vector2) -> void:
	var Line := Line2D.new()
	Line.z_index = 1000
	get_tree().current_scene.add_child(Line)

	# Place in global space
	Line.global_position = Vector2.ZERO

	Line.width = 4.0
	Line.default_color = Color(0.6, 0.9, 1.0, 1.0)  # bluish lightning

	var Points := PackedVector2Array()
	var Segments := 10

	var Dir := (ToPos - FromPos)
	var Length := Dir.length()
	if Length == 0.0:
		Points.append(FromPos)
		Points.append(ToPos)
		Line.points = Points
		return

	var BaseDir := Dir / Length
	var Perpendicular := Vector2(-BaseDir.y, BaseDir.x)

	for i in range(Segments + 1):
		var T := float(i) / float(Segments)
		var Pos := FromPos.lerp(ToPos, T)

		# Add random sideways jitter to interior points
		if i != 0 and i != Segments:
			var MaxOffset := 12.0
			var OffsetAmount := (randf() - 0.5) * 2.0 * MaxOffset
			Pos += Perpendicular * OffsetAmount

		Points.append(Pos)

	Line.points = Points
	print(Line.global_position)

	# Quick fade-out tween (lightning is fast)
	var tween := get_tree().create_tween()
	tween.tween_property(Line, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func():
		if is_instance_valid(Line):
			Line.queue_free()
	)
	

@export var ChainRadius: float = 250.0

var ShockPos = Vector2.ZERO
var CanShoot = true
func find_next_enemy_in_radius(center: Vector2, radius: float, enemy_container: Node, excluded: Array) -> Node:
	var best: Node = null
	var best_dist_sq := radius * radius

	for e in enemy_container.get_children():
		if e in excluded:
			continue

		var d_sq := center.distance_squared_to(e.global_position)
		if d_sq <= best_dist_sq:
			best_dist_sq = d_sq
			best = e

	return best

func ShootLightning() -> void:
	var origin: Vector2 = global_position
	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = (mouse_pos - origin).normalized()
	var max_range: float = 800.0
	var target_point: Vector2 = origin + direction * max_range

	var space_state := get_world_2d().direct_space_state

	# Exclude the gun itself
	var query := PhysicsRayQueryParameters2D.create(origin, target_point, 0xFFFFFFFF, [self])
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return

	var collider = result.collider
	if collider == null:
		return

	# Resolve to the actual enemy node using groups
	var enemy = collider
	if enemy.get_parent().name != "Enemy":
		return
	

	# --- FIRST HIT ---
	ShockPos = enemy.global_position
	enemy.Health = 0
	SpawnLightningSegment(origin, ShockPos)
	var hit_enemies: Array = [enemy]

	# Get the container that holds all enemies
	var main_scene := get_tree().current_scene
	var enemy_container: Node = main_scene.get_node("Enemy")

	# --- CHAIN JUMPS ---
	var last_hit_pos = ShockPos
	for i in range(MaxJumps-1):
		var next_enemy := find_next_enemy_in_radius(ShockPos, ChainRadius, enemy_container, hit_enemies)
		if next_enemy == null:
			break

		ShockPos = next_enemy.global_position
		SpawnLightningSegment(last_hit_pos, next_enemy.global_position)
		last_hit_pos = next_enemy.global_position
		next_enemy.Health = 0
		hit_enemies.append(next_enemy)
		print("Chained to: ", next_enemy.name)
	
func _physics_process(delta: float) -> void:
	if Enabled == false && $"WunderwaffeDg-2ReloadSoundAnimation".playing == true:
		$"WunderwaffeDg-2ReloadSoundAnimation".stop()
		$ProgressBar.value  = 0 
		CanShoot = true
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
		

		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && shot == false && Mag > 0 && CanShoot == true :
					shot = true
					Mag -= 1
					$WunderWaffeShot.play()
					var randomnumber  =  randi() %2
					var sign = 0
					
					if randomnumber == 1:
						sign = -1
					else:
						sign = 1
					var mouse_vp = get_viewport().get_mouse_position()
					var player_vp = get_global_transform_with_canvas().get_origin()
					var dir = (mouse_vp - player_vp)
					dir = dir.normalized()
					var normal = Vector2(-dir.y,dir.x)
					target = mouse_vp + normal * (100 * sign)
					ShootCooldown()
					ShootLightning()
					
		if Input.is_action_just_pressed('Reload') && MagazineReserve > 0 && Mag < MaxMag && $"WunderwaffeDg-2ReloadSoundAnimation".playing == false :
			$"WunderwaffeDg-2ReloadSoundAnimation".play()
			$ProgressBar.max_value = $"WunderwaffeDg-2ReloadSoundAnimation".stream.get_length()
			CanShoot = false
			$ProgressBar.visible = true
		if $"WunderwaffeDg-2ReloadSoundAnimation".playing == true:

				$ProgressBar.value = $"WunderwaffeDg-2ReloadSoundAnimation".get_playback_position()
				
				
		if $"WunderwaffeDg-2ReloadSoundAnimation".playing == true && $"WunderwaffeDg-2ReloadSoundAnimation".get_playback_position() >= 5.3 && OnlyOnce == false:
			OnlyOnce = true
		
			if MagazineReserve >= MaxMag:
				MagazineReserve -= MaxMag - Mag
			
				Mag = MaxMag
				
			else:
					Mag = MagazineReserve
					MagazineReserve -= MagazineReserve
			
					
		if target:
			Input.warp_mouse(get_viewport().get_mouse_position().move_toward(target,10000*delta))
	
			if (get_viewport().get_mouse_position()-target).length() <= 4:
			
				target = null

		
			
			
		
		
		





func _on_wunderwaffe_dg_2_reload_sound_animation_finished() -> void:
	CanShoot = true
	OnlyOnce = false
	$ProgressBar.value = 0
	$ProgressBar.visible = false
