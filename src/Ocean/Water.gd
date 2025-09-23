extends Node2D
class_name Water

# ----------------------
# Tunable parameters
# ----------------------
@export var width: float = 1024.0      # total width of water surface
@export var samples: int = 500         # number of points in the surface (>= 2)
@export var base_y: float = 400.0      # calm water level
@export var spring_k: float = 40.0     # spring stiffness for displacement
@export var spring_damping: float = 6.0
@export var coupling: float = 8.0      # neighbor coupling constant

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

# ----------------------
# Update
# ----------------------
func _process(delta: float) -> void:
	elapsed_time += delta
	_update_springs(delta)
	_update_mesh()
	_update_traveling_waves(delta)

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


# ----------------------
# Rendering
# ----------------------
func _update_mesh() -> void:
	if has_node("Line2D"):
		var line := $Line2D
		line.clear_points()
		for i in range(samples):
			var h = _analytic_base_height(positions_x[i], elapsed_time) + displacements[i]
			line.add_point(Vector2(positions_x[i], h))
