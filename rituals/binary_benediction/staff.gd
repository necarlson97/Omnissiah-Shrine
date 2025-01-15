extends Node2D
class_name Staff

var line_count = 3
var line_height = 60
var total_height = line_count * line_height
var note_data: Dictionary
var margin = BinaryBenediction.margin

var notes_to_play: Array[Node2D] = []

static func create(note_data: Dictionary) -> Staff:
	var new = preload("res://rituals/binary_benediction/staff.tscn").instantiate() as Staff
	new.note_data = note_data
	return new
	
func _ready():
	create_staff_lines(line_count)
	generate_notes(note_data)
	$Cursor.modulate = ThemeDB.get_project_theme().get_color("darker", "CSS")
	
func create_staff_lines(line_count: int):
	for i in range(line_count):
		var height = margin + i * line_height
		$Lines.add_child(Barline.create(line_count-1-i, height))
		
	var cursor_height = line_height * (line_count - 1)
	$Cursor.scale.y = cursor_height
	$Cursor.position = Vector2(margin, margin + cursor_height / 2)

func generate_notes(note_data: Dictionary):
	var total_width = get_viewport().size.x - margin * 3
	var note_spacing = total_width / note_data["syllables"].size()
	var x_position = margin * 1.5

	for syllable_data in note_data["syllables"]:
		var note: Note = Note.create(syllable_data, $Lines.get_children())
		$Notes.add_child(note)

		var y_pos = margin + (line_count - 1 - note.pitch_int) * line_height
		note.position = Vector2(x_position, y_pos)
		x_position += note_spacing

		notes_to_play.append(note)

var _active = false
func activate():
	# When this staff becomes the next-in-line, brigten up it's colors
	if _active:
		return
	_active = true
	var lighter_gray = ThemeDB.get_project_theme().get_color("dark", "CSS")
	$Cursor.modulate = lighter_gray
	for line in $Lines.get_children():
		line.set_color(lighter_gray)
	for note in notes_to_play:
		note.set_color(lighter_gray)

func play_note(pressed_line: int) -> bool:
	# Play a given note, returning true if the note was correct
	if is_done():
		print("Hymn finished!")
		return true

	var note = notes_to_play.pop_front()
	var was_correct = note.pitch_was_pressed(pressed_line)
	var last_idx = $Lines.get_children().size()-1
	var line = $Lines.get_children()[last_idx-pressed_line]
	line.trigger_wave(note.global_position.x, was_correct)
	$Cursor.global_position.x = note.global_position.x
	return was_correct

func get_text() -> String:
	return note_data.get("text", "")

func is_done() -> bool:
	return notes_to_play.size() == 0
	
func _to_string() -> String:
	return "Staff %s: %s"%[note_data["text"], notes_to_play]
