extends Node2D

@export var Cost = 0
@export var GunName = "AssaultRifle"
@export var Player = CharacterBody2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Cost != 0:
		$CostLabel.text = str(Cost)
		set_process(false)

		



func _on_area_2d_mouse_entered() -> void:
	$CostLabel.text = str(Cost)
	Player.SelectingGun = self
	print("Entered")


func _on_area_2d_mouse_exited() -> void:
	$CostLabel.text = ""
	Player.SelectingGun = null
	print("Exited")
