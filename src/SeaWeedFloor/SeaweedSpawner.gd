extends Node

@export var seaweed : PackedScene = preload("res://SeaWeedFloor/sea_weed.tscn")

# Spawning parameters
@export var density: int = 50  # Number of seaweed instances to spawn
@export var floor_height: float = 500.0  # Y position of the ocean floor
@export var floor_range: Vector2 = Vector2(-1000, 1000)  # X range for spawning (min, max)
@export var height_variation: float = 50.0  # Random height variation above floor

# Optional parameters for more control
@export var spacing_variation: float = 0.3  # 0-1, how much spacing can vary
@export var scale_variation: Vector2 = Vector2(0.8, 1.2)  # Random scale range
@export var allow_overlap: bool = true  # Whether seaweed can overlap

func _ready() -> void:
	spawn_seaweed_floor()

func spawn_seaweed_floor():
	if not seaweed:
		print("Seaweed scene not loaded!")
		return
	
	# Calculate spacing between seaweed
	var total_width = floor_range.y - floor_range.x
	var base_spacing = total_width / density
	
	for i in range(density):
		# Calculate base position
		var x_pos = floor_range.x + (i * base_spacing)
		
		# Add some spacing variation for natural look
		if not allow_overlap:
			x_pos += randf_range(-base_spacing * spacing_variation * 0.5, 
								base_spacing * spacing_variation * 0.5)
		else:
			# More random placement if overlap is allowed
			x_pos += randf_range(-base_spacing * spacing_variation, 
								base_spacing * spacing_variation)
		
		# Random height variation above floor
		var y_pos = floor_height - randf_range(0, height_variation)
		
		# Create and position seaweed instance
		var seaweed_instance = seaweed.instantiate()
		seaweed_instance.global_position = Vector2(x_pos, y_pos)
		
		# Optional: Add scale variation for variety
		var random_scale = randf_range(scale_variation.x, scale_variation.y)
		seaweed_instance.scale = Vector2(random_scale, random_scale)
		
		# Optional: Random flip for more variety
		if randf() > 0.5:
			seaweed_instance.scale.x *= -1
		
		# Add to scene
		add_child(seaweed_instance)

# Optional: Function to clear and respawn seaweed
func respawn_seaweed():
	# Clear existing seaweed
	for child in get_children():
		if child.scene_file_path == seaweed.resource_path:
			child.queue_free()
	
	# Wait a frame then respawn
	await get_tree().process_frame
	spawn_seaweed_floor()

# Optional: Function to spawn seaweed in a specific area
func spawn_seaweed_in_area(area_start: float, area_end: float, area_density: int):
	var area_width = area_end - area_start
	var spacing = area_width / area_density
	
	for i in range(area_density):
		var x_pos = area_start + (i * spacing)
		x_pos += randf_range(-spacing * spacing_variation * 0.5, 
							spacing * spacing_variation * 0.5)
		
		var y_pos = floor_height - randf_range(0, height_variation)
		
		var seaweed_instance = seaweed.instantiate()
		seaweed_instance.global_position = Vector2(x_pos, y_pos)
		
		var random_scale = randf_range(scale_variation.x, scale_variation.y)
		seaweed_instance.scale = Vector2(random_scale, random_scale)
		
		if randf() > 0.5:
			seaweed_instance.scale.x *= -1
			
		add_child(seaweed_instance)
