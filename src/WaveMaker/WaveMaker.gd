extends Node
class_name WaveMaker

@export var water: Water
@export var game_mode : GameMode

func make_ocean_madness(count : int):
	# Start wobble and noise on their own schedules
	count *= 2
	_trigger_wobbles(count)
	_trigger_noise(count)
	
	# Main loop hammers random pits
	for i in count:
		game_mode._on_random_pit_pressed()
		await get_tree().create_timer(0.1).timeout

func _trigger_wobbles(count : int):
	for i in count / 3:  # Wobble happens ~1/3 as often
		await get_tree().create_timer(randf_range(0.3, 0.8)).timeout
		game_mode._on_wobble_pressed()

func _trigger_noise(count : int):
	for i in count / 4:  # Noise happens ~1/4 as often
		await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
		game_mode._on_noise_pressed()

var counter : float = 5
var time_tracker : float = 0
func _process(delta: float) -> void:
		time_tracker += delta
		if time_tracker > counter:
			time_tracker = 0
			counter = randf_range(4,10)
			call_one()		

func call_one():
	game_mode._on_wave_left_pressed()
	#game_mode._on_wave_right_pressed()
	#game_mode._on_wobble_pressed()
	#game_mode._on_noise_pressed()
	#game_mode._on_random_pit_pressed()
