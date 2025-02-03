extends CanvasLayer

@onready var display: RichTextLabel = $Control/MarginContainer/VBoxContainer/Panel/MarginContainer/RichTextLabel

var title: String = "" # The 'header'
var hymn_text: String = ""  # Full hymn text
var current_index: int = 0  # Tracks progress in the text
var title_line: int = 1     # Number of title lines to remain white

func _ready():
	# Example setup
	display.bbcode_enabled = true

func set_hymn(hymn_data: Dictionary):
	"""
	Clears the current text and sets the new hymn.
	The title is made white, and the rest of the text gray.
	"""
	title = hymn_data["name"]
	var lines = hymn_data["lines"].map(func(l): return l["text"])
	hymn_text = "\n".join(lines)
	current_index = 0
	update_text("", hymn_text)

func advance(note: Note, was_correct=true):
	"""
	Advances the highlighted white text by the given substring (word or syllable).
	"""
	var substring = note.syllable
	if current_index >= hymn_text.length():
		return  # Already finished

	# Update the text display
	var next_index = hymn_text.findn(substring, current_index)
	if next_index == -1:
		return  # Substring not found

	current_index = next_index + substring.length()
	var before = hymn_text.substr(0, current_index)
	var after = hymn_text.substr(current_index)
	update_text(before, after)
	

func update_text(read: String, unread: String):
	var theme = ThemeDB.get_project_theme()
	var title_color = theme.get_color("dark", "CSS")
	var read_color = Color.WHITE
	var unread_color = theme.get_color("darkest", "CSS")
	display.bbcode_text = (
		"[b][color=#%s][font_size=50]%s[/font_size][/color][/b]\n"%[title_color.to_html(), title]
		+ "[color=#%s]%s[/color]"%[read_color.to_html(), read]
		+ "[color=#%s]%s[/color]"%[unread_color.to_html(), unread]
	)
