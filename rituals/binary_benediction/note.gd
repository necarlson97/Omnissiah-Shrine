extends Node2D
class_name Note

@onready var audio_player: AudioStreamPlayer2D = get_tree().get_root().find_child("AudioStreamPlayer2D", true, false)

# What pitch line does this note rest on?
var pitch_int: int = -1
# Do we play the whole word file, or just part?
var audio_stream: AudioStream
var syllable_data: Dictionary

static func create(syllable_data: Dictionary) -> Note:
	var note = preload("res://rituals/binary_benediction/note.tscn").instantiate() as Note
	note.syllable_data = syllable_data
	
	# So our 'melody' here is 'random' - but deterministic and
	# dependent on the phonemes, so each hymn will always have a constant
	# mealody
	note.pitch_int = abs(hash(syllable_data["espeak"])) % 3
	
	(func(): note._setup(syllable_data['text'], syllable_data['espeak'])).call_deferred()
	var audio_path = "res://preprocess/audio/%s.wav" % syllable_data['filename']
	var audio_stream = load(audio_path) as AudioStream
	note.audio_stream = audio_stream
	return note

func _setup(syllable: String, phonemes: String):
	$Phoneme.text = phonemes
	$Text.text = syllable

func voice_word(pitch_pressed: int):
	if audio_stream:
		audio_player.pitch_scale = get_pitch_percent(pitch_pressed)
		audio_player.stream = audio_stream
		audio_player.play()
	
func pitch_pressed(pitch_pressed: int):
	voice_word(pitch_pressed)
	if pitch_int == pitch_pressed: success()
	else: fail()
	
func get_pitch_percent(pitch_pressed: int) -> float:
	# Returns the 'pitch scale' needed to shift the audio clip
	# to match the pressed note
	
	# Assume the input is at C#(3)
	# and we need to pitch it up to one of the following note(s):
	# [D, F, C] depending on 'pitch_pressed' (pitch_pressed is 0, 1, or 2)
	
	var semitone_shifts = [1, 4, 8]  # Semitone shifts from C#(3) to D, F, G
	var semitone_shift = semitone_shifts[pitch_pressed]
	var pitch_scale = pow(2.0, semitone_shift / 12.0)
	print(pitch_scale)
	return pitch_scale

func success():
	$Sprite2D.modulate = ThemeDB.get_project_theme().get_color("good", "CSS")

func fail():
	$Sprite2D.modulate = ThemeDB.get_project_theme().get_color("bad", "CSS")
