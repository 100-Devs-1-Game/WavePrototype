extends Node
@onready var body_parent : CharacterBody2D = get_parent()

func _physics_process(delta: float) -> void:
	if body_parent.global_position.x < 0:
		body_parent.global_position.x = 0
	elif body_parent.global_position.x > 1000:
		body_parent.global_position.x = 1000
		
