extends Node
class_name Intro

@export var water: Water
@export var game_mode : GameMode
@export var spawner : Spawner

@onready var camera : Camera2D = $Camera2D 

signal intro_finished()

func _ready() -> void:
	intro_finished.connect(Callable(spawner, "spawn_boat"))
	

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	intro_finished.emit()
