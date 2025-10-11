extends Node
class_name VehicleController

@export var vehicle: Vehicle
@export var acceleration: float = 200.0
@export var max_speed: float = 100.0
@export var dive_impulse: float = 400.0
@export var max_boost : float = 1600


signal interacting()

var input_vector := Vector2.ZERO
var has_dived_this_air: bool = false

var sprite : AnimatedSprite2D
var rotation_tween: Tween
var target_rotation: float = 0.0
var rotation_speed: float = 0.2  # Adjust for faster/slower rotation



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
		squish_for_dive_dramatic()
		splash_effect()

func _ready() -> void:
	if vehicle == null:
		vehicle = get_parent() as Vehicle
		if vehicle == null:
			push_error("VehicleController: no Vehicle assigned or found!")
		vehicle.reset_timer.connect(Callable(self, "reset_dive_no_bounce" ))

	sprite = vehicle.get_node("Sprite2D")





var music_player = SfxPlayer.play_sound_looped(2)
func check_for_soar_anim_controller():
	if vehicle.soaring:
		sprite.play("flying")
		if music_player:
			return
		music_player = SfxPlayer.play_sound_looped(5)
		
	else:
		sprite.play("boat")
		if music_player:
			music_player.stop()
			music_player.queue_free()	
		



func _physics_process(delta: float) -> void:
	if vehicle == null:
		return

	# --- Input handling ---
	input_vector = Vector2.ZERO
	
	check_for_soar_anim_controller()

	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		target_rotation = -10
	elif Input.is_action_pressed("move_right"):
		input_vector.x += 1
		target_rotation = 10
	else:
		target_rotation = 0
	
	smooth_rotate_to_target(sprite)	
		
	# Soaring
	vehicle.soaring = Input.is_action_pressed("hover") and vehicle.was_above_water		
		
	#if Input.is_action_pressed("move_up"):
		#input_vector.y -= 1
	#if Input.is_action_pressed("move_down"):
		#input_vector.y += 1

		
		#don't use this for anything yet
	if Input.is_action_just_pressed("interact"):
		interacting.emit()

	input_vector = input_vector.normalized()

	# --- horizontal ---
	if input_vector.x != 0:
		vehicle.velocity.x += input_vector.x * acceleration * delta
	else:
		vehicle.velocity.x = move_toward(vehicle.velocity.x, 0, acceleration * delta)

	vehicle.velocity.x = clamp(vehicle.velocity.x, -max_speed, max_speed)

	# --- Dive impulse ---
	if Input.is_action_just_pressed("move_down")  and not has_dived_this_air: #and vehicle.was_above_water
		vehicle.velocity.y += dive_impulse
		has_dived_this_air = true
		#squish and pull the sprite.
		squish_for_dive_dramatic()
		dash_effect()
		


	# --- Reset dive when splashing back into water ---
	if not vehicle.was_above_water:
		has_dived_this_air = false
		

func squish_for_dive_dramatic():
	sprite.scale = Vector2.ONE
	var tween = create_tween()
	tween.set_parallel(true) #?
	
	var original_scale = sprite.scale
	var original_position = sprite.position
	
	# More dramatic squish with position offset
	var squish_scale = Vector2(original_scale.x * 0.1, original_scale.y * 2.4)
	var squish_offset = Vector2(0, 5)  # Slight downward push
	
	# Quick squish
	tween.tween_property(sprite, "scale", squish_scale, 0.08)
	tween.tween_property(sprite, "position", original_position + squish_offset, 0.08)
	
	# Bounce back with overshoot
	tween.tween_property(sprite, "scale", original_scale * 1.1, 0.12)
	tween.tween_property(sprite, "position", original_position, 0.12)
	
	# Settle to normal
	tween.tween_property(sprite, "scale", original_scale, 0.08)
	
	# Add rotation for impact feel
	tween.tween_property(sprite, "rotation", deg_to_rad(-8), 0.08)
	tween.tween_property(sprite, "rotation", deg_to_rad(3), 0.12)
	tween.tween_property(sprite, "rotation", 0, 0.08)
	
func splash_effect():
		var splash = preload("res://Scuba/splash_particle.tscn").instantiate()
		splash.global_position = get_parent().global_position
		splash.scale = Vector2.ONE
		get_tree().current_scene.add_child(splash)
		
func dash_effect():
	SfxPlayer.play_sound_varied(6,0.3,0.2)

func smooth_rotate_to_target(sprite: AnimatedSprite2D):
	# Kill existing tween if it exists
	if rotation_tween:
		rotation_tween.kill()
	
	# Create new tween
	rotation_tween = create_tween()
	rotation_tween.tween_property(sprite, "rotation_degrees", target_rotation, rotation_speed)

# Alternative version using lerp in _physics_process instead of tween
func _physics_process_lerp_version(delta: float) -> void:
	if vehicle == null:
		return
		
	var sprite : Sprite2D = vehicle.get_node("Sprite2D")
	
	# --- Input handling ---
	input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		target_rotation = -10
	elif Input.is_action_pressed("move_right"):
		input_vector.x += 1
		target_rotation = 10
	else:
		target_rotation = 0
	
	# Smoothly lerp rotation each frame
	sprite.rotation_degrees = lerp(sprite.rotation_degrees, target_rotation, 5.0 * delta)
	
	# ... rest of your physics code ...

# If you want different speeds for different directions
func smooth_rotate_to_target_variable_speed(sprite: Sprite2D):
	if rotation_tween:
		rotation_tween.kill()
	
	rotation_tween = create_tween()
	
	# Different speeds based on direction
	var speed = rotation_speed
	if target_rotation == 0:
		speed *= 0.7  # Slower return to center for more natural feel
	
	rotation_tween.tween_property(sprite, "rotation_degrees", target_rotation, speed)
