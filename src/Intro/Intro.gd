extends Node
#perhaps expand this to be more that a black circle shrinking
class_name Intro

@export var water: Water
@export var game_mode : GameMode
@export var spawner : Spawner

signal intro_finished()

func _ready() -> void:
	intro_finished.connect(Callable(spawner, "spawn_boat"))
	await get_tree().create_timer(1).timeout
	intro_finished.emit() #spawner spawns boat. what starts the game?
	SfxPlayer.play_sound_looped(3)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	pass
	#intro_finished.emit()
