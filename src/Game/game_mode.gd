extends Node
class_name GameMode

@export var starting_box : PackedScene = preload("res://StartingBox/starting_collison.tscn")
@export var spawner : Spawner
@export var score : ScoreTracker
@export var timer_tracker : TimerForRound
@export var wave_maker : WaveMaker
@export var end_game_overlay : EndGameOverlay
@export var water : Water

func _ready() -> void:
	#set up the starting box...
	var temp_starter_box = starting_box.instantiate()
	temp_starter_box.global_position = Vector2(500,-100)
	temp_starter_box.start_round.connect(Callable(timer_tracker,"start_intro_sequence" ))
	temp_starter_box.start_round.connect(Callable(end_game_overlay, ("hide_scoreboard")))
	add_child(temp_starter_box)
	
	#game timer connections
	timer_tracker.do_ocean_madness.connect(Callable(wave_maker, "make_ocean_maddess"))
	timer_tracker.game_finished.connect(Callable(end_game_overlay,"stop_scoring"))
	timer_tracker.GameManagerDoWaterEvent.connect(Callable(self,"do_maddess"))
	

func do_maddess():
	water.spawn_traveling_wave(-400, randf_range(1,5), randf_range(500,1000), randf_range(150,550), -1)  # Right-going wave
	water.add_wind_noise(randf_range(1,100))
	for i in 10:
		water.add_bump(randf_range(10,400),randf_range(1,100), randf_range(10,100) )
		

#used in wave maker
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
