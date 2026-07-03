extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.003

var health := 100
var tracer_timer := 0.0
var gold := 0
var jump_velocity = 4
var is_reloading := false
var reload_timer := 0.0
var shake_amount := 0.0
@onready var cam_home = $Camera3D.position

var weapons = {
	"pistol": {
		"damage": 25,
		"fire_rate": 0.2,
		"automatic": false,
		"sound": preload("res://sounds/pistol_shot.wav"),
		"ammo": 12,
		"mag_size": 12,
		"range": 20
	},
	"shotgun": {
		"damage": 15,
		"fire_rate": 0.8,
		"pellets": 8,
		"automatic": false,
		"sound": preload("res://sounds/shotgun_shot.wav"),
		"ammo": 12,
		"mag_size": 4,
		"range": 4
	},
	"rifle": {
		"damage" : 35,
		"fire_rate": 0.2,
		"automatic": true,
		"sound": preload("res://sounds/sniper_shot.wav"),
		"ammo": 36,
		"mag_size" : 16,
		"range": 60
	},
	"sniper": {
		"damage" : 100,
		"fire_rate": 1.2,
		"automatic": false,
		"sound": preload("res://sounds/sniper_shot.wav"),
		"ammo": 8,
		"mag_size": 4,
		"range": 60
	}
}
var current_weapon := "pistol"
var owned_weapons := ["pistol"]
var fire_cooldown := 0.0



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var box = CylinderMesh.new()
	box.top_radius = 0.02
	box.bottom_radius = 0.02
	box.height = 1.0
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
	weapon_display()
	update_gun_model()
	update_ammo_count()
	fade_in()
	update_blood_overlay()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.5, 1.5)
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not weapons[current_weapon].get("automatic", false):
			shoot()
	if event is InputEventKey and event.pressed:
		var key_index = -1
		
		if event.keycode == KEY_1: key_index = 0
		elif event.keycode == KEY_2: key_index = 1
		elif event.keycode == KEY_3: key_index = 2
		elif event.keycode == KEY_4: key_index = 3
		elif event.keycode == KEY_5: key_index = 4
			
		if key_index >= 0 and key_index < owned_weapons.size():
			current_weapon = owned_weapons[key_index]
			weapon_display()
			update_gun_model()
			$Camera3D/AnimationPlayer.play("switch")
			
	if Input.is_action_just_pressed("reload"):
		start_reload()

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
	
	if Input.is_action_pressed("repair"):
		var barricades = get_tree().get_nodes_in_group("barricades")
		for b in barricades:
			if global_position.distance_to(b.global_position) < 3.0:
				b.repair(delta, self)
		
	
	if Input.is_action_just_pressed("interact"):
		var buys = get_tree().get_nodes_in_group("weapon_shops")
		var doors = get_tree().get_nodes_in_group("doors")
		for b in buys:
			if global_position.distance_to(b.global_position) < 3.0:
				b.try_buy(self)
		for c in doors:
			if global_position.distance_to(c.global_position) < 3.0:
				c.vanish(self)
			
func start_reload():
	var weapon = weapons[current_weapon]
	if is_reloading or weapon["ammo"] >= weapon["mag_size"]:
		return
	
	is_reloading = true
	reload_timer = 1.5
	$Camera3D/AnimationPlayer.play("switch")
	print("reloading...")
					

func finish_reload():
	weapons[current_weapon]["ammo"] = weapons[current_weapon]["mag_size"]
	is_reloading = false
	update_ammo_count()
	print("reloaded")	
		
func shoot():
	var weapon = weapons[current_weapon]
	if fire_cooldown > 0 or weapon["ammo"] == 0 or is_reloading:
		return
		
	
	fire_cooldown = weapon["fire_rate"]
	$GunSound.stream = weapon["sound"]
	$GunSound.pitch_scale = randf_range(0.9, 1.1)
	$GunSound.play()
	weapon["ammo"] -= 1
	update_ammo_count()
	var pellets = weapon.get("pellets", 1)
	for i in pellets:
		fire_one_ray(weapon["damage"], pellets > 1)
		
		
		
