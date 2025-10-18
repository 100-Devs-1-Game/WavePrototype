extends Area2D

signal start_round()
var started: bool = false
var explosion : PackedScene = preload("res://explosion/explosion.tscn")
func _on_area_entered(area: Area2D) -> void:
	if started:
		return
	
	started = true
	
	SfxPlayer.play_sound(0)

	start_round.emit()
	
	for i in 30:
		var offset : Vector2 = Vector2(randf_range(-450,450), randf_range(-450,450))
		var bomb = explosion.instantiate()
		bomb.global_position = global_position + offset
		get_tree().current_scene.add_child(bomb)
		await  get_tree().create_timer(0.03).timeout
	queue_free()
