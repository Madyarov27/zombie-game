extends CharacterBody3D

@export var speed := 8.0
@export var mouse_sensitivity := 0.003

var health := 100
var tracer_timer := 0.0
var gold := 0
var jump_velocity = 4
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# build the tracer mesh + material ONCE
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 1)   # length 1 for now, we scale it later
	$Tracer.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 0)
	mat.emission_energy_multiplier = 5.0
	$Tracer.material_override = mat
	$Tracer.visible = true
	tracer_timer = 0.01
	show_tracer(global_position, global_position + Vector3(0, 0, -1))

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.5, 1.5)
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot()

func _physics_process(delta):
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y -= 16 * delta  # gravity
	move_and_slide()
	

func shoot():
	var ray = $Camera3D/RayCast3D
	ray.force_raycast_update()
	var start = $Camera3D/MeshInstance3D.global_position
	var end
	if ray.is_colliding():
		end = ray.get_collision_point()
		var hit = ray.get_collider()
		print("Hit: ", hit.name)
		if hit.has_method("take_damage"):
			hit.take_damage(20)
	else:
		end = $Camera3D.global_position - $Camera3D.global_transform.basis.z * 50
	show_tracer(start, end)
func show_tracer(start, end):
	var mesh = $Tracer
	var distance = start.distance_to(end)
	mesh.global_position = (start + end) / 2
	mesh.look_at(end, Vector3.UP)
	mesh.scale = Vector3(1, 1, distance)   # stretch the length-1 box to fit
	mesh.visible = true
	tracer_timer = 0.1
	
func add_gold(amount):
	gold += amount
	print("Gold: ", gold)
	update_gold_display()
	
func update_health_display():
	if not is_inside_tree():
		return
	var hp = get_tree().get_first_node_in_group("health_label")
	if hp: 
		hp.text = "Health" + str(health)

func die():
	print("YOU DIED!")
	get_tree().reload_current_scene()

func update_gold_display():
	var label = get_tree().get_first_node_in_group("gold_label")
	if label:
		label.text = "Gold: " + str(gold)
		
func _process(delta):
	if tracer_timer > 0:
		tracer_timer -= delta
		if tracer_timer <= 0:
			$Tracer.visible = false

func take_damage(amount):
	health -= amount
	print("Player health: ", health)
	if health <= 0:
		die()
	update_health_display()
		
