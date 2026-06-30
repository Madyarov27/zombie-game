extends Node3D

@export var weapon_name := "shotgun"
@export var cost := 500



# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("weapon_shops")
	
func try_buy(player):
	if player.owned_weapons.has(weapon_name):
		print("Already owned")
		return 
	if player.gold >= cost:
		player.gold -= cost
		player.owned_weapons.append(weapon_name)
		player.current_weapon = weapon_name
		player.update_gold_display()
		print("Bought ", weapon_name, "!")
		player.update_gun_model()
	else:
		print("Not enough gold!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
