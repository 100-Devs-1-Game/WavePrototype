extends Node2D

signal broken(point_value : int)
@export var life : int = 1
@export var points : int = 100

func _on_sky_detector_area_entered(area: Area2D) -> void:
	broken.emit(points)
	
	# Add a squish mostly horizontal stretch and shrink before queue_freeing
	await squish_and_break()
	queue_free()

func squish_and_break():
	var sprite = $Sprite2D  # Adjust path to your sprite node if different
	if not sprite:
		return  # Exit if no sprite found
	
	var tween = create_tween()
	var original_scale = sprite.scale
	
	# Sequential animation - each step waits for the previous to finish
	tween.set_parallel(false)
	# Step 1: Horizontal stretch with slight vertical squish
	var stretch_scale = Vector2(original_scale.x * 1.4, original_scale.y * 1.2)
	tween.tween_property(sprite, "scale", stretch_scale, 0.1)
	
	# Step 2: Shrink down to nothing (with parallel rotation and fade)
	  # Now allow parallel for the final effects
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.15)
	#tween.tween_property(sprite, "rotation", deg_to_rad(90), 0.15)  # Match duration
	
	# Optional: Fade out (match duration with others)
	#if sprite.has_method("set_modulate"):
		#tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	
	# Wait for animation to complete
	await tween.finished

# Alternative more dramatic version with proper sequencing
func squish_and_break_dramatic():
	var sprite = $Sprite2D
	if not sprite:
		return
	
	var tween = create_tween()
	var original_scale = sprite.scale
	
	# Sequential steps for precise timing
	
	# Step 1: Stretch horizontally
	var stretch_scale = Vector2(original_scale.x * 1.8, original_scale.y * 0.6)
	tween.tween_property(sprite, "scale", stretch_scale, 0.08)
	
	# Step 2: Quick vertical squish
	var mid_scale = Vector2(original_scale.x * 0.8, original_scale.y * 1.2)
	tween.tween_property(sprite, "scale", mid_scale, 0.06)
	
	# Step 3: Final shrink with parallel rotation and fade
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.12)
	tween.tween_property(sprite, "rotation", deg_to_rad(180), 0.12)  # Match duration
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)  # Match duration
	
	await tween.finished

# Alternative: Using tween chaining method
func squish_and_break_chained():
	var sprite = $Sprite2D
	if not sprite:
		return
	
	var original_scale = sprite.scale
	
	# Create separate tweens for each step
	var tween1 = create_tween()
	var stretch_scale = Vector2(original_scale.x * 1.4, original_scale.y * 0.8)
	tween1.tween_property(sprite, "scale", stretch_scale, 0.1)
	await tween1.finished
	
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(sprite, "scale", Vector2.ZERO, 0.15)
	tween2.tween_property(sprite, "rotation", deg_to_rad(90), 0.15)
	tween2.tween_property(sprite, "modulate:a", 0.0, 0.15)
	await tween2.finished
