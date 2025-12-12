extends Node2D

var hallway1 = preload("res://hallway_1.tscn")
var hallway2 = preload("res://hallway_2.tscn")
var hallway3 = preload("res://hallway_3.tscn")
var hallway4 = preload("res://Hallway4.tscn")
var DeadEnd = preload("res://DeadEnd.tscn")
var Wall = preload("res://Wall.tscn")
var hallways = [hallway3,hallway4]
var DeadEnds = [Wall,DeadEnd]
var Successful  = 0 
var genrunning = false
var opposite := {
		"ConnR": "ConnL",
		"ConnL": "ConnR",
		"ConnU": "ConnD",
		"ConnD": "ConnU",
}
var rect = Rect2(25,25,-100,-50)
@onready var _timer = Timer.new()
@onready var Timer2 = Timer.new()
var markerrunning = false
var Hallwaydupe = hallways.duplicate()
var DeadEndDupe = DeadEnds.duplicate()

func _spawn_deadend_at_marker(scene,  marker: Marker2D) -> bool:

	var obj := scene.instantiate() as Node2D
	


	
			
	# 1) Map marker name -> opposite connector on the NEW piece

	

	
	
	if not opposite.has(marker.name):
		push_error("Marker must be named ConnR/ConnL/fConnU/ConnD"); obj.queue_free(); return false 

	var new_conn := obj.find_child("ConnU") as Node2D
	if new_conn == null:

		return false
		#push_error("New hallway missing %s" % opposite[marker.name]); obj.queue_free(); 
			#marker.set_meta("Occupied",true)
		
		#return

		
	var T_marker := Transform2D(marker.global_rotation, marker.global_position)
	var T_conn   := Transform2D(new_conn.rotation, new_conn.position)

	var R_180    := Transform2D(PI, Vector2.ZERO)  # make connectors face away (butt-join)

	# 3) Place: obj * new_conn_local = marker * 180°
	var T := T_marker * R_180 * T_conn.affine_inverse()

	# 4) Apply pos/rot only (keep scale)
	obj.find_child("Sprite2D").global_position = T.origin
	obj.find_child("Sprite2D").global_rotation = T.get_rotation()
	obj.scale = Vector2.ONE
	obj.global_position = obj.global_position.round()
	add_child(obj)
	



	await get_tree().physics_frame
	



	
	

					
	if  obj.find_child("Sprite2D").find_child("Area2D").has_overlapping_areas():
		#new_conn.set_meta("Occupied",false)
		#if is_instance_valid(marker) and !marker.is_queued_for_deletion():
			#marker.set_meta("Occupied",false)

		obj.queue_free()
		return false
		

	else:
		#Successful +=1
		new_conn.set_meta("Occupied",true)
		#new_conn.set_meta("DeadEnd",false)
	
	
		marker.set_meta("Occupied",true)
		
		#	marker.set_meta("DeadEnd",false)
		return true
		
var abc = false 	
func _spawn_hallway_at_marker(scene,  marker: Marker2D) -> bool:

	var obj := scene.instantiate() as Node2D
	


	
			
	# 1) Map marker name -> opposite connector on the NEW piece

	

	var Vectors := {
		"ConnR": Vector2(1000,0),
		"ConnL": Vector2(-1000,0),
		"ConnU": Vector2(0,-1000),
		"ConnD": Vector2(0,1000),
	}
	
	if not opposite.has(marker.name):
		push_error("Marker must be named ConnR/ConnL/fConnU/ConnD"); obj.queue_free(); return false 

	var new_conn := obj.find_child(opposite[marker.name]) as Node2D
	if new_conn == null:
		return false
	var T_marker := Transform2D(marker.global_rotation, marker.global_position)
	var T_conn   := Transform2D(new_conn.rotation, new_conn.position)

	var R_180    := Transform2D(PI, Vector2.ZERO)  # make connectors face away (butt-join)

	# 3) Place: obj * new_conn_local = marker * 180°
	var T := T_marker * R_180 * T_conn.affine_inverse()

	# 4) Apply pos/rot only (keep scale)
	obj.find_child("Sprite2D").global_position = T.origin
	obj.find_child("Sprite2D").global_rotation = T.get_rotation()
	obj.scale = Vector2.ONE
	obj.global_position = obj.global_position.round()
		#push_error("New hallway missing %s" % opposite[marker.name]); obj.queue_free(); 
	marker.set_meta("Locked",true)
	new_conn.set_meta("Locked",true)
	add_child(obj)

	markerrunning = true
	

		#marker.set_meta("Occupied",true)

		#return

		
	abc = true


	await get_tree().physics_frame
	



	
	

					
	if  obj.find_child("Sprite2D").find_child("Area2D").has_overlapping_areas():
		#new_conn.set_meta("Occupied",false)
		#if is_instance_valid(marker) and !marker.is_queued_for_deletion():
			#marker.set_meta("Occupied",false)
	
		obj.queue_free()
	
		markerrunning = false
		marker.set_meta("Locked",false)
		return false
		
		

	else:
		Successful +=1
		new_conn.set_meta("Occupied",true)
		
		#new_conn.set_meta("DeadEnd",false)
		marker.set_meta("Occupied",true)
		marker.set_meta("Locked",false)
		
		#	marker.set_meta("DeadEnd",false)
	
		markerrunning = false
		return true
		
	
	
	
	
