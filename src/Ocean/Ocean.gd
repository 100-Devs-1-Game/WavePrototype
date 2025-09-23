extends Node2D
var water_points = []
var water_width = 800
var num_points = 50
var spring_strength = 0.02
var damping = 0.90
var water_y = 300

func _ready():
	# Initialize water points
	for i in range(num_points):
		var point = {
			"x": i * (water_width / float(num_points)),
			"y": water_y,
			"velocity": 0.0,
			"target_y": water_y
		}
		water_points.append(point)

func _process(delta):
	# Apply spring forces
	for i in range(water_points.size()):
		var point = water_points[i]
		
		# Spring force toward rest position
		var force = (point.target_y - point.y) * spring_strength
		
		# Spring forces from neighbors
		if i > 0:
			var left_diff = water_points[i-1].y - point.y
			force += left_diff * spring_strength * 0.5
		
		if i < water_points.size() - 1:
			var right_diff = water_points[i+1].y - point.y
			force += right_diff * spring_strength * 0.5
		
		# Update velocity and position
		point.velocity += force
		point.velocity *= damping
		point.y += point.velocity
	
	queue_redraw()

func _draw():
	# Draw water surface
	var points_array = PackedVector2Array()
	for point in water_points:
		points_array.append(Vector2(point.x, point.y))
	
	# Add bottom points for filled water
	points_array.append(Vector2(water_width, 600))
	points_array.append(Vector2(0, 600))
	
	draw_colored_polygon(points_array, Color.CYAN)

func disturb_water(x_pos, force):
	# Find closest point and apply force
	var closest_index = int(x_pos / (water_width / float(num_points)))
	if closest_index >= 0 and closest_index < water_points.size():
		water_points[closest_index].velocity += force

 
#Optional: Add this method to your water script to get precise water height
func get_water_height_at(x_pos):
	var point_index = int(x_pos / (water_width / float(num_points)))
	if point_index >= 0 and point_index < water_points.size():
		return water_points[point_index].y
	return water_y
