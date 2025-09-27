extends Node
class_name GameMode

@export var water : Water

func _on_wave_left_pressed() -> void:
	water.spawn_traveling_wave(-400, randf_range(1,5), randf_range(500,1000), randf_range(150,550), 1)  # Right-going wave

func _on_wave_right_pressed() -> void:
	water.spawn_traveling_wave(-400, randf_range(1,5), randf_range(500,1000), randf_range(150,550), -1)  # Right-going wave

func _on_wobble_pressed() -> void:
	water.add_traveling_wave(randf_range(1,50),randf_range(500,1000), randf_range(50,100))
	
func _on_noise_pressed() -> void:
	water.add_wind_noise(randf_range(1,100))

func _on_random_pit_pressed() -> void:
	water.add_bump(randf_range(10,400),randf_range(1,100), randf_range(10,100) )
