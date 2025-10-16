extends Node2D

var particle : PackedScene = preload("res://SkyHoop/seagull_smash_particle.tscn")

signal broken(point_value : int)
@export var life : int = 1
@export var points : int = 100
@export var animsprite : AnimatedSprite2D

# Movement settings
@export var speed : float = 100.0
@export var flight_height_variation : float = 20.0  # How much it bobs up and down
@export var bob_speed : float = 2.0  # Speed of up/down bobbing
@export var auto_despawn : bool = true
@export var despawn_distance : float = 11000.0

var starting_y : float
var time_elapsed : float = 0.0
var is_hit : bool = false

func _ready() -> void:
	animsprite.play("flap")
	animsprite.speed_scale = randf_range(0.9,1.1)
	
	# Optional: Random speed variation for each seagull
	speed += randf_range(-20, 20)
	
	# Optional: Random scale for variety
	var random_scale = randf_range(0.8, 1.2)
	scale = Vector2(random_scale, random_scale)

func _physics_process(delta: float) -> void:
	if is_hit:
		return  # Stop moving when hit
	
	# Move to the right
	position.x += speed * delta
	
	# Add bobbing motion (sine wave for natural flight)
	time_elapsed += delta
	var bob_offset = sin(time_elapsed * bob_speed) * flight_height_variation
	position.y = starting_y + bob_offset
	
	# Auto-remove when far off screen
	if auto_despawn and position.x > despawn_distance:
		queue_free()

func _on_sky_detector_area_entered(area: Area2D) -> void:
	if is_hit:
		return  # Prevent multiple hits
	
	#SfxPlayer.play_sound_varied(0, 0.2,0.1)
	SfxPlayer.play_sound_varied_2D(2, 0.2,0.1, global_position)


	is_hit = true
	broken.emit(points)
	animsprite.play("hit")
		
	var hit_particle = particle.instantiate()
	hit_particle.global_position = global_position
	get_tree().current_scene.add_child(hit_particle)
	
	await squish_and_break()
	queue_free()

func squish_and_break():
	var sprite = $Sprite2D  
	if not sprite:
		return  # Exit if no sprite found
	
	var tween = create_tween()
	var original_scale = sprite.scale
	
	# Sequential animation - each step waits for the previous to finish
	tween.set_parallel(false)
	
	# Step 1: Horizontal stretch with slight vertical squish
	var stretch_scale = Vector2(original_scale.x * 1.4, original_scale.y * 1.2)
	tween.tween_property(sprite, "scale", stretch_scale, 0.1)
	
	# Step 2: Shrink down to nothing 
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.15)
	
	# Optional: Spin while falling
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", deg_to_rad(180), 0.25)
	tween.tween_property(self, "position:y", position.y + 100, 0.25)  # Fall down
	
	# Wait for animation to complete
	await tween.finished

# Alternative: More realistic flight pattern
func _physics_process_realistic(delta: float) -> void:
	if is_hit:
		return
	
	# Move to the right
	position.x += speed * delta
	
	# More complex flight pattern with multiple sine waves
	time_elapsed += delta
	var primary_bob = sin(time_elapsed * bob_speed) * flight_height_variation
	var secondary_bob = sin(time_elapsed * bob_speed * 2.3) * (flight_height_variation * 0.3)
	position.y = starting_y + primary_bob + secondary_bob
	
	# Slight rotation based on vertical movement (tilts when going up/down)
	var vertical_velocity = cos(time_elapsed * bob_speed) * bob_speed * flight_height_variation
	animsprite.rotation = deg_to_rad(vertical_velocity * 2)  # Subtle tilt
	
	# Auto-remove when far off screen
	if auto_despawn and position.x > despawn_distance:
		queue_free()
