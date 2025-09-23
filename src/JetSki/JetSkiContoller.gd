extends Node
class_name VehicleController

@export var vehicle: Vehicle
@export var acceleration: float = 200.0
@export var max_speed: float = 100.0
@export var dive_impulse: float = 400.0
@export var max_boost : float = 450

signal interacting()

var input_vector := Vector2.ZERO
var has_dived_this_air: bool = false

# Called when the vehicle collides with something it can bounce off
func reset_dive():
	has_dived_this_air = false
	bounce()

#Connected to vehicle to reset the dive mechanic 
#Might have some logic issues
func reset_dive_no_bounce():
	has_dived_this_air = false
	vehicle.was_above_water = true
	
func bounce():
		var vel_temp = vehicle.velocity.y
		vehicle.velocity.y = 0
		var calc_boost = abs(vel_temp) * 0.8
		if calc_boost > max_boost:
			calc_boost = max_boost 
		vehicle.velocity.y -= calc_boost
		var splash = preload("res://Scuba/splash_particle.tscn").instantiate()
		splash.global_position = get_parent().global_position
		splash.scale = Vector2.ONE
		get_tree().current_scene.add_child(splash)

func _ready() -> void:
	if vehicle == null:
		vehicle = get_parent() as Vehicle
		if vehicle == null:
			push_error("VehicleController: no Vehicle assigned or found!")
		vehicle.reset_timer.connect(Callable(self, "reset_dive_no_bounce" ))



func _physics_process(delta: float) -> void:
	if vehicle == null:
		return

	# --- Input handling ---
	input_vector = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1

	if Input.is_action_just_pressed("interact"):
		interacting.emit()

	input_vector = input_vector.normalized()

	# --- Apply horizontal thrust ---
	if input_vector.x != 0:
		vehicle.velocity.x += input_vector.x * acceleration * delta
	else:
		vehicle.velocity.x = move_toward(vehicle.velocity.x, 0, acceleration * delta)

	vehicle.velocity.x = clamp(vehicle.velocity.x, -max_speed, max_speed)

	# --- Dive impulse ---
	if Input.is_action_just_pressed("move_down")  and not has_dived_this_air: #and vehicle.was_above_water
		vehicle.velocity.y += dive_impulse
		has_dived_this_air = true

		var splash = preload("res://Scuba/splash_particle.tscn").instantiate()
		splash.global_position = get_parent().global_position
		splash.scale = Vector2.ONE
		get_tree().current_scene.add_child(splash)

	# --- Reset dive when splashing back into water ---
	if not vehicle.was_above_water:
		has_dived_this_air = false
