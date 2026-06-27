extends Node3D

var unlocked = false
@export var price := 500

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("doors") # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func vanish(player):
	if !unlocked and has_node("door") and player.gold >= price:
		$door.queue_free()
		unlocked = true
		player.gold -= price
		player.update_gold_display()
	
