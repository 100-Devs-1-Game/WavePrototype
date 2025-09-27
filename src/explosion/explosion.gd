extends Sprite2D

func _ready() -> void:
	# Create a Tween node
	var tween := create_tween()
	
	scale = Vector2(0.1, 0.1)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.3) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(0.4).timeout
	queue_free()
