extends Node
class_name Spawner

@export var water: Water
@export var game_mode : GameMode
@export var score_tracker : ScoreTracker


@export var vehicle : PackedScene = preload("res://JetSki/jet_ski.tscn")
@export var crate : PackedScene = preload("res://Crate/crate.tscn")

func spawn_boat():
	var temp_vehicle = vehicle.instantiate()
	temp_vehicle.water_path = water
	game_mode.add_child(temp_vehicle)
	temp_vehicle.global_position = Vector2(100,400)
	temp_vehicle.get_node("BounceArea").bouncing.connect(Callable(score_tracker, "update_combo"))
	temp_vehicle.reset_timer.connect(Callable(score_tracker, "reset_combo"))
	
func spawn_crate():
	var temp_crate = crate.instantiate()
	temp_crate.water_path = water
	game_mode.add_child(temp_crate)
	temp_crate.global_position = Vector2(randf_range(10,980),420)
	temp_crate.get_node("BouncingArea").broken.connect(Callable(score_tracker,"update_score"))

func _on_spawn_crate_pressed() -> void:
	spawn_crate()

var counter : float = 0.5
var time_tracker : float = 0
func _process(delta: float) -> void:
		time_tracker += delta
		if time_tracker > counter:
			time_tracker = 0
			call_one()		

func call_one():
	spawn_crate()
