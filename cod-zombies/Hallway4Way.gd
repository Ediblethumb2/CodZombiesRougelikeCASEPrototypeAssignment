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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		set_process(false)

var EnemyNames = ["Cat"]
var Modnames = ["Fast","Tanky"]
var AppliedMod = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if onlyonce == false && $RoomLayer.has_meta("Budget"):
		
		
		$RoomLayer/RichTextLabel.text = str($RoomLayer.get_meta("Budget"))
		onlyonce = true
	if $RoomLayer.has_meta("Budget"):
		print($RoomLayer.get_meta("Budget"))
		if $RoomLayer.get_meta("Budget") < 4:
			AppliedMod = false 
			set_process(false)
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
					var Spawn = $RoomLayer/Spawn.get_children().pick_random()
					EnemyOBJ.global_position = Spawn.global_position
					
					EnemyOBJ.Spawn = Spawn
					for mods in Modnames:
						
						if ENEMIES[enemy]["cost"] * ELITE_MODS[mods]["cost_mul"] <= $RoomLayer.get_meta("Budget") && $RoomLayer.get_meta("depth") >= ELITE_MODS[mods]["min_depth"]:
							
							$RoomLayer.set_meta("Budget",$RoomLayer.get_meta("Budget")-(ENEMIES[enemy]["cost"] * ELITE_MODS[mods]["cost_mul"]))
							ELITE_MODS[mods]["apply"].call(EnemyOBJ)
							add_child(EnemyOBJ)
							AppliedMod  = true
						
							break
					if AppliedMod == false:
						$RoomLayer.set_meta("Budget",$RoomLayer.get_meta("Budget")-(ENEMIES[enemy]["cost"]))
						
						
					break
					
				
	
		 
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		set_process(true)
