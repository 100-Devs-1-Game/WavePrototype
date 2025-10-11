extends Node2D

@onready var front : CPUParticles2D = $Front

@onready var back : CPUParticles2D = $Back

func _ready() -> void:
	SfxPlayer.play_sound_varied(0, 0.3, 0.1)

	front.emitting = true
	back.emitting = true
	await get_tree().create_timer(1).timeout
	queue_free()	
