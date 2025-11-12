extends Node2D

var ENEMIES := {
	"Cat": {"cost": 4.0,  "MinDepth": 0,  "Scene": preload("res://Enemies/BasicEnemy.tscn")},
	"Groot":{"cost":400000,"MinDepth": 0}

}

var ELITE_MODS := {
		"Fast": {"min_depth": 4, "cost_mul": 100000, "apply": func(n) -> void :
		n.set_meta("Fast",true)
		},
	"Tanky": { "min_depth": 0, "cost_mul": 1, "apply": func(n) -> void:
		n.set_meta("Tanky",true)
		},

}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var EnemyNames = ["Cat","Groot"]
var Modnames = ["Fast","Tanky"]
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $RoomLayer.has_meta("depth"):
	if $RoomLayer.has_meta("Budget"):
		$RoomLayer/RichTextLabel.text = str($RoomLayer.get_meta("Budget"))
		EnemyNames.shuffle()
		Modnames.shuffle()
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
					$RoomLayer.set_meta("Budget",$RoomLayer.get_meta("Budget")-ENEMIES[enemy]["cost"])
					add_child(EnemyOBJ)
					EnemyOBJ.Spawn = Spawn
					for mods in Modnames:
						
						if ENEMIES[enemy]["cost"] * ELITE_MODS[mods]["cost_mul"] <= $RoomLayer.get_meta("Budget") && $RoomLayer.get_meta("depth") >= ELITE_MODS[mods]["min_depth"]:
							print( ENEMIES[enemy]["cost"] * ELITE_MODS[mods]["cost_mul"])
							$RoomLayer.set_meta("Budget",$RoomLayer.get_meta("Budget")-ENEMIES[enemy]["cost"] * ELITE_MODS[mods]["cost_mul"])
							ELITE_MODS[mods]["apply"].call(EnemyOBJ)
							break
					break
				
	
		 
		
