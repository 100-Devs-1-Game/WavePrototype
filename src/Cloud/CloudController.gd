extends Node2D

var sprite_1 = preload("res://assets/cloud1.png")
var sprite_2 = preload("res://assets/cloud2.png")
@onready var sprite = $Sprite2D
@export var speed : float = 10.0

# Optional: Auto-remove when off screen
@export var auto_despawn : bool = true
@export var despawn_distance : float = 6000.0  # How far off screen before removing

func _ready() -> void:
	var random_choice = randi() % 2
	
	if random_choice == 0:
		sprite.texture = sprite_1
	else:
		sprite.texture = sprite_2
	
	# Optional: Random scale variation for variety
	var random_scale = randf_range(0.8, 1.2)
	sprite.scale = Vector2(random_scale, random_scale)
	
	# Optional: Random opacity for depth effect
	sprite.modulate.a = randf_range(0.6, 1.0)

func _physics_process(delta: float) -> void:
	# Move to the right by speed
	position.x += speed * delta
	
	# Optional: Auto-remove when far off screen
	if auto_despawn and global_position.x > despawn_distance:
		queue_free()
