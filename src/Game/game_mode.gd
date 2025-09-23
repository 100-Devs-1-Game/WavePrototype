extends Node
class_name GameMode

@export var water : Water

func _on_wave_left_pressed() -> void:
	water.spawn_traveling_wave(0.0, randf_range(0.1,1), randf_range(1,100), 150.0, 1)  # Right-going wave

func _on_wave_right_pressed() -> void:
	water.spawn_traveling_wave(600.0,randf_range(0.1,1), randf_range(1,100), 150.0, -1)  # Left-going wave

func _on_wobble_pressed() -> void:
	water.add_traveling_wave(randf_range(1,50),randf_range(10,500), randf_range(1,100))
	
func _on_noise_pressed() -> void:
	water.add_wind_noise(randf_range(1,100))

func _on_random_pit_pressed() -> void:
	water.add_bump(randf_range(10,400),randf_range(1,100), randf_range(10,100) )
