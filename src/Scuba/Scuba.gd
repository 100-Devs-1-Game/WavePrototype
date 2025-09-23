extends CharacterBody2D

# Movement properties
@export var max_speed : float = 200.0
@export var acceleration : float = 400.0
@export var friction : float = 300.0

# Water surface restriction
@export var water_surface_y : float = 300.0  # Adjust to your water level
@export var surface_buffer : float = 2.0    # Allow a little leeway above water


func _physics_process(delta: float) -> void:
	handle_input(delta)
	apply_friction(delta)
	clamp_to_water_surface()
	move_and_slide()


func handle_input(delta: float) -> void:
	var input_vector := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1

	# Normalize for diagonal movement
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity += input_vector * acceleration * delta
		velocity = velocity.limit_length(max_speed)


func apply_friction(delta: float) -> void:
	if velocity.length() > 0.1:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		velocity = Vector2.ZERO


func clamp_to_water_surface() -> void:
	# Prevent diver from surfacing more than buffer above the water
	if position.y < water_surface_y - surface_buffer:
		position.y = water_surface_y - surface_buffer
		velocity.y = max(velocity.y, 0)  # Stop upward movement
