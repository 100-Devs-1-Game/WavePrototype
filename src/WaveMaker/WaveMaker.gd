extends Node
class_name WaveMaker

@export var water: Water
@export var game_mode : GameMode

var counter : float = 1
var time_tracker : float = 0
func _process(delta: float) -> void:
		time_tracker += delta
		if time_tracker > counter:
			time_tracker = 0
			call_one()		

func call_one():
	game_mode._on_wave_left_pressed()
	#game_mode._on_wave_right_pressed()
	#game_mode._on_wobble_pressed()
	#game_mode._on_noise_pressed()
	#game_mode._on_random_pit_pressed()
