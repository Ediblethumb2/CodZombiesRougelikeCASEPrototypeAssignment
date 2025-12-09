extends Node2D
var Guns := {
	"Pistol": {
		"BasePrice": 10.0,
		"MinDepth": 0,
		"Scene": preload("res://PistolShop.tscn")
	},
	"AssaultRifle": {
		"BasePrice": 30.0,
		"MinDepth": 3,
		"Scene": preload("res://AKShop.tscn")
	},
	"WunderWaffe": {
		"BasePrice": 200.0,
		"MinDepth": 7,
		"Scene": preload("res://WunderWaffeShop.tscn")
	}
}
const DEPTHPRICESTEP := 0.60 
var GunNames = ["Pistol","AssaultRifle"]
var Pistol = null
var Ready = false
@export var Player = null
func get_scaled_price(gun_name: String) -> float:
	var base_price: float = Guns[gun_name]["BasePrice"]
	var depth: int = int($RoomLayer.get_meta("depth"))
	var min_depth: int = Guns[gun_name]["MinDepth"]

	
	var effective_depth: int = max(depth - min_depth, 0)

	var multiplier: float = 1.0 + float(effective_depth) * DEPTHPRICESTEP
	return base_price * multiplier
func _ready() -> void:
	set_process(false)






var Spawn = null
var GunCount = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
		GunNames.shuffle()
		

	
		for Gun in GunNames:
			if Guns[Gun]["MinDepth"] > $RoomLayer.get_meta("depth"):
				
				continue
			else:
					if GunCount < 3:
						var GunOBJ = Guns[Gun]["Scene"].instantiate()
						for Spawns in $RoomLayer/Spawnpoints.get_children():
							if Spawns.get_meta("Occupied") == false:
								Spawn = Spawns
								Spawns.set_meta("Occupied",true)
								break
							
						GunOBJ.global_position = Spawn.global_position
						GunOBJ.Player = Player
						GunCount+= 1
						add_child(GunOBJ)
						var ScaledPrice = get_scaled_price(Gun)
						GunOBJ.Cost = ScaledPrice
						GunNames.erase(Gun)
						break

func _on_area_2d_body_entered(body: Node2D) -> void:
	
	
	if body.get_class() == "CharacterBody2D":
		set_process(true)
		Player = body
		body.set_meta("NoFog",true)
		body.set_meta("Shop",true)
		


func _on_area_2d_body_exited(body: Node2D) -> void:
	body.set_meta("NoFog",false)
	body.set_meta("Shop",false)
