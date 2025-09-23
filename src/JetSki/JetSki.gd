extends CharacterBody2D

# Movement properties
@export var max_speed = 300.0
@export var acceleration = 200.0
@export var friction = 50.0
@export var turn_speed = 1.0

# Water interaction properties
@export var dive_force = 500.0
@export var max_dive_depth = 500.0
@export var buoyancy_multiplier = 2.5
@export var water_drag = 0.95
@export var surface_water_y = 300.0  # Should match your water script's water_y

# Internal variables
var current_speed = 0.0
var is_underwater = false
var dive_depth = 0.0
var water_surface_node = null
var is_diving_input = false  # Track dive input state

func _ready():
	# Find the water surface node (assuming it's named "WaterSurface")
	water_surface_node = get_node("../Ocean")  # Adjust path as needed

func _physics_process(delta):
	handle_input(delta)
	handle_water_physics(delta)
	apply_movement(delta)
	move_and_slide()
	
	# Disturb water if we have a water surface node (only near surface)
	if water_surface_node and not is_underwater:
		var water_level = get_water_level_at_position(global_position.x)
		var distance_to_surface = abs(global_position.y - water_level)
		
		if distance_to_surface <= 16.0:  # Within 16 pixels of water surface
			var disturbance_force = abs(velocity.x) * 0.001 + abs(velocity.y) * 0.002
			water_surface_node.disturb_water(global_position.x, -disturbance_force)

func handle_input(delta):
	var input_vector = Vector2.ZERO
	
	#debug to check a 'drop'
	if Input.is_action_just_pressed("ui_cancel"):
		global_position = Vector2(150, 0)
	
	# Forward/Backward movement
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	
	# Dive input
	is_diving_input = Input.is_action_pressed("dive") or Input.is_action_pressed("ui_down")
	
	# Apply horizontal acceleration/deceleration
	if input_vector.x != 0:
		current_speed = move_toward(current_speed, input_vector.x * max_speed, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, 0, friction * delta)
	
	velocity.x = current_speed

func handle_water_physics(delta):
	var water_level = get_water_level_at_position(global_position.x)
	var depth_below_surface = global_position.y - water_level
	
	# Simple underwater check
	is_underwater = depth_below_surface > 10.0  # Small buffer to prevent flickering
	
	if is_underwater:
		# Apply water drag
		velocity *= water_drag
		
		# Diving vs Buoyancy
		if is_diving_input:
			# Player wants to dive - apply downward force
			velocity.y += dive_force * delta * 0.08
			
			# Track how deep we've gone for jump power
			if depth_below_surface > dive_depth:
				dive_depth = depth_below_surface
		else:
			# Player released dive - apply buoyancy based on depth
			var buoyancy_force = 550.0 + (dive_depth * 0.5)  # Deeper = more buoyancy
			velocity.y -= buoyancy_force * delta
	else:
		# Above water - apply gravity and reset dive depth
		velocity.y += 180.0 * delta
		
		# Allow diving even when above water (within reasonable range)
		if is_diving_input and depth_below_surface > -50.0:  # Can dive if within 50 pixels above water
			velocity.y += dive_force * delta * 0.06  # Slightly less force than underwater diving
		
		# Reset dive depth when we surface (but not if actively diving down)
		if not is_diving_input:
			dive_depth = 0.0
		
		# Optional: Surface following for small waves (only if not diving)
		if depth_below_surface > -30.0 and not is_diving_input:  # Close to surface and not diving
			var distance_from_surface = depth_below_surface
			var surface_follow_force = -distance_from_surface * 200.0 * delta
			velocity.y += surface_follow_force
			
func get_water_level_at_position(x_pos):
	# If we have a water surface node, get the actual water level
	if water_surface_node and water_surface_node.has_method("get_water_height_at"):
		return water_surface_node.get_water_height_at(x_pos)
	
	# Fallback to static water level
	return surface_water_y

func apply_movement(delta):
	# Rotate the sprite based on movement direction and water interaction
	var target_rotation = 0.0
	
	if is_underwater:
		# Tilt based on velocity direction when underwater
		target_rotation = velocity.normalized().angle()
		target_rotation = clamp(target_rotation, -PI/4, PI/4)
	else:
		# Slight tilt based on horizontal movement when above water
		target_rotation = velocity.x * 0.001
		target_rotation = clamp(target_rotation, -PI/6, PI/6)
	
	rotation = lerp_angle(rotation, target_rotation, turn_speed * delta)
