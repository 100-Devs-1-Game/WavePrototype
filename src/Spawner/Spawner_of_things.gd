extends Node
class_name Spawner

@export var debug : bool = false

@export var water: Water
@export var game_mode : GameMode
@export var score_tracker : ScoreTracker
@export var timer_for_round : TimerForRound


@export var vehicle : PackedScene = preload("res://JetSki/jet_ski.tscn")
@export var crate : PackedScene = preload("res://Crate/crate.tscn")
@export var sky_hoop : PackedScene = preload("res://SkyHoop/sky_hoop.tscn")


# Different spawn curve options
@export var max_crates_per_wave : int = 50
@export var min_crates_per_wave : int = 5
@export var total_waves : int = 6  # For a 2 minute round with 10 second intervals

var spawned_boxes = []

var bouncing_boat

func _ready() -> void:
	timer_for_round.new_box_spawn_wave.connect(Callable(self, "spawn_crate"))
	timer_for_round.game_finished.connect(Callable(self, "kill_all_boxes"))
	timer_for_round.new_gull.connect(Callable(self,"spawn_gull"))
	await get_tree().create_timer(0.4).timeout
	spawn_starting_gulls()
	
func spawn_starting_gulls():
	for i in 50:
			var temp_hoop = sky_hoop.instantiate()
			game_mode.add_child(temp_hoop)
			var x_to_spawn = float(randf_range(50,8990))
			var p_to_spawn = float(randf_range(-100,-900))
			temp_hoop.starting_y = p_to_spawn
			temp_hoop.global_position = Vector2(x_to_spawn, p_to_spawn) 
			temp_hoop.broken.connect(Callable(score_tracker,"update_score"))

func spawn_gull():
	pass

func spawn_boat():
	var temp_vehicle = vehicle.instantiate()
	temp_vehicle.water_path = water
	game_mode.add_child(temp_vehicle)
	temp_vehicle.global_position = Vector2(1000,0)
	temp_vehicle.get_node("BounceArea").bouncing.connect(Callable(score_tracker, "update_combo"))
	temp_vehicle.reset_timer.connect(Callable(score_tracker, "reset_combo"))
	score_tracker.vehicle = temp_vehicle
	score_tracker.vehicle_controller = temp_vehicle.get_node("Controller")
	bouncing_boat = temp_vehicle
	

func spawn_crate(count : int):
	# Calculate spawn amount based on wave progression
	var spawn_amount = calculate_spawn_amount(count)
	
	for i in spawn_amount:
		var temp_crate = crate.instantiate()
		temp_crate.water_path = water
		game_mode.add_child(temp_crate)
		temp_crate.global_position = Vector2(randf_range(10, 5000), -100)
		temp_crate.get_node("BouncingArea").broken.connect(Callable(score_tracker, "update_score"))	
		spawned_boxes.append(temp_crate)
		
func kill_all_boxes():
	for i in spawned_boxes:
		if i != null:
			i.get_node("BouncingArea").explode_no_points()
			i.queue_free()
			await get_tree().create_timer(0.01).timeout
	spawned_boxes.clear()
		
# Method 1: Smooth exponential curve (gradual then steep)
func calculate_spawn_amount(wave_count: int) -> int:
	var progress = float(wave_count) / float(total_waves)
	progress = clamp(progress, 0.0, 1.0)
	
	# Exponential curve: starts slow, ramps up at the end
	var curve_value = pow(progress, 2)  # Square for smooth acceleration
	
	var amount = min_crates_per_wave + int((max_crates_per_wave - min_crates_per_wave) * curve_value)
	return amount		
		
func spawn_sky_hoop():
	var temp_hoop = sky_hoop.instantiate()
	game_mode.add_child(temp_hoop)
	var p_to_spawn = float(randf_range(-100,-900))
	temp_hoop.starting_y = p_to_spawn
	temp_hoop.global_position = Vector2(-60, p_to_spawn) 
	temp_hoop.broken.connect(Callable(score_tracker,"update_score"))

func _on_spawn_crate_pressed() -> void:
	spawn_crate(1)

var counter : float = 0.5
var time_tracker : float = 0
func _process(delta: float) -> void:
		time_tracker += delta
		if time_tracker > counter:
			time_tracker = 0
			if debug:
				call_one()		

func call_one():
	#spawn_crate(1)
	spawn_sky_hoop()
