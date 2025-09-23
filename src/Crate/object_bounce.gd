extends Area2D

@export var life : int = 1
@export var points : int = 100

@export var size_offset: float = 5.0
@export var transfer_ratio: float = 1.0
@export var collision_cooldown: float = 0.1  # seconds, tweak to taste

@onready var velocity_holder: CharacterBody2D = get_parent()

var recent_collisions := {}  # id -> last_time

signal broken(point_value : int)

func _on_area_entered(area: Area2D) -> void:
	if not area.is_inside_tree():
		return

	var collision_velocity_holder: CharacterBody2D = area.get_parent()
	if collision_velocity_holder == null:
		return

	var id = collision_velocity_holder.get_instance_id()
	var now = Time.get_ticks_msec() / 1000.0

	# --- Cleanup old collisions ---
	for key in recent_collisions.keys():
		if now - recent_collisions[key] > collision_cooldown:
			recent_collisions.erase(key)

	# --- Collision cooldown ---
	if id in recent_collisions and now - recent_collisions[id] < collision_cooldown:
		return
	recent_collisions[id] = now

	# --- Case 1: landed on top ---
	if area.global_position.y < global_position.y - size_offset:
		if area.has_method("bounce"):
			area.bounce()
			velocity_holder.velocity = Vector2.ZERO
			velocity_holder.velocity.y += 150
			broken.emit(points)
			life -= 1
			if life <= 0 :
				velocity_holder.queue_free()
			else: #do effect
				pass
			return

	# --- Case 2: side bump (transfer momentum) ---
	var my_speed = abs(velocity_holder.velocity.x)
	var their_speed = abs(collision_velocity_holder.velocity.x)

	if their_speed > my_speed:
		# transfer their motion into me
		velocity_holder.velocity = collision_velocity_holder.velocity * transfer_ratio
		# let them keep some momentum so it feels natural
		collision_velocity_holder.velocity *= 0.8
