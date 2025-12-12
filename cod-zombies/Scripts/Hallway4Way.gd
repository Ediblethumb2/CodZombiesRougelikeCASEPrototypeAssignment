extends Node2D

var ENEMIES := {
	"Cat": {"cost": 4.0,  "MinDepth": 0,  "Scene": preload("res://Enemies/BasicEnemy.tscn")},

}
var onlyonce = false

var ELITE_MODS := {
		"Fast": {"min_depth": 0, "cost_mul": 1.3, "apply": func(n) -> void :
		n.set_meta("Fast",true)
		},
	"Tanky": { "min_depth": 0, "cost_mul": 1.2, "apply": func(n) -> void:
		n.set_meta("Tanky",true)
		},

}
var Spawned = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		set_process(false)

var EnemyNames = ["Cat"]
var Modnames = ["Fast","Tanky"]
var AppliedMod = false
var Count = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
		
	if onlyonce == false && $RoomLayer.has_meta("Budget"):
		
		
		$RoomLayer/RichTextLabel.text = str($RoomLayer.get_meta("Budget"))
		onlyonce = true
	if $RoomLayer.has_meta("Budget"):
	
		if $RoomLayer.get_meta("Budget") < 4:
			AppliedMod = false 
		
			print("ssdhsfhuife")
		EnemyNames.shuffle()
		Modnames.shuffle()
		AppliedMod = false
		for enemy in EnemyNames:
			if ENEMIES[enemy]["cost"] > $RoomLayer.get_meta("Budget"):
				continue
				
			else:
				if ENEMIES[enemy]["MinDepth"] > $RoomLayer.get_meta("depth"):
					continue
				else:
					var EnemyOBJ = ENEMIES[enemy]["Scene"].instantiate()
					var Spawn = null
					for Spawns in $RoomLayer/Spawn.get_children():
						if not Spawns.has_meta("Occupied"):
							Spawn = Spawns
							Count += 1
							break
					
					if Count >= $RoomLayer/Spawn.get_children().size() :
						break
					EnemyOBJ.global_position = Spawn.global_position
					EnemyOBJ.set_meta("Depth",$RoomLayer.get_meta("depth"))
				
					Spawn.set_meta("Occupied",true)
					
					EnemyOBJ.Spawn = Spawn
					for mods in Modnames:
						
						if ENEMIES[enemy]["cost"] * ELITE_MODS[mods]["cost_mul"] <= $RoomLayer.get_meta("Budget") && $RoomLayer.get_meta("depth") >= ELITE_MODS[mods]["min_depth"]:
							
							$RoomLayer.set_meta("Budget",$RoomLayer.get_meta("Budget")-(ENEMIES[enemy]["cost"] * ELITE_MODS[mods]["cost_mul"]))
							ELITE_MODS[mods]["apply"].call(EnemyOBJ)
							get_tree().current_scene.get_node("Enemy").add_child(EnemyOBJ)
							
							AppliedMod  = true
						
							break
					if AppliedMod == false:
						$RoomLayer.set_meta("Budget",$RoomLayer.get_meta("Budget")-(ENEMIES[enemy]["cost"]))
						
						
					break
					
	if Spawned == true && 	get_tree().current_scene.get_node("Enemy").get_children().size() == 0:
		for door in $RoomLayer/Doors.get_children():
			door.queue_free()
			set_process(false)
					
	
		 
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		await get_tree().create_timer(2.0).timeout
		set_process(true)
		Spawned = true

	
var SelectedDoor = null		
var Player = null



func _on_door_area_unlock_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Player = body
		body.CanUnlock = true
	
		SelectedDoor = $RoomLayer/Doors/Door
		body.UnlockableDoor =  $RoomLayer/Doors/Door
		 
		
func StartSpawning():
	
	Player.global_position  = $RoomLayer/CameraTarget.global_position
	
func _on_door_area_unlock_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body = Player
		body.CanUnlock = false
		SelectedDoor = null
		body.UnlockableDoor = null


func _on_door_area_unlock_2_body_entered(body: Node2D) -> void:
		if body.name == "Player":
			Player = body
			body.CanUnlock = true
	
			SelectedDoor = $RoomLayer/Doors/Door2
			body.UnlockableDoor =  $RoomLayer/Doors/Door2


func _on_door_area_unlock_2_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body = Player
		body.CanUnlock = false
		SelectedDoor = null
		body.UnlockableDoor = null


func _on_door_area_unlock_3_body_entered(body: Node2D) -> void:
		if body.name == "Player":
			Player = body
			body.CanUnlock = true
	
			SelectedDoor = $RoomLayer/Doors/Door3
			body.UnlockableDoor =  $RoomLayer/Doors/Door3



func _on_door_area_unlock_3_body_exited(body: Node2D) -> void:
	
	if body.name == "Player":
		body = Player
		body.CanUnlock = false
		SelectedDoor = null
		body.UnlockableDoor = null


func _on_door_area_unlock_4_body_entered(body: Node2D) -> void:
		if body.name == "Player":
			Player = body
			body.CanUnlock = true
	
			SelectedDoor = $RoomLayer/Doors/Door4
			body.UnlockableDoor =  $RoomLayer/Doors/Door4


func _on_door_area_unlock_4_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body = Player
		body.CanUnlock = false
		SelectedDoor = null
		body.UnlockableDoor = null
