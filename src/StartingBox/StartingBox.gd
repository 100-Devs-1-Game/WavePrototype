extends Area2D

signal start_round()

func _on_area_entered(area: Area2D) -> void:
	SfxPlayer.play_sound(0)

	start_round.emit()
	queue_free()
