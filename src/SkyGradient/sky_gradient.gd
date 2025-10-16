extends TextureRect

# Gradient colors
@export var top_color : Color = Color(0.2, 0.6, 1.0)  # Light blue
@export var bottom_color : Color = Color(0.0, 0.1, 0.3)  # Dark blue

# Dimensions
@export var gradient_y_start : float = -10000
@export var gradient_height : float = 25000
@export var gradient_width : float = 11000

func _ready() -> void:
	setup_gradient()

func setup_gradient():
	# Set position and size
	position = Vector2(0, gradient_y_start)
	size = Vector2(gradient_width, gradient_height)
	
	# Create gradient
	var gradient = Gradient.new()
	gradient.set_color(0, top_color)  # Top color at offset 0
	gradient.set_color(1, bottom_color)  # Bottom color at offset 1
	
	# Create gradient texture
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)  # Start at top
	gradient_texture.fill_to = Vector2(0, 1)  # End at bottom (vertical gradient)
	gradient_texture.width = int(gradient_width)
	gradient_texture.height = int(gradient_height)
	
	# Apply texture to TextureRect
	texture = gradient_texture
	
	# Make sure it stretches to fill the area
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
