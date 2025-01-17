extends Node2D
class_name Note

@onready var audio_player: AudioStreamPlayer2D = get_tree().get_root().find_child("AudioStreamPlayer2D", true, false)

var syllable = ""
var phoneme = ""
# What pitch line does this note rest on?
var pitch_int: int = -1
var pitch_pressed: int = -2
# Do we play the whole word file, or just part?
var audio_stream: AudioStream
var syllable_data: Dictionary

var line: Barline

# Sometimes we change color suddenly, other times we lerp
var target_color = ThemeDB.get_project_theme().get_color("darker", "CSS")

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
	note.audio_stream = get_syllable_audio_stream(syllable_data['filename'])
	
	note.syllable = syllable_data["text"]
	note.phoneme = syllable_data["espeak"]
	return note

static func get_syllable_audio_stream(filename: String) -> AudioStream:
	var audio_path = "res://preprocess/audio/%s.wav" % filename
	return load(audio_path) as AudioStream

func _ready() -> void:
	$Phoneme.text = phoneme
	$Text.text = syllable
	set_color(target_color)

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
	
func pitch_was_pressed(pressed: int) -> bool:
	pitch_pressed = pressed
	voice_word(pitch_pressed)
	if was_correct(): success()
	else: fail()
	return was_correct()
	
func was_correct() -> bool:
	return pitch_pressed == pitch_int
	
func get_pitch_scale(pitch_pressed: int) -> float:
	# Returns the 'pitch scale' needed to shift the audio clip
	# to match the pressed note
	
	# Assume the input is at C#(3)
	var semitone_shifts = [0, +2, +3]  # Semitone shifts
	var semitone_shift = semitone_shifts[pitch_pressed]
	var pitch_scale = pow(2.0, semitone_shift / 12.0)
	# Add a little randomness
	var variation = 0.02
	pitch_scale += randf_range(-variation, variation)
	return pitch_scale

func success():
	target_color = ThemeDB.get_project_theme().get_color("good_dark", "CSS")
	$Sprite2D.modulate = ThemeDB.get_project_theme().get_color("good", "CSS")

func fail():
	target_color = ThemeDB.get_project_theme().get_color("bad_dark", "CSS")
	$Sprite2D.modulate = ThemeDB.get_project_theme().get_color("bad", "CSS")

func comming_next():
	set_color(Color.WHITE)
	
func _process(delta: float) -> void:
	$Sprite2D.modulate = $Sprite2D.modulate.lerp(target_color, 0.04)
	
func set_color(color: Color):
	# Snap to a specific color
	$Sprite2D.modulate = color
	target_color = color
	
func _to_string() -> String:
	return "%s (%s)"%[syllable_data["text"], pitch_int]
