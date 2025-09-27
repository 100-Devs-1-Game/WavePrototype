extends Node2D

var sprite_1 = preload("res://assets/blue_plant.png")
var sprite_2 = preload("res://assets/seaweed.png")
@onready var sprite = $Sprite2D

func _ready() -> void:
	var random_choice = randi() % 2
	
	if random_choice == 0:
		sprite.texture = sprite_1
	else:
		sprite.texture = sprite_2
