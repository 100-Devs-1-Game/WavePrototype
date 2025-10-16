extends Node
class_name ScoreTracker

@export var vehicle_controller : VehicleController
@export var vehicle : Vehicle
@onready var score_label : Label = $Score
@onready var combo_counter_label : Label = $ComboCounter
@onready var combo_confetti_label : Label = $ComboConfetti
@onready var height_label : Label = $Height
@onready var highest_height_label : Label = $Highest_Height
@onready var timer_coutner : TimerForRound = $Timer
@onready var endgame_overlay : EndGameOverlay = $EndgameOverlay

var combo_tracker_score : int = 0

# Animation settings
@export var score_bounce_scale: float = 1.3
@export var combo_pulse_scale: float = 1.4
@export var confetti_messages: Array[String] = ["NICE!", "COMBO!", "AWESOME!", "AMAZING!", "INCREDIBLE!"]

var game_finished : bool = false
signal score_result(finalscore : int) 


func _ready() -> void:
	game_finished = true
	timer_coutner.game_finished.connect(Callable(self, "stop_scoring"))

var highest_height : float = 0 #updated as you play the game
var current_score : int = 0 #updated as you play the game

func stop_scoring():
	game_finished = true
#	endgame_overlay.highest_height = highest_height 
	endgame_overlay.current_score = current_score
	endgame_overlay.game_finished = game_finished

func _process(delta: float) -> void:
	if not game_finished and vehicle != null:
		
		var current_height = abs(vehicle.global_position.y)
		var result = "%.1f" % current_height
		if current_height > highest_height:
			highest_height = current_height
			var height_result = "%.1f" % highest_height
			highest_height_label.text = str(height_result)
			
		height_label.text = str(result)
	
	
func update_score(points_to_add : int):
	if game_finished:
		return
	var current_height = abs(vehicle.global_position.y)
#	height_label.text = str(current_height)
	var final_points = points_to_add
	
	if combo_tracker_score > 0:
		final_points = points_to_add * combo_tracker_score
	
	# Animate the score counting up
	animate_score_count_up(final_points)
	
	# Extra juice for combo scores
	if combo_tracker_score > 1:
		animate_combo_score()

# Settings for counting animation
@export var count_increment: int = 10  # How much to add per step (1, 5, 10, etc.)
@export var count_speed: float = 0.02  # Time between increments (lower = faster)
@export var min_count_time: float = 0.5  # Minimum time for counting (for small scores)
@export var max_count_time: float = 2.0  # Maximum time for counting (for huge scores)

# Score display formatting settings
@export var use_abbreviated_numbers: bool = true  # Show 1.2K instead of 1200
@export var max_digits_before_abbreviation: int = 4  # Abbreviate after 9999
@export var decimal_places: int = 1  # How many decimals for abbreviated (1.2K vs 1.23K)

# Text scaling settings
@export var max_score_width: float = 200.0  # Maximum width before scaling down
@export var min_scale_factor: float = 0.5  # Don't scale smaller than this
@export var auto_scale_text: bool = true  # Enable automatic text scaling

func animate_score_count_up(points_to_add: int):
	if game_finished:
		return
	var start_score = current_score
	var target_score = current_score + points_to_add
	
	# Calculate counting parameters
	var steps = max(1, points_to_add / count_increment)
	var total_time = clamp(steps * count_speed, min_count_time, max_count_time)
	var time_per_step = total_time / steps
	
	# Store original scale for bounce animations
	var original_scale = Vector2.ONE  # Base scale before any auto-scaling
	
	# Bounce effect at start
	var bounce_tween = create_tween()
	bounce_tween.set_parallel(true)
	
	# Calculate what the scale should be for current text
	var temp_text = format_score_text(target_score)
	var needed_scale = calculate_needed_scale(temp_text)
	original_scale = Vector2(needed_scale, needed_scale)
	
	bounce_tween.tween_property(score_label, "scale", original_scale * score_bounce_scale, 0.1)
	bounce_tween.tween_property(score_label, "scale", original_scale, 0.2)
	
	# Start counting
	counting_tween = create_tween()
	
	# Count up in increments
	for i in range(int(steps)):
		var progress = float(i + 1) / float(steps)
		var current_target = start_score + int(points_to_add * progress)
		
		counting_tween.tween_method(update_score_display, current_score, current_target, time_per_step)
		counting_tween.tween_callback(func(): current_score = current_target)
		
		# Add little bounce every few increments for big scores
		if points_to_add > 500 and i % 5 == 0:
			counting_tween.tween_callback(mini_bounce_scaled)
	
	# Ensure we hit the exact final score
	counting_tween.tween_callback(func(): 
		current_score = target_score
		score_label.text = format_score_text(current_score)
		auto_scale_score_text()  # Final scale adjustment
		final_score_effect(points_to_add)
		counting_tween = null  # Clear counting state
	)

