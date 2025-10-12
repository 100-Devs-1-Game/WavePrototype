# SoundManager.gd (set as autoload)
extends Node

# Array of sound file paths
@export var sound_files: Array[String] = [
	"res://sounds/splashsound.wav",
	"res://sounds/sillysong2.wav",
	"res://sounds/seagulhurt.wav",
	"res://sounds/seagulloceanwaveloop.wav",
	"res://sounds/bomexplosion.wav",
	"res://sounds/heliloopEQ.wav",
	"res://sounds/swoosh.wav",
	"res://sounds/bloopintromessagesound.wav"
]


# Play a specific sound by index
func play_sound(index: int):
	if index < 0 or index >= sound_files.size():
		push_warning("Sound index out of range: " + str(index))
		return
	
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = load(sound_files[index])
	
	# Add to scene tree
	add_child(audio_player)
	
	# Play and auto-cleanup
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)

# Play a specific sound by index with variation
func play_sound_varied(index: int, pitch_variation: float = 0.2, volume_variation: float = 3.0):
	if index < 0 or index >= sound_files.size():
		push_warning("Sound index out of range: " + str(index))
		return
	
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = load(sound_files[index])
	
	# Add pitch variation (e.g., 0.2 = ±20% pitch change)
	audio_player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	
	# Add volume variation in decibels (e.g., 3.0 = ±3dB)
	audio_player.volume_db = randf_range(-volume_variation, volume_variation)
	
	add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)

# Play a looped sound by index (returns the audio player so you can stop it later)
func play_sound_looped(index: int) -> AudioStreamPlayer:
	if index < 0 or index >= sound_files.size():
		push_warning("Sound index out of range: " + str(index))
		return null
	
	var audio_player = AudioStreamPlayer.new()
	var sound_stream = load(sound_files[index])
	
	# Enable looping (works for most AudioStream types)
	if sound_stream is AudioStreamWAV:
		sound_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif sound_stream is AudioStreamOggVorbis:
		sound_stream.loop = true
	
	audio_player.stream = sound_stream
	
	add_child(audio_player)
	audio_player.play()
	
	return audio_player
