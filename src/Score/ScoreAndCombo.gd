extends Node
class_name ScoreTracker

@export var vehicle_controller : VehicleController
@export var vehicle : Vehicle

@onready var score_label : Label = $Score
@onready var combo_counter_label : Label = $ComboCounter
@onready var combo_confetti_label : Label = $ComboConfetti

var current_score : int = 0
var combo_tracker_score : int = 0

func update_score(points_to_add : int):
	current_score += points_to_add * combo_tracker_score
	score_label.text = str(current_score)
	
func update_combo():
	combo_tracker_score += 1
	combo_counter_label.text = str(combo_tracker_score)

func reset_combo():
	combo_tracker_score = 0
	combo_counter_label.text = ""	
	
func show_confetti():
	pass
	
	
