extends CharacterBody2D
class_name Vehicle

@export var debug_label : Label
@export var debug_label2 : Label

# NODE SETUP
@export var water_path: Water                 # link to your Water Node2D


# INTERNAL
var was_above_water := true

# SPLASH CONTROL
var splash_bounce_count: int = 0
var splash_reset_timer: float = 0.0
signal reset_timer()
@export var splash_reset_delay: float = 0.3  # time before bounce count resets

func _trigger_splash(pos: Vector2, size: float) -> void:
	# Water surface reaction  add *size if I want to later to make it larger or smaller based on velocity
	if splash_bounce_count > 1:
		water_path.add_pulse(pos.x, randf_range(1,4), randf_range(2,10))
	else:
		water_path.add_pulse(pos.x, randf_range(3,7), randf_range(5,20))
		
	# Visual particle effect
	var splash = preload("res://Scuba/splash_particle.tscn").instantiate()
	splash.global_position = pos
	splash.scale = Vector2.ONE
	get_tree().current_scene.add_child(splash)

func _ready() -> void:
	if water_path == null:
		print("assign water path")
		
func _physics_process(delta: float) -> void:
	if water_path == null:
		return

	# --- Water info ---
	var water_height = water_path.get_height(global_position.x)
	var submerged_depth = water_height - global_position.y

	# detect splash entry
	if was_above_water and submerged_depth < 0.0 and velocity.y > 100.0:
		splash_bounce_count += 1
		if splash_bounce_count <= 2:  # only allow first two bounces
			var splash_size = clamp(velocity.y / 500.0, 0.5, 2.0)
			_trigger_splash(global_position, splash_size)
		# reset timer on each entry
		splash_reset_timer = 0.0

	# reset bounce counter if we’ve been in water long enough
	if submerged_depth < 0.0:
		splash_reset_timer += delta
		if splash_reset_timer >= splash_reset_delay:
			splash_bounce_count = 0
			reset_timer.emit()

	was_above_water = submerged_depth >= 0.0
	
	# --- Gravity ---
	var gravity = 660.0
	velocity.y += gravity * delta

	# --- Buoyancy only when submerged ---
	if submerged_depth < 0.0:
		var buoyancy_strength = 100.0
		var damping = 3.0
		velocity.y += submerged_depth * buoyancy_strength * delta
		velocity.y -= velocity.y * damping * delta
	else:
		# --- Wave riding effect ---
		var ride_strength = 50.0
		var wave_slope = water_path.get_normal(global_position.x).y
		velocity.y -= wave_slope * ride_strength * delta
	
	# --- Horizontal drag ---
	var drag = 0.5
	velocity.x -= velocity.x * drag * delta

	# --- Traveling wave push ---
	var wave_push_strength = 4
	for wave in water_path.traveling_waves:
		var dist = global_position.x - wave.x
		if abs(dist) <= wave.width:
			var falloff = cos((dist / wave.width) * PI * 0.5)
			velocity.x += wave.direction * wave.amplitude * wave_push_strength * falloff * delta

	# --- Move the vehicle ---
	move_and_slide()

	debug_label.text = str(splash_bounce_count)
	debug_label2.text = str(splash_reset_timer)
	
	
