extends Node2D
var Cards := {
	"CooldownReduction": {
		"BasePrice": 30.0,
		"MinDepth": 0,
		"Scene": preload("res://CooldownCard.tscn")
	},
	"ExtraDamage":{
		"BasePrice": 60,
		"MinDepth": 0,
		"Scene": preload("res://ExtraDamageCard.tscn")
	}
}
const DEPTHPRICESTEP := 0.60 
var CardNames = ["ExtraDamage","CooldownReduction"]
var Pistol = null
var Ready = false
@export var Player = null
func get_scaled_price(CardName: String) -> float:
	var base_price: float = Cards[CardName]["BasePrice"]
	var depth: int = int($RoomLayer.get_meta("depth"))
	var min_depth: int = Cards[CardName]["MinDepth"]

	
	var effective_depth: int = max(depth - min_depth, 0)

	var multiplier: float = 1.0 + float(effective_depth) * DEPTHPRICESTEP
	return base_price * multiplier
func _ready() -> void:
	set_process(false)







var Spawn = null
var CardCount = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
		CardNames.shuffle()
		

	
		for CardName in CardNames:
			if Cards[CardName]["MinDepth"] > $RoomLayer.get_meta("depth"):
				
				continue
			else:
					if CardCount < 3:
						var CardOBJ = Cards[CardName]["Scene"].instantiate()
						for Spawns in $RoomLayer/Spawnpoints.get_children():
							if Spawns.get_meta("Occupied") == false:
								Spawn = Spawns
								Spawns.set_meta("Occupied",true)
								break
							
						CardOBJ.global_position = Spawn.global_position
						CardOBJ.Player = Player
						CardCount+= 1
						add_child(CardOBJ)
						var ScaledPrice = get_scaled_price(CardName)
						CardOBJ.Cost = ScaledPrice
						CardNames.erase(CardName)
						break

func _on_area_2d_body_entered(body: Node2D) -> void:
	
	
	if body.get_class() == "CharacterBody2D":
		set_process(true)
		Player = body
		body.set_meta("NoFog",true)
		body.set_meta("Shop",true)
		


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		body.set_meta("NoFog",false)
		body.set_meta("Shop",true)
