extends Node2D

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var ipa_label: Label = $IPAText
@onready var hyphenated_label: Label = $HyphenatedText

var hymns_data: Dictionary

func _ready():
	# Load hymns.json
	var json_path = "res://preprocess/hymns.json"
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("Failed to load json at %s"%json_path)
		return
	var file_str = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(file_str)
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", file_str, " at line ", json.get_error_line())
		return
	
	var hymns_data = json.data
	if typeof(hymns_data) != TYPE_ARRAY:
		print("Unexpected data: %s"%hymns_data)
		return
	
	if not hymns_data:
		print("Hymns empty: %s"%hymns_data)
		return
	play_hymn(hymns_data[0])  # Play the first hymn

func play_hymn(hymn_data: Dictionary):
	print("Playing hymn: " + hymn_data["name"])

	for line in hymn_data["lines"]:
		for word in line["words"]:
			var audio_path = "res://preprocess/audio/" + word["ipa"] + ".wav"

			# Load the audio stream dynamically to support web-safe resources
			var audio_stream = load(audio_path)
			if audio_stream:
				audio_player.stream = audio_stream
				display_text(word["ipa"], word["hyphenated"])
				audio_player.play()

				# Wait until the audio finishes playing
				while audio_player.is_playing():
					await get_tree().process_frame
			else:
				print("Failed to load audio: " + audio_path)

func display_text(ipa: String, hyphenated: String):
	# Display the IPA and hyphenated text on screen
	ipa_label.text = "IPA: " + ipa
	hyphenated_label.text = "Hyphenated: " + hyphenated
