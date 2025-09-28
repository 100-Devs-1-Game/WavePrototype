extends Node
class_name Spawner

@export var debug : bool = false

@export var water: Water
@export var game_mode : GameMode
@export var score_tracker : ScoreTracker


@export var vehicle : PackedScene = preload("res://JetSki/jet_ski.tscn")
@export var crate : PackedScene = preload("res://Crate/crate.tscn")
@export var sky_hoop : PackedScene = preload("res://SkyHoop/sky_hoop.tscn")

func spawn_boat():
	var temp_vehicle = vehicle.instantiate()
	temp_vehicle.water_path = water
	game_mode.add_child(temp_vehicle)
	temp_vehicle.global_position = Vector2(1000,0)
	temp_vehicle.get_node("BounceArea").bouncing.connect(Callable(score_tracker, "update_combo"))
	temp_vehicle.reset_timer.connect(Callable(score_tracker, "reset_combo"))
	score_tracker.vehicle = temp_vehicle
	score_tracker.vehicle_controller = temp_vehicle.get_node("Controller")
	
func spawn_crate():
	var temp_crate = crate.instantiate()
	temp_crate.water_path = water
	game_mode.add_child(temp_crate)
	temp_crate.global_position = Vector2(randf_range(10,5000),-100)
	temp_crate.get_node("BouncingArea").broken.connect(Callable(score_tracker,"update_score"))
	
func spawn_sky_hoop():
	var temp_hoop = sky_hoop.instantiate()
	game_mode.add_child(temp_hoop)
	temp_hoop.global_position = Vector2(randf_range(10,5000),randf_range(0,-600))
	temp_hoop.broken.connect(Callable(score_tracker,"update_score"))

func _on_spawn_crate_pressed() -> void:
	spawn_crate()

var counter : float = 0.5
var time_tracker : float = 0
func _process(delta: float) -> void:
		time_tracker += delta
		if time_tracker > counter:
			time_tracker = 0
			if debug:
				call_one()		

func call_one():
	spawn_crate()
	spawn_sky_hoop()
