extends Node
class_name floatingScore

@onready var high_score_label : Label = $HighLabel
@onready var current_score_label : Label = $CurrentLabel

func _ready() -> void:
	high_score_label.text = ""
	current_score_label.text = ""
	
func change_score(currentinscore : int):
	current_score_label.text = str(currentinscore)

func change_high_score(new_high_score  : int):
	high_score_label.text = str(new_high_score)
