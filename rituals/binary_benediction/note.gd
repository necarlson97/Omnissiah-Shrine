extends Node2D
class_name Note

@onready var audio_player: AudioStreamPlayer2D = get_tree().get_root().find_child("AudioStreamPlayer2D", true, false)

# What pitch line does this note rest on?
var pitch_int: int = -1
# Do we play the whole word file, or just part?
var audio_stream: AudioStream
var syllable_data: Dictionary

var line: Barline

static func create(syllable_data: Dictionary, lines: Array) -> Note:
	var note = preload("res://rituals/binary_benediction/note.tscn").instantiate() as Note
	note.syllable_data = syllable_data
	
	# So our 'melody' here is 'random' - but deterministic and
	# dependent on the phonemes, so each hymn will always have a constant
	# mealody
	note.pitch_int = abs(hash(syllable_data["espeak"])) % 3
	if syllable_data['text'] == "0" or syllable_data['text'] == "1":
		note.pitch_int = int(syllable_data['text'])
	note.line = lines[lines.size() - 1 - note.pitch_int]
	
	(func(): note._setup(syllable_data['text'], syllable_data['espeak'])).call_deferred()
	var audio_path = "res://preprocess/audio/%s.wav" % syllable_data['filename']
	var audio_stream = load(audio_path) as AudioStream
	note.audio_stream = audio_stream
	return note

func _setup(syllable: String, phonemes: String):
	$Phoneme.text = phonemes
	$Text.text = syllable
	$Sprite2D.modulate = Color.WEB_GRAY

func voice_word(pitch_pressed: int):
	# Set the pitch shift effect on the 'chant' audio bus
	var effect = AudioServer.get_bus_effect(AudioServer.get_bus_index("chant"), 0)
	effect.pitch_scale = get_pitch_scale(pitch_pressed)
	
	# Play the audio stream on the 'chant' bus
	audio_player.bus = "chant"
	audio_player.stream = audio_stream
	audio_player.play()
	
	# If we finished a word, bubble that up to show
	if "finished_word" in syllable_data:
		var transcript = Utils.static_get_matching_node(get_tree().root, Transcript) as Transcript
		transcript.finished_word(syllable_data["finished_word"])
	
func pitch_pressed(pitch_pressed: int) -> bool:
	voice_word(pitch_pressed)
	if pitch_int == pitch_pressed: success()
	else: fail()
	return pitch_int == pitch_pressed
	
func get_pitch_scale(pitch_pressed: int) -> float:
	# Returns the 'pitch scale' needed to shift the audio clip
	# to match the pressed note
	
	# Assume the input is at C#(3)
	# and we need to pitch it up to one of the following note(s):
	# [D, F, C] depending on 'pitch_pressed' (pitch_pressed is 0, 1, or 2)
	
	var semitone_shifts = [-5, 0, +2]  # Semitone shifts
	var semitone_shift = semitone_shifts[pitch_pressed]
	var pitch_scale = pow(2.0, semitone_shift / 12.0)
	# Add a little randomness
	pitch_scale += randf_range(-0.01, 0.01)
	return pitch_scale

func success():
	$Sprite2D.modulate = ThemeDB.get_project_theme().get_color("good", "CSS")

func fail():
	$Sprite2D.modulate = ThemeDB.get_project_theme().get_color("bad", "CSS")

func comming_next():
	$Sprite2D.modulate = Color.WHITE

func _to_string() -> String:
	return "%s (%s)"%[syllable_data["text"], pitch_int]
