extends Node2D

@onready var front : CPUParticles2D = $Front

@onready var back : CPUParticles2D = $Back

func _ready() -> void:
	front.emitting = true
	back.emitting = true
	