func get_all_children(in_node,arr:= []):
	if arr == null:
		arr = []
	arr.push_back(in_node)
	for child in in_node.get_children():
		get_all_children(child,arr)
	return arr
func FillDeadEnds():
		

		var canfill = false

		for Hallway in get_children():
	
		
			if Hallway.get_class() != "Node2D":
				continue
			
		
			
				
			var marker =Hallway.find_child("Sprite2D").find_child("Control").get_children().pick_random()
				
			if  marker.get_meta("Occupied") == false || marker.get_meta("DeadEnd") == true  :


			
					
				DeadEndDupe = DeadEnds.duplicate()
					
					
				var scene = DeadEndDupe.pick_random()
				var placed = await _spawn_deadend_at_marker(scene,marker)
				
				if placed == false:
					
					DeadEndDupe.remove_at(DeadEndDupe.find(scene))
						
						
					while !DeadEndDupe.is_empty():
						await  get_tree().physics_frame
						
						markerrunning = true
						scene = DeadEndDupe.pick_random()
						
						placed  =  await _spawn_deadend_at_marker(scene,marker)
							
						if placed == false && DeadEndDupe.size() > 0:
							
						
							DeadEndDupe.remove_at(DeadEndDupe.find(scene))
						if placed:
							markerrunning = false
							marker.set_meta("DeadEnd",false)
							marker.set_meta("Occupied",true)
								
							break
						if DeadEndDupe.size() == 0:
								
								marker.set_meta("Occupied",true)
								markerrunning = false
							#	marker.set_meta("DeadEnd",false)
									
								break
								
								
						
					break
			
				
		
	
func FillMap():
		

		var canfill = false
		
		for Hallway in get_children():
	
			
			if not (Hallway is Node2D):
					continue
			var control = Hallway.get_node("Sprite2D/Control")
			if control == null:
				continue
			
				
			var marker =Hallway.find_child("Sprite2D").find_child("Control").get_children().pick_random()
		
			if markerrunning :
				continue
			if marker.get_meta("Occupied") == false  && marker.get_meta("Locked") == false:

					
				Hallwaydupe = hallways.duplicate()
					
					
				var scene = Hallwaydupe.pick_random()
				var placed = await _spawn_hallway_at_marker(scene,marker)
				
				if placed == false:
					
					Hallwaydupe.remove_at(Hallwaydupe.find(scene))
						
						
					while !Hallwaydupe.is_empty():
						await  get_tree().physics_frame
							
						markerrunning = true
						scene = Hallwaydupe.pick_random()
						
						placed  =  await _spawn_hallway_at_marker(scene,marker)
							
						if placed == false && Hallwaydupe.size() > 0:
							
							
							Hallwaydupe.remove_at(Hallwaydupe.find(scene))
							
							
						if placed:
							markerrunning = false
							
							marker.set_meta("DeadEnd",false)
							marker.set_meta("Occupied",true)
							break
						if Hallwaydupe.size() == 0:
							marker.set_meta("Occupied",true)
							markerrunning = false
							marker.set_meta("DeadEnd",true)
									
							break
								
								
						
					break
			
					
		
		


	
			
	# 1) Map marker name -> opposite connector on the NEW piece

	
	
				

							
		
						
							
# Called when the node enters the scene tree for the first time.
func genloop():
	if genrunning == true:
		return
	genrunning = true
	await rungeneration()
	genrunning = false 
func _ready() -> void:
	call_deferred("genloop")
	_timer.autostart = true
	_timer.one_shot = false
	#_timer.wait_time = get_tree().physics_frame
	_timer.timeout.connect(Callable(self, "_on_timer_timeout"))
	#add_child(_timer)
	#_timer.start()
	
	
func _on_timer_timeout() -> void:
	pass
var FillEnds = false
func RunDeadEndFill():
	while FillEnds == true:
		
		await FillDeadEnds()
		await get_tree().physics_frame
		
		
		
func rungeneration():
	while Successful < 100:
		if markerrunning == false || abc == false:
			await get_tree().create_timer(0.5).timeout
			
			await FillMap()
			await get_tree().physics_frame
	FillEnds = true 
	await RunDeadEndFill()
			
# Called every frame. 'delta' is the elapsed time since the previous frame.

	
