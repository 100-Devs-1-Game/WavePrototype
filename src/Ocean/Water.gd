extends Node
# ----------------------
# Alternative: Use vertex colors for gradient (more reliable)
# ----------------------extends Node2D
class_name Water

# ----------------------
# Tunable parameters
# ----------------------
@export var width: float = 5024.0      # total width of water surface
@export var samples: int = 50         # number of points in the surface (>= 2)
@export var base_y: float = 400.0      # calm water level
@export var spring_k: float = 40.0     # spring stiffness for displacement
@export var spring_damping: float = 6.0
@export var coupling: float = 8.0      # neighbor coupling constant

# Water appearance
@export var water_depth: float = 500.0  # how deep to render the water
@export var surface_color: Color = Color(0.3, 0.6, 1.0, 0.8)  # light blue, semi-transparent
@export var deep_color: Color = Color(0.1, 0.3, 0.6, 0.9)     # darker blue, more opaque

# Surface line appearance
@export var show_surface_line: bool = true
@export var surface_line_width: float = 3.0
@export var surface_line_color: Color = Color(0.8, 0.9, 1.0, 1.0)  # bright water surface

# sine waves for base motion
var sines := [
	{"A": 8.0,  "k": 0.004, "omega": 1.5, "phase": 0.0},
	{"A": 3.5,  "k": 0.020, "omega": 3.8, "phase": 1.0},
]

# ----------------------
# Internal state
# ----------------------
var dx: float
var positions_x: Array = []
var displacements: Array = []
var velocities: Array = []
var elapsed_time: float = 0.0

# For rendering
var water_polygon: Polygon2D
var surface_line: Line2D

# ----------------------
# Setup
# ----------------------
func _ready() -> void:
	if samples < 2:
		samples = 2   # safety
	dx = width / float(samples - 1)

	positions_x.resize(samples)
	displacements.resize(samples)
	velocities.resize(samples)

	for i in range(samples):
		positions_x[i] = i * dx
		displacements[i] = 0.0
		velocities[i] = 0.0
	
	# Create the water body polygon
	_setup_water_polygon()
	
	# Create the surface line
	_setup_surface_line()

# ----------------------
# Setup water polygon for gradient fill
# ----------------------
func _setup_water_polygon() -> void:
	water_polygon = Polygon2D.new()
	add_child(water_polygon)
	
	# Create gradient from surface to depth
	var gradient = Gradient.new()
	#gradient.clear()  # Clear any default points
	gradient.add_point(0.0, surface_color)  # Surface color at top
	gradient.add_point(1.0, deep_color)     # Deep color at bottom
	
	# Force gradient to update
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 256
	gradient_texture.height = 256
	gradient_texture.fill_from = Vector2(0.0, 0.0)  # Start from top
	gradient_texture.fill_to = Vector2(0.0, 1.0)    # End at bottom
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	
	# Force the texture to generate
	await gradient_texture.changed
	
	water_polygon.texture = gradient_texture
	
	# Alternative: Use vertex colors instead of texture
	_use_vertex_colors()

# ----------------------
# Update
# ----------------------
func _process(delta: float) -> void:
	elapsed_time += delta
	_update_springs(delta)
	_update_water_polygon()
	_update_surface_line()
	_update_traveling_waves(delta)

# ----------------------
# Setup surface line
# ----------------------
func _setup_surface_line() -> void:
	if not show_surface_line:
		return
		
	surface_line = Line2D.new()
	surface_line.width = surface_line_width
	surface_line.default_color = surface_line_color
	surface_line.joint_mode = Line2D.LINE_JOINT_ROUND
	surface_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(surface_line)

# ----------------------
# Update surface line
# ----------------------
func _update_surface_line() -> void:
	if not show_surface_line or not surface_line:
		return
		
	surface_line.clear_points()
	for i in range(samples):
		var h = _analytic_base_height(positions_x[i], elapsed_time) + displacements[i]
		surface_line.add_point(Vector2(positions_x[i], h))
