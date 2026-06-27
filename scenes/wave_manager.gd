extends Node

@export var zombie_scene: PackedScene
@export var spawn_points_path: NodePath

var current_round := 0
var zombies_alive := 0
var zombies_to_spawn := 0
var spawn_index := 0
var spawn_timer := 0.0
var spawn_interval := 2


func _ready():
	start_next_round()

func start_next_round():
	current_round += 1
	print("=== ROUND ", current_round, " ===")
	# more zombies each round
	zombies_to_spawn = 2 + current_round
	spawn_timer = 0.0

func _process(delta):
	if zombies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_zombie()
			zombies_to_spawn -= 1
			spawn_timer = spawn_interval

func spawn_zombie():
	var spawn_points = get_node(spawn_points_path).get_children()
	if spawn_points.is_empty():
		print("NO SPAWN POINTS FOUND")
		return
	# cycle through points so zombies don't stack
	var point = spawn_points[spawn_index % spawn_points.size()]
	spawn_index += 1
	var zombie = zombie_scene.instantiate()
	get_parent().add_child(zombie)
	zombie.global_position = point.global_position + Vector3(0, 1, 0)  # lift up a bit
	zombies_alive += 1
	print("Spawned zombie at ", zombie.global_position, " | alive now: ", zombies_alive)
	zombie.tree_exited.connect(_on_zombie_died)

func _on_zombie_died():
	zombies_alive -= 1
	print("A zombie left. alive now: ", zombies_alive)
	if zombies_alive <= 0 and zombies_to_spawn <= 0:
		print("Round cleared!")
		$Timer.start()

func _on_timer_timeout():
	start_next_round()
