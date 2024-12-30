extends Node2D
class_name Transcript
# Handles the transcrips in the corner that keep track of what the player has said

# Shorthand
@onready var text = $Text
@onready var espeak = $PhoneticsHBox/Espeak
@onready var ipa = $PhoneticsHBox/IPA

func _ready() -> void:
	espeak.text = ""
	ipa.text = ""
	text.text = ""
	
	# Change up some colors
	ipa.modulate = ThemeDB.get_project_theme().get_color("good", "CSS")
	espeak.modulate = ThemeDB.get_project_theme().get_color("good_dark", "CSS")

func finished_word(word_data: Dictionary) -> void:
	# Takes in the finished word dict, e.g.:
	#"finished_word": {
		#"text": "sacred",
		#"hyphenated": "sa-cred",
		#"ipa": "sˈeɪ.kɹɪd",
		#"espeak_phonemes": "s'eIkrI2d"
	#}
	text.text = word_data["hyphenated"] + "\n" + text.text
	espeak.text = word_data["espeak_phonemes"] + "\n" + espeak.text
	ipa.text = word_data["ipa"] + "\n" + ipa.text
