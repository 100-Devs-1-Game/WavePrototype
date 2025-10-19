extends Control
class_name EndGameOverlay

var highest_score_record : float = 0
#var highest_height_record : float = 0
#var highest_height : float = 0  # Updated as you play the game
var current_score : int = 0  # Updated as you play the game
var game_finished : bool = false
signal loaded_score(high_score: int)

# UI Node references - set these in the editor or _ready
@onready var overlay = $GameOverOverlay
@onready var result_label = $GameOverOverlay/ResultLabel
@onready var score_current_label = $GameOverOverlay/ScorePanel/CurrentScore
@onready var score_best_label = $GameOverOverlay/ScorePanel/BestScore
@onready var score_new_badge = $GameOverOverlay/ScorePanel/NewBadge
@onready var height_current_label = $GameOverOverlay/HeightPanel/CurrentHeight
@onready var height_best_label = $GameOverOverlay/HeightPanel/BestHeight
@onready var height_new_badge = $GameOverOverlay/HeightPanel/NewBadge
@onready var message_label = $GameOverOverlay/MessageLabel
@onready var play_again_button = $GameOverOverlay/PlayAgainButton
@onready var menu_button = $GameOverOverlay/MenuButton

func _ready():
	# Load saved records
	load_records()
	
	# Hide overlay initially
	overlay.visible = false
	
	# Connect buttons
	play_again_button.pressed.connect(_on_play_again)
	menu_button.pressed.connect(quit_game)
	display_text_on_start()
	

func hide_scoreboard():
	visible=false

func stop_scoring():
	visible=true
	game_finished = true
	
	# Check for new records
	var new_score_record = current_score > highest_score_record
	#var new_height_record = highest_height > highest_height_record
	var any_new_record = new_score_record #or new_height_record
	
	# Update records if beaten
	if new_score_record:
		highest_score_record = current_score
		celebrate_new_record("score")
		loaded_score.emit(highest_score_record)
	
	#if new_height_record:
		#highest_height_record = highest_height
		#celebrate_new_record("height")
	
	# Save new records
	save_records()
	
	# Show overlay with results
	show_game_over_overlay(new_score_record, any_new_record) #removed height

func show_game_over_overlay(new_score: bool, any_record: bool):
	# Show overlay
	overlay.visible = true
	loaded_score.emit(highest_score_record)
	
	# Set header message
	if any_record:
		result_label.text = "AMAZING!"
		result_label.modulate = Color.GOLD
		message_label.text = "A NEW RECORD!"
	else:
		result_label.text = "TIME'S UP!"
		result_label.modulate = Color.WHITE
		message_label.text = "Nope! Try again!"
	
	# Animate header
	animate_result_label()
	
	# Set score values
	score_current_label.text = str(current_score)
	score_best_label.text = str(int(highest_score_record))
	score_new_badge.visible = new_score
	
	if new_score:
		score_current_label.modulate = Color.GOLD
		animate_badge(score_new_badge)
	else:
		score_current_label.modulate = Color.WHITE
	
	## Set height values
	#height_current_label.text = str(int(highest_height)) + "m"
	#height_best_label.text = str(int(highest_height_record)) + "m"
	#height_new_badge.visible = new_height
	#
	#if new_height:
		#height_current_label.modulate = Color.GOLD
		#animate_badge(height_new_badge)
	#else:
		#height_current_label.modulate = Color.WHITE
	
	# Animate overlay entrance
	animate_overlay_entrance()

func animate_result_label():
	var tween = create_tween()
	tween.set_parallel(true)
	
	result_label.scale = Vector2.ZERO
	tween.tween_property(result_label, "scale", Vector2.ONE * 1.2, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(result_label, "scale", Vector2.ONE, 0.2).set_delay(0.3)

func animate_badge(badge: Control):
	badge.modulate.a = 0.0
	badge.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(badge, "modulate:a", 1.0, 0.3).set_delay(0.5)
	tween.tween_property(badge, "scale", Vector2.ONE * 1.3, 0.2).set_delay(0.5)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.1)
	
	# Pulse animation
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(badge, "scale", Vector2.ONE * 1.1, 0.5)
	pulse_tween.tween_property(badge, "scale", Vector2.ONE, 0.5)

func animate_overlay_entrance():
	overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4)

func celebrate_new_record(record_type: String):
	print("NEW " + record_type.to_upper() + " RECORD!")
	# Add particle effects, sounds, screen shake, etc here

func _on_play_again():
	# Reset game state
	current_score = 0
	#highest_height = 0
	game_finished = false
	
	# Hide overlay
	overlay.visible = false
	
	# Restart the game scene
	get_tree().reload_current_scene()

func quit_game():
	get_tree().quit()
	
func save_records():
	var save_file = FileAccess.open("user://highscores.save", FileAccess.WRITE)
	if save_file:
		var save_data = {
			"highest_score": int(highest_score_record),
		#	"highest_height": int(highest_height_record)
		}
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_records():
	if FileAccess.file_exists("user://highscores.save"):
		var save_file = FileAccess.open("user://highscores.save", FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var save_data = json.data
				highest_score_record = save_data.get("highest_score", 0)
				#highest_height_record = save_data.get("highest_height", 0)

func display_text_on_start():
	result_label.text = "Scoreboard"
	score_current_label.text = str(0)
	score_best_label.text = str(highest_score_record)
	message_label.text = "WASD or Arrows to move"
	score_new_badge.text = ""
	loaded_score.emit(highest_score_record)
	
	#height_current_label.text = ""
	#height_best_label.text = str(highest_height_record)
	#height_new_badge.text = ""
	
func get_high_score() -> int:
	return int(highest_score_record)
#
#func get_high_height() -> int:
	#return int(highest_height_record)
