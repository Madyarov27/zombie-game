extends CharacterBody3D

var health := 100
var speed := 4.0
var attack_range := 1.5
var attack_damage := 10
var attack_cooldown := 1.0
var time_since_attack := 0.0


func _physics_process(delta):
	time_since_attack += delta
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance > attack_range:
			# tell the navigation agent where we want to go
			$NavigationAgent3D.target_position = player.global_position
			# ask it for the next point along the smart path
			var next_point = $NavigationAgent3D.get_next_path_position()
			# move toward that next point (not straight at the player)
			var direction = (next_point - global_position)
			direction.y = 0
			direction = direction.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# close enough: stop and attack
			velocity.x = 0
			velocity.z = 0
			if time_since_attack >= attack_cooldown:
				time_since_attack = 0.0
				if player.has_method("take_damage"):
					player.take_damage(attack_damage)

	velocity.y -= 9.8 * delta
	move_and_slide()
	

	

		
func take_damage(amount):
	health -= amount
	print("Zombie health: ", health)
	if health <= 0:
		die()
	

func die():
	print("Zombie died!")
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold"):
		print("Calling add_gold")
		player.add_gold(50)
	queue_free()
