extends Node
class_name floatingScore

@onready var score_label : Label = $Label

func _ready() -> void:
	score_label.text = ""
	
func change_score(inscore : int):
	score_label.text = str(inscore)
