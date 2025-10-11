extends Area2D
class_name Bouncer

signal bouncing()
@onready var controller

func _ready():
	controller = get_parent().get_node("Controller")
	print(controller)
	bouncing.connect(Callable(controller, "reset_dive"))

func bounce():
	SfxPlayer.play_sound_varied(0, 0.2,0.1)
	bouncing.emit()