# ----------------------
func _use_vertex_colors() -> void:
	# Don't use texture, use vertex colors instead
	water_polygon.texture = null
	water_polygon.vertex_colors = PackedColorArray()

# ----------------------
# Update water polygon shape
# ----------------------
func _update_water_polygon() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	
	# Find min and max Y for gradient calculation
	var min_y = INF
	var max_y = base_y + water_depth
	
	# First pass: find the actual min Y from surface points
	for i in range(samples):
		var h = _analytic_base_height(positions_x[i], elapsed_time) + displacements[i]
		if h < min_y:
			min_y = h
	
	# Add surface points (from left to right)
	for i in range(samples):
		var h = _analytic_base_height(positions_x[i], elapsed_time) + displacements[i]
		points.append(Vector2(positions_x[i], h))
		
		# Calculate gradient factor for this surface point
		var gradient_factor = (h - min_y) / (max_y - min_y)
		gradient_factor = clamp(gradient_factor, 0.0, 1.0)
		var color = surface_color.lerp(deep_color, gradient_factor)
		colors.append(color)
	
	# Add bottom points (from right to left to close the polygon)
	var bottom_y = base_y + water_depth
	points.append(Vector2(width, bottom_y))  # Bottom right
	colors.append(deep_color)  # Deep color at bottom
	
	points.append(Vector2(0, bottom_y))      # Bottom left  
	colors.append(deep_color)  # Deep color at bottom
	
	water_polygon.polygon = points
	water_polygon.vertex_colors = colors

# ----------------------
# Update texture coordinates for proper gradient mapping
# ----------------------
func _update_texture_coordinates() -> void:
	if not water_polygon:
		return
		
	var points = water_polygon.polygon
	var uvs: PackedVector2Array = PackedVector2Array()
	
	# Find the highest and lowest Y values for proper UV mapping
	var min_y = INF
	var max_y = -INF
	
	for point in points:
		if point.y < min_y:
			min_y = point.y
		if point.y > max_y:
			max_y = point.y
	
	# Create UV coordinates that map the gradient vertically
	for point in points:
		var u = point.x / width  # Horizontal UV (0 to 1 across width)
		var v = (point.y - min_y) / (max_y - min_y)  # Vertical UV (0 at surface, 1 at bottom)
		uvs.append(Vector2(u, v))
	
	water_polygon.uv = uvs

# ----------------------
# Wave Simulation
# ----------------------
func _update_springs(delta: float) -> void:
	for i in range(samples):
		var base = _analytic_base_height(positions_x[i], elapsed_time)
		var disp = displacements[i]
		var acc = -spring_k * disp - spring_damping * velocities[i]

		var left = displacements[i - 1] if i > 0 else disp
		var right = displacements[i + 1] if i < samples - 1 else disp
		acc += coupling * (left + right - 2.0 * disp)

		velocities[i] += acc * delta

	for i in range(samples):
		displacements[i] += velocities[i] * delta

# ----------------------
# Base Wave Function
# ----------------------
func _analytic_base_height(x: float, t: float) -> float:
	var sum := 0.0
	for s in sines:
		sum += s["A"] * sin(s["k"] * x - s["omega"] * t + s["phase"])
	return base_y + sum

# ----------------------
# Sampling Functions
# ----------------------
func get_height(world_x: float) -> float:
	var local_x = clamp(world_x, 0.0, width)
	var f = local_x / dx
	var i = clamp(int(f), 0, samples - 2)
	var alpha = clamp(f - i, 0.0, 1.0)

	var h0 = _analytic_base_height(positions_x[i], elapsed_time) + displacements[i]
	var h1 = _analytic_base_height(positions_x[i + 1], elapsed_time) + displacements[i + 1]

	return lerp(h0, h1, alpha)

func get_normal(world_x: float, sample_offset: int = 2) -> Vector2:
	var dx_sample = dx * float(sample_offset)
	var h_left = get_height(clamp(world_x - dx_sample, 0.0, width))
	var h_right = get_height(clamp(world_x + dx_sample, 0.0, width))

	var tangent = Vector2(2.0 * dx_sample, h_right - h_left).normalized()
	return Vector2(-tangent.y, tangent.x).normalized()

