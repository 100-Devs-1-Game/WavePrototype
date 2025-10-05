extends Label
class_name TimerForRound

@export var increment : float = 10.0
var increment_counter : float = 0.0
@export var time : float = 60.0#also connected to the UMM spawner timer
var time_has_started : bool = false
@export var excitement_label : Label

signal new_box_spawn_wave(count : int)
var box_spawn_wave_count : int = 1
signal do_ocean_madness
signal game_finished #where is this connected?

# Intro messages
@export var intro_messages : Array[String] = [
	"GET READY!",
	"SMASH BOXES!",
	"BUILD COMBOS!",
	"GO!"
]
@export var intro_message_duration : float = 0.8

# Event countdown messages
var countdown_messages : Array[String] = ["3", "2", "1", "GO!"]
var is_counting_event : bool = false

signal start_game_intro()

func _ready() -> void:
	text = format_time(time)

func start_intro_sequence():
	excitement_label.modulate.a = 0.0
	
	for i in range(intro_messages.size()):
		excitement_label.text = intro_messages[i]
		
		# Animate message in
		var tween_in = create_tween()
		tween_in.set_parallel(true)
		tween_in.tween_property(excitement_label, "modulate:a", 1.0, 0.2)
		tween_in.tween_property(excitement_label, "scale", Vector2.ONE * 1.5, 0.2)
		
		await tween_in.finished
		
		# Hold message
		await get_tree().create_timer(intro_message_duration).timeout
		
		# Animate message out
		var tween_out = create_tween()
		tween_out.set_parallel(true)
		tween_out.tween_property(excitement_label, "modulate:a", 0.0, 0.2)
		tween_out.tween_property(excitement_label, "scale", Vector2.ONE, 0.2)
		
		await tween_out.finished
	
	spawn_boxes()
	
	# Start the game
	time_has_started = true
	increment_counter = 0.0

func spawn_boxes():
	new_box_spawn_wave.emit(box_spawn_wave_count)
	box_spawn_wave_count += 1

func start_timer() -> bool:
	return time_has_started

func _physics_process(delta: float) -> void:
	if not start_timer():
		return
	
	# Countdown the main timer
	time -= delta
	text = format_time(time)
	
	# Check if time is up, and finish the round
	if time <= 0:
		time = 0
		text = format_time(0)
		finish()
		time_has_started = false
		return
	
	# Track increment for events (only when not already counting down)
	if not is_counting_event:
		increment_counter += delta
		
		# Check if we need to trigger events
		var time_until_next_event = increment - increment_counter
		
		# Start countdown warning at 3 seconds before event
		if time_until_next_event <= 3.0 and time_until_next_event > 2.9:
			start_event_countdown()
		# NOTE: Removed the immediate trigger here - countdown handles it now

func start_event_countdown():
	is_counting_event = true
	show_event_countdown()

func show_event_countdown():
	# Randomly choose which event to announce
	var event_type = randi() % 2
	var event_name = "BOX WAVE" if event_type == 0 else "OCEAN MADNESS"
	
	# Show "INCOMING" message
	excitement_label.text = event_name + " INCOMING!"
	animate_excitement_text(Color.ORANGE, 0.5)
	
	await get_tree().create_timer(0.5).timeout
	
	# Countdown 3, 2, 1
	for i in range(3):
		excitement_label.text = countdown_messages[i]
		
		var color = Color.YELLOW if i < 2 else Color.RED
		animate_excitement_text(color, 0.3)
		
		await get_tree().create_timer(0.8).timeout
	
	# THIS WAS MISSING! Call trigger_events after countdown finishes
	trigger_events()

func trigger_events():
	# Show GO! message
	excitement_label.text = "GO!"
	animate_excitement_text(Color.GREEN, 0.4)
	print("EVENT TRIGGERED")
	
	# Determine which events to trigger
	var trigger_madness = (box_spawn_wave_count % 3 == 0)  # Every 3rd wave
	var trigger_boxes = true
	
	# Add some randomness for variety
	if randf() > 0.7:
		trigger_madness = !trigger_madness
	
	# Emit signals
	if trigger_boxes:
		new_box_spawn_wave.emit(box_spawn_wave_count)
		show_event_effect("BOXES SPAWNED!", Color.GOLD)
	
	if trigger_madness:
		do_ocean_madness.emit()
		show_event_effect("OCEAN MADNESS!", Color.CYAN)
	
	box_spawn_wave_count += 1
	increment_counter = 0.0  # CRITICAL: Reset counter here!
	is_counting_event = false

func show_event_effect(message: String, color: Color):
	await get_tree().create_timer(0.5).timeout
	
	excitement_label.text = message
	animate_excitement_text(color, 0.6)

func animate_excitement_text(color: Color, duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Reset state
	excitement_label.modulate = color
	excitement_label.modulate.a = 0.0
	excitement_label.scale = Vector2.ZERO
	excitement_label.rotation = 0
	
	# Pop in
	tween.tween_property(excitement_label, "modulate:a", 1.0, 0.05)
	tween.tween_property(excitement_label, "scale", Vector2.ONE * 1.3, 0.05)
	
	# Slight bounce
	tween.tween_property(excitement_label, "scale", Vector2.ONE * 1.1, 0.1)
	
	# Gentle wiggle
	tween.tween_property(excitement_label, "rotation", deg_to_rad(5), 0.1)
	tween.tween_property(excitement_label, "rotation", deg_to_rad(-5), 0.1)
	tween.tween_property(excitement_label, "rotation", 0, 0.1)
	
	# Hold
	await get_tree().create_timer(duration).timeout
	
	# Fade out
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(excitement_label, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(excitement_label, "scale", Vector2.ZERO, 0.3)

func finish():
	show_finish_sequence()

func show_finish_sequence():
	game_finished.emit()
	# Final messages
	var finish_messages = [
		"TIME'S UP!",
		"CALCULATING...",
		"GREAT JOB!"
	]
	
	for message in finish_messages:
		excitement_label.text = message
		
		var color = Color.GOLD if message == "GREAT JOB!" else Color.WHITE
		animate_excitement_text(color, 2.0)
		
		await get_tree().create_timer(1.5).timeout
	
	# Return to main menu
	await get_tree().create_timer(0.5).timeout
	game_finished.emit()

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]