func calculate_needed_scale(text: String) -> float:
	if not auto_scale_text:
		return 1.0
	
	var font = score_label.get_theme_font("font")
	var font_size = score_label.get_theme_font_size("font_size")
	
	var text_size = font.get_string_size(
		text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		font_size
	)
	
	var scale_factor = 1.0
	if text_size.x > max_score_width:
		scale_factor = max_score_width / text_size.x
		scale_factor = max(scale_factor, min_scale_factor)
	
	return scale_factor

func mini_bounce_scaled():
	if not is_counting_active():
		return
		
	var current_scale = score_label.scale
	var mini_tween = create_tween()
	mini_tween.tween_property(score_label, "scale", current_scale * 1.1, 0.05)
	mini_tween.tween_property(score_label, "scale", current_scale, 0.05)

func update_score_display(score: int):
	if game_finished:
		return
	score_label.text = format_score_text(score)
	
	# Auto-scale text if it's too wide
	if auto_scale_text:
		auto_scale_score_text()

func auto_scale_score_text():
	# Get the text size
	var font = score_label.get_theme_font("font")
	var font_size = score_label.get_theme_font_size("font_size")
	
	var text_size = font.get_string_size(
		score_label.text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		font_size
	)
	
	# Calculate scale factor based on width
	var scale_factor = 1.0
	if text_size.x > max_score_width:
		scale_factor = max_score_width / text_size.x
		scale_factor = max(scale_factor, min_scale_factor)
	
	# Apply scale smoothly
	var target_scale = Vector2(scale_factor, scale_factor)
	
	# Don't tween during counting animation, just set it
	if not is_counting_active():
		var scale_tween = create_tween()
		scale_tween.tween_property(score_label, "scale", target_scale, 0.1)
	else:
		score_label.scale = target_scale

# Track if we're currently counting to avoid scale conflicts
var counting_tween: Tween
func is_counting_active() -> bool:
	return counting_tween != null and counting_tween.is_valid()

func format_score_text(score: int) -> String:
	if not use_abbreviated_numbers or score < pow(10, max_digits_before_abbreviation):
		return str(score)
	
	# Determine the appropriate suffix and divisor
	var suffixes = ["", "K", "M", "B", "T", "Q"]  # Thousand, Million, Billion, Trillion, Quadrillion
	var divisors = [1, 1000, 1000000, 1000000000, 1000000000000, 1000000000000000]
	
	var suffix_index = 0
	var display_value = float(score)
	
	# Find the appropriate suffix
	for i in range(divisors.size() - 1, 0, -1):
		if score >= divisors[i]:
			suffix_index = i
			display_value = float(score) / float(divisors[i])
			break
	
	# Format the number
	if suffix_index == 0:
		return str(score)  # No abbreviation needed
	
	# Round to specified decimal places
	var format_string = "%." + str(decimal_places) + "f%s"
	var result = format_string % [display_value, suffixes[suffix_index]]
	
	# Remove trailing zeros after decimal point
	if decimal_places > 0 and "." in result:
		result = result.rstrip("0").rstrip(".")
	
	return result

# Alternative: Simple K/M formatting function
func format_score_simple(score: int) -> String:
	if score >= 1000000:
		var millions = float(score) / 1000000.0
		if millions >= 10:
			return str(int(millions)) + "M"
		else:
			return ("%.1f" % millions).rstrip("0").rstrip(".") + "M"
	elif score >= 1000:
		var thousands = float(score) / 1000.0
		if thousands >= 10:
			return str(int(thousands)) + "K"
		else:
			return ("%.1f" % thousands).rstrip("0").rstrip(".") + "K"
	else:
		return str(score)

func final_score_effect(points_gained: int):
	# Color flash for big scores at the end
	var flash_color = Color.WHITE
	if points_gained >= 1000:
		flash_color = Color.PURPLE
		epic_score_effect()
	elif points_gained >= 500:
		flash_color = Color.GOLD
		screen_shake(5.0, 0.2)
	elif points_gained >= 200:
		flash_color = Color.ORANGE
		
	if points_gained >= 200:
		var flash_tween = create_tween()
		flash_tween.tween_property(score_label, "modulate", flash_color, 0.05)
		flash_tween.tween_property(score_label, "modulate", Color.WHITE, 0.15)

func animate_combo_score():
	if game_finished:
		return
	# Extra sparkle for combo scores
	var tween = create_tween()
	tween.set_parallel(true)
	# Rotation wiggle
	tween.tween_property(score_label, "rotation", deg_to_rad(5), 0.05)
	tween.tween_property(score_label, "rotation", deg_to_rad(-5), 0.05)
	tween.tween_property(score_label, "rotation", 0, 0.05)

func update_combo():
	if game_finished:
		return
	combo_tracker_score += 1
	combo_counter_label.text = str(combo_tracker_score) + "x"
	
	# Animate combo counter
	animate_combo_update()
	
	# Show confetti for high combos
	if combo_tracker_score >= 3:
		show_confetti()

