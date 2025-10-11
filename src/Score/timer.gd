extends Label
class_name TimerForRound

@export var increment : float = 5.0
var increment_counter : float = 0.0
@export var time : float = 60.0#also connected to the UMM spawner timer
var time_has_started : bool = false
@export var excitement_label : Label

signal GameManagerDoWaterEvent

enum Possible_Events {
	Buoy,
	Ocean,
}
var current_event : Possible_Events = Possible_Events.Buoy
var current_event_index : int = 0


signal new_box_spawn_wave(count : int)
var box_spawn_wave_count : int = 1
signal do_ocean_madness(count : int) #where is this?
signal game_finished #where is this connected? in the spawner at least and score
signal new_gull
# Intro messages
@export var intro_messages : Array[String] = [
	"KILL SEAGULLS!",
	"SMASH BUOYS!",
	"BUILD COMBOS!",
	"GET POINTS!"
]
@export var intro_message_duration : float = 0.8

# Event countdown messages
var countdown_messages : Array[String] = ["3", "2", "1", ""]
var is_counting_event : bool = false

signal start_game_intro()

func _ready() -> void:
	text = format_time(time)

func start_intro_sequence():
	visible=true
	excitement_label.modulate.a = 0.0
	
	#loop through the messages, making the label exciting!
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
		await get_tree().create_timer(0.3).timeout #just a little buffer for 'feel'
	
	#then start the game
	spawn_boxes() #this sends a signal to the spawner
	get_parent().game_finished = false #this prevents scoring
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
	if not is_counting_event: #(counting down is a little timer message prepping the player for the next wave)
		increment_counter += delta
		
		# Check if we need to trigger events
		var time_until_next_event = increment - increment_counter
		
		# Start countdown warning at 3 seconds before event
		# This seems janky
		if time_until_next_event <= 3.0 and time_until_next_event > 2.9:
			start_event_countdown() #this is a coroutiene

func start_event_countdown():
	is_counting_event = true
	show_event_countdown()

func execute_current_event():
	print(current_event_index as Possible_Events)
	match current_event_index as Possible_Events:
		#Possible_Events.OPPWAVE:
		#	await handle_oppwave()
		Possible_Events.Buoy:
			await handle_spawn_boxes()
		Possible_Events.Ocean:
			await handle_om1()
		#Possible_Events.OM2:
		#	await handle_om2()
		#Possible_Events.OM3:
		#	await handle_om3()
			
	box_spawn_wave_count += 1
	current_event_index += 1
	# Wrap around to start if we've gone through all events
	if current_event_index >= Possible_Events.size():
		current_event_index = 0
	# coroutiene ends...
	#this starts the countdown timer again
	increment_counter = 0.0  # CRITICAL: Reset counter here!
	is_counting_event = false

func handle_oppwave():
	show_event_effect("WAVE!", Color.CYAN)
	print("EVENT: Opposite Wave!")
	# Add your opposite wave logic here


#>>>>>>>>>>>>>>>>>>>>>>
#just these 2....
func handle_spawn_boxes():
	new_box_spawn_wave.emit(box_spawn_wave_count)
	show_event_effect("Buoys Spawned", Color.GOLD)
	print("EVENT: Spawn Boxes!")
	# Add your box spawning logic here

func handle_om1():
	show_event_effect("MADDNESS", Color.GOLD)
	GameManagerDoWaterEvent.emit()
	print("EVENT: Ocean Madness 1!")
#>>>>>>>>>>>>>>>>>>>>>>


func handle_om2():
	show_event_effect("MADDNESS 2", Color.GOLD)
	print("EVENT: Ocean Madness 2!")

func handle_om3():
	show_event_effect("MADDNESS 3", Color.GOLD)
	print("EVENT: Ocean Madness 3!")

func reset_events():
	current_event_index = 0	
	
func get_current_event_name() -> String:
	return Possible_Events.find_key(current_event_index)
	
#this starts after the incriment countdown
func show_event_countdown():
	excitement_label.text = get_current_event_name() + " INCOMING!"
	animate_excitement_text(Color.ORANGE, 1)
	await get_tree().create_timer(2).timeout
	
	# Countdown 3, 2, 1
	for i in range(3):
		excitement_label.text = countdown_messages[i]
		
		var color = Color.YELLOW if i < 2 else Color.RED
		animate_excitement_text(color, 1)
		
		await get_tree().create_timer(1.5).timeout
	
	execute_current_event()
	
	
	#trigger_events()

func trigger_events():
	
	new_box_spawn_wave.emit(box_spawn_wave_count)
	show_event_effect("BOXES SPAWNED!", Color.GOLD)
	
	do_ocean_madness.emit(box_spawn_wave_count)
	show_event_effect("OCEAN MADNESS!", Color.CYAN)
	
	box_spawn_wave_count += 1
	
	# coroutiene ends...
	#this starts the countdown timer again
	increment_counter = 0.0  # CRITICAL: Reset counter here!
	is_counting_event = false

func show_event_effect(message: String, color: Color):
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
	await fade_tween.finished
	await get_tree().create_timer(0.1).timeout

func finish():
	show_finish_sequence()

func show_finish_sequence():
	# Final messages
	var finish_messages = [
		"TIME'S UP!",
		"CALCULATING...",
	]
	
	for message in finish_messages:
		excitement_label.text = message
		
		var color = Color.GOLD if message == "GREAT JOB!" else Color.WHITE
		animate_excitement_text(color, 2.0)
		
		await get_tree().create_timer(1.5).timeout
	

	await get_tree().create_timer(0.5).timeout
	game_finished.emit()
	visible=false
	#tells a few things to reset.
	#first tell the score to show the results...
	#so connect game_finished to score
	
func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]
