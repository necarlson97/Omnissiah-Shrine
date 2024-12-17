extends Node2D
class_name Staff

@onready var notes: Node2D = $Notes
@onready var lines: Node2D = $Lines

var line_count = 3
var line_height = 100
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
	
func create_staff_lines(line_count: int):
	for i in range(line_count):
		var line = Line2D.new()
		line.default_color = Color.WHITE
		line.width = 5
		var height = margin + i * line_height
		
		# TOOD more points so we can do juicy wave later
		line.points = [
			Vector2(margin, height),
			Vector2(get_viewport().size.x - margin, height)
		]
		add_child(line)
	
	var cursor_height = line_height * (line_count - 1)
	$Cursor.scale.y = cursor_height
	$Cursor.position = Vector2(margin, margin + cursor_height / 2)

func generate_notes(note_data: Dictionary):
	var total_width = get_viewport().size.x - margin * 2
	var note_spacing = total_width / note_data["syllables"].size()
	var x_position = margin

	for syllable_data in note_data["syllables"]:
		# So our 'melody' here is 'random' - but deterministic and
		# dependent on the phonemes, so each hymn will always have a constant
		# mealody
		var pitch_int: int = abs(hash(syllable_data["espeak"])) % 3
		
		var note: Note = Note.create(
			syllable_data["text"], syllable_data["espeak"], pitch_int)
		$Notes.add_child(note)

		var y_pos = margin + (2 - pitch_int) * line_height
		note.position = Vector2(x_position, y_pos)
		x_position += note_spacing
		
		notes_to_play.append(note)

func advance_cursor(pressed_line: int):
	if is_done():
		print("Hymn finished!")
		return

	var note = notes_to_play.pop_front()
	note.pitch_pressed(pressed_line)
	$Cursor.position.x = note.position.x

func is_done() -> bool:
	return notes_to_play.size() == 0