func animate_combo_update():
	if game_finished:
		return
	var tween = create_tween()
	tween.set_parallel(true)
	
	var original_scale = combo_counter_label.scale
	
	# Pulse effect
	tween.tween_property(combo_counter_label, "scale", original_scale * combo_pulse_scale, 0.08)
	tween.tween_property(combo_counter_label, "scale", original_scale, 0.12)
	
	# Color progression based on combo level
	var combo_color = Color.WHITE
	if combo_tracker_score >= 10:
		combo_color = Color.PURPLE
	elif combo_tracker_score >= 7:
		combo_color = Color.GOLD
	elif combo_tracker_score >= 5:
		combo_color = Color.ORANGE
	elif combo_tracker_score >= 3:
		combo_color = Color.YELLOW
	
	if combo_tracker_score >= 3:
		tween.tween_property(combo_counter_label, "modulate", combo_color, 0.1)

func reset_combo():
	# Animate combo reset
	if combo_tracker_score > 0:
		animate_combo_reset()
	
	combo_tracker_score = 0
	
	# Delayed clear to allow animation
	await get_tree().create_timer(0.3).timeout
	combo_counter_label.text = ""
	combo_counter_label.modulate = Color.WHITE

func animate_combo_reset():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Shrink and fade
	tween.tween_property(combo_counter_label, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(combo_counter_label, "modulate:a", 0.0, 0.2)
	
	# Reset scale and alpha after animation
	await tween.finished
	combo_counter_label.scale = Vector2.ONE
	combo_counter_label.modulate.a = 1.0

func show_confetti():
	if game_finished:
		return
	if confetti_messages.is_empty():
		return
	
	# Pick random confetti message
	var message = confetti_messages[randi() % confetti_messages.size()]
	combo_confetti_label.text = message
	
	animate_confetti()

func animate_confetti():
	if game_finished:
		return
	var tween = create_tween()
	tween.set_parallel(true)
	#SfxPlayer.play_sound(7)
	
	# Reset state
	combo_confetti_label.scale = Vector2.ZERO
	combo_confetti_label.modulate = Color.WHITE
	combo_confetti_label.rotation = 0
	
	# Pop in with bounce
	tween.tween_property(combo_confetti_label, "scale", Vector2.ONE * 1.5, 0.2)
	tween.tween_property(combo_confetti_label, "scale", Vector2.ONE * 1.2, 0.1)
	
	# Rainbow color cycle
	tween.tween_property(combo_confetti_label, "modulate", Color.RED, 0.1)
	tween.tween_property(combo_confetti_label, "modulate", Color.ORANGE, 0.1)
	tween.tween_property(combo_confetti_label, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(combo_confetti_label, "modulate", Color.GREEN, 0.1)
	tween.tween_property(combo_confetti_label, "modulate", Color.BLUE, 0.1)
	
	# Gentle spin
	tween.tween_property(combo_confetti_label, "rotation", deg_to_rad(360), 0.8)
	
	# Hold for a moment
	await get_tree().create_timer(1.0).timeout
	
	# Fade out
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(combo_confetti_label, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(combo_confetti_label, "scale", Vector2.ZERO, 0.3)
	
	await fade_tween.finished
	combo_confetti_label.text = ""

# Bonus: Screen shake effect for big scores
func screen_shake(intensity: float = 5.0, duration: float = 0.2):
	var tree = get_tree()
	if not tree:
		return
		
	var camera = tree.get_first_node_in_group("camera")  # Add camera to "camera" group
	if not camera:
		# Fallback: find any Camera2D in the scene
		camera = tree.get_nodes_in_group("camera2d").front() if tree.get_nodes_in_group("camera2d").size() > 0 else null
	
	if not camera:
		return
	
	var tween = create_tween()
	var original_offset = camera.offset
	
	# More efficient shake using fewer tween calls
	var shake_steps = int(duration * 30)  # 30 steps per second
	for i in range(shake_steps):
		var progress = float(i) / float(shake_steps)
		var fade_intensity = intensity * (1.0 - progress)  # Fade out shake
		
		var shake_offset = Vector2(
			randf_range(-fade_intensity, fade_intensity),
			randf_range(-fade_intensity, fade_intensity)
		)
		tween.tween_property(camera, "offset", original_offset + shake_offset, duration / shake_steps)
	
	# Return to original position
	tween.tween_property(camera, "offset", original_offset, 0.05)

# Call this for massive scores (like 1000+ points)
func epic_score_effect():
	if game_finished:
		return
	screen_shake(10.0, 0.4)
	
	# Flash the entire screen briefly
	var tree = get_tree()
	if not tree:
		return
		
	var root = tree.current_scene
	if not root:
		return
	
	# Create flash overlay
	var flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0.3)
	flash_rect.anchors_preset = Control.PRESET_FULL_RECT  # Fill entire screen
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	
	# Add to the root scene temporarily
	root.add_child(flash_rect)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.2)
	await flash_tween.finished
	flash_rect.queue_free()