# ----------------------
# Wake / Disturbance Functions
# ----------------------

# small local pulse
func add_pulse(world_x: float, amplitude: float, radius: float = 64.0) -> void:
	_add_gaussian_bump(world_x, amplitude, radius)

# larger Gaussian bump
func add_bump(world_x: float, amplitude: float, width: float) -> void:
	_add_gaussian_bump(world_x, amplitude, width)

# internal helper for Gaussian bumps
func _add_gaussian_bump(world_x: float, amplitude: float, width: float) -> void:
	var left_idx = int(clamp((world_x - width) / dx, 0, samples - 1))
	var right_idx = int(clamp((world_x + width) / dx, 0, samples - 1))

	for i in range(left_idx, right_idx + 1):
		var dist = abs(positions_x[i] - world_x)
		var falloff = exp(-pow(dist / width, 2))  # smooth Gaussian
		displacements[i] += amplitude * falloff

# traveling waves
func add_traveling_wave(amplitude: float, wavelength: float, speed: float) -> void:
	for i in range(samples):
		var x = positions_x[i]
		var phase = speed * elapsed_time
		var wave = amplitude * sin((2.0 * PI / wavelength) * x - phase)
		displacements[i] += wave

# random wind noise
func add_wind_noise(strength: float = 5.0) -> void:
	for i in range(samples):
		displacements[i] += (randf() - 0.5) * strength

# change water level (e.g., tide)
func set_base_height(new_base: float) -> void:
	base_y = new_base

# ----------------------
# Color control functions
# ----------------------
func set_water_colors(new_surface_color: Color, new_deep_color: Color) -> void:
	surface_color = new_surface_color
	deep_color = new_deep_color
	# Colors will be updated on next frame via _update_water_polygon()

# ----------------------
# Control surface line visibility and appearance
# ----------------------
func set_surface_line_visible(visible: bool) -> void:
	show_surface_line = visible
	if surface_line:
		surface_line.visible = visible

func set_surface_line_color(color: Color) -> void:
	surface_line_color = color
	if surface_line:
		surface_line.default_color = color

func set_surface_line_width(width: float) -> void:
	surface_line_width = width
	if surface_line:
		surface_line.width = width

# ----------------------
# Traveling Wave Data
# ----------------------
class TravelingWave:
	var x: float
	var amplitude: float
	var width: float
	var speed: float
	var direction: int = 1  # 1 = right, -1 = left

# Active waves list
var traveling_waves: Array = []

# ----------------------
# Spawn a traveling wave
# ----------------------
func spawn_traveling_wave(start_x: float, amplitude: float, width: float, speed: float, direction: int = 1) -> void:
	var wave = TravelingWave.new()
	wave.x = start_x
	wave.amplitude = amplitude
	wave.width = width
	wave.speed = speed
	wave.direction = direction
	traveling_waves.append(wave)

# ----------------------
# Update traveling waves
# ----------------------
func _update_traveling_waves(delta: float) -> void:
	for wave in traveling_waves:
		# Move the wave
		wave.x += wave.speed * wave.direction * delta

		# Apply wave displacement to water points
		var left_idx = int(clamp((wave.x - wave.width) / dx, 0, samples - 1))
		var right_idx = int(clamp((wave.x + wave.width) / dx, 0, samples - 1))

		for i in range(left_idx, right_idx + 1):
			var dist = abs(positions_x[i] - wave.x)
			if dist <= wave.width:
				var falloff = cos((dist / wave.width) * PI * 0.5)  # smooth fade
				displacements[i] += wave.amplitude * falloff * sin((dist / wave.width) * PI)

	# Remove waves that have fully left the water
	traveling_waves = traveling_waves.filter(func(w):
		return w.x + w.width >= 0 and w.x - w.width <= width)