func fade_in():
	var overlay = $"../HUD/LoadingScreen"
	var text = $"../HUD/LoadingText"
	
	overlay.color.a = 1.0
	text.visible = true
	
	var start_rot = rotation.y
	var steps = 8
	
	for i in steps:
		rotation.y = start_rot + TAU * (float(i) / steps)
		await get_tree().process_frame
		await get_tree().process_frame
		
	rotation.y = start_rot
	
	await get_tree().create_timer(1.0).timeout
	
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 1.0)
	await tween.finished
	
	text.visible = false
	
func update_ammo_count():
	var label = get_tree().get_first_node_in_group("ammo_label")
	if label:
		label.text = "Ammo: " + str(weapons[current_weapon]["ammo"])
	
	
func fire_one_ray(damage, spread):
		var ray = $Camera3D/RayCast3D
		if spread:
			ray.target_position = Vector3(randf_range(-2, 2), randf_range(-2, 2), -40)
		else: 
			ray.target_position = Vector3(0, 0, -1000)
			
		ray.force_raycast_update()
		var muzzle = $Camera3D/GunHolder.get_node(current_weapon + "/Muzzle")
		
		var start = muzzle.global_position
		var end
		if ray.is_colliding():
			end = ray.get_collision_point()
			var hit = ray.get_collider()
			var dist = $Camera3D.global_position.distance_to(end)
			var max_range = weapons[current_weapon].get("range", 1000)
			if dist <= max_range and hit.has_method("take_damage"):
				hit.take_damage(damage)
			print("Hit: ", hit.name)
			
		else:
			end = $Camera3D.global_position - $Camera3D.global_transform.basis.z * 50
		show_tracer(start, end)
		
func show_tracer(start, end): 
	var mesh = $Tracer
	var distance = start.distance_to(end)
	mesh.global_position = (start + end) / 2
	mesh.look_at(end, Vector3.UP)
	mesh.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(90))
	mesh.scale = Vector3(1, distance, 1)   # stretch the length-1 box to fit
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
		hp.text = "Health: " + str(health)
	update_blood_overlay()
	
func update_blood_overlay():
	var blood = get_tree().get_first_node_in_group("blood_overlay")
	if blood:
		var t = 1.0 - (float(health / 100.0))
		blood.modulate.a = clamp(t, 0.0, 1.0)

func die():
	print("YOU DIED!")
	get_tree().reload_current_scene()

func update_gold_display():
	var label = get_tree().get_first_node_in_group("gold_label")
	if label:
		label.text = "Gold: " + str(gold)
		
func weapon_display():
	var label = get_tree().get_first_node_in_group("weapon_label")
	if label:
		label.text = "Weapon: " + str(current_weapon)
		
func update_gun_model():
	$Camera3D/GunHolder/pistol.visible = (current_weapon == "pistol")
	$Camera3D/GunHolder/shotgun.visible = (current_weapon == "shotgun")
	$Camera3D/GunHolder/sniper.visible = (current_weapon == "sniper")
	$Camera3D/GunHolder/rifle.visible = (current_weapon == "rifle")
func _process(delta):
	if weapons[current_weapon].get("automatic", false):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			shoot()
	
	if tracer_timer > 0:
		tracer_timer -= delta
		if tracer_timer <= 0:
			$Tracer.visible = false
			
	if fire_cooldown > 0:
		fire_cooldown -= delta
		
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			finish_reload()
			
	if shake_amount > 0:
		shake_amount -= delta * 5.0
		var offset = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			0
		) * shake_amount * 0.1
		$Camera3D.position = cam_home + offset
	else:
		$Camera3D.position = cam_home
		
func take_damage(amount):
	health -= amount
	shake_amount = 1.0
	print("Player health: ", health)
	if health <= 0:
		die()
	update_health_display()
		
