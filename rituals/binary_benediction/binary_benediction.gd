extends Node2D
class_name BinaryBenediction

var current_note_index: int = 0
var current_notes: Array = []

var current_hymn_index: int = 0
var all_hymn_data: Array

var line_height = 100
const margin = 50
# For now just keep scrolling forever
var y = 0

var staffs_to_play: Array[Node2D]

@onready var pointer = $Staffs/Pointer

func _ready():
	# Load hymns.json
	var json_path = "res://preprocess/hymns.json"
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("Failed to load json at %s" % json_path)
		return
	var file_str = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(file_str)
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", file_str, " at line ", json.get_error_line())
		return

	all_hymn_data = json.data
	if typeof(all_hymn_data) != TYPE_ARRAY:
		print("Unexpected data: %s" % all_hymn_data)
		return

	if not all_hymn_data:
		print("Hymns empty: %s" % all_hymn_data)
		return

	current_hymn_index = Kronos.get_day_of_year() % all_hymn_data.size()
	create_hymn(all_hymn_data[current_hymn_index])
	activate_staff()
	advance_pointer()

func create_hymn(hymn_data: Dictionary):
	print("Playing hymn: " + hymn_data["name"])
	$ReadAlong.set_hymn(hymn_data)

	# Load the first line of the hymn
	for line_data in hymn_data["lines"]:
		var new_staff = Staff.create(line_data)
		$Staffs.add_child(new_staff)
		new_staff.position.y = y
		y += new_staff.total_height + margin
		staffs_to_play.append(new_staff)
	# For now, limit to only 2 lines of binary
	for line_data in hymn_data["lines"].slice(0, 2):
		var new_staff = StaffBinary.create(line_data)
		$Staffs.add_child(new_staff)
		new_staff.position.y = y
		y += new_staff.total_height + margin
		staffs_to_play.append(new_staff)

func _input(event: InputEvent):
	var pitch_int = get_note_key(event)
	if pitch_int > -1:
		note_pressed(pitch_int)
			
static func get_note_key(event) -> int:
	# Get white note the keypress corresponds to 0-2 (or w/e)
	# -1 if it is not a note key
	if not (event is InputEventKey and event.is_pressed()):
		return -1
		
	if event.keycode in range(KEY_KP_1, KEY_KP_9+1):
		return (event.keycode - KEY_KP_1) % 3
	if event.keycode in [KEY_1, KEY_2, KEY_3]:
		return event.keycode - KEY_1
	return -1

func note_pressed(pressed_line: int):
	if not staffs_to_play:
		return
	var current_note = staffs_to_play[0].notes_to_play[0]
	var was_correct = staffs_to_play[0].play_note(pressed_line)
	$ReadAlong.advance(current_note, was_correct)
	
	if staffs_to_play[0].is_done():
		staffs_to_play.pop_front()
		if staffs_to_play.is_empty():
			done()
			return
		activate_staff()
		
	advance_pointer()

func activate_staff():
	staffs_to_play[0].activate()
	$CamHolder/ClickPlayer.set_binary_score(staffs_to_play[0].get_text())

func advance_pointer():
	var next_note = staffs_to_play[0].notes_to_play[0] as Note
	next_note.comming_next()
	pointer.global_position = next_note.global_position + Vector2(0, -20)
	pointer.reset_pulse()

var cam_speed = 10
func _process(delta: float) -> void:
	if staffs_to_play:
		$Staffs.position = $Staffs.position.lerp(
			-staffs_to_play[0].position, cam_speed * delta)

func done(next_hymn=false):
	if next_hymn:
		current_hymn_index = (current_hymn_index - 1) % all_hymn_data.size()
		create_hymn(all_hymn_data[current_hymn_index])
		return
	var all_notes: Array[Note]
	for s in $Staffs.get_children():
		var note_holder = s.get_node_or_null("Notes")
		if note_holder:
			for n in s.get_node("Notes").get_children():
				all_notes.append(n)
	
	var correct_notes = all_notes.filter(func(n): return n.was_correct())
	Archivist.save_day_info({
		"correct count": correct_notes.size(),
		"note count": all_notes.size(),
		"correct ratio": float(correct_notes.size()) / all_notes.size(),
	})
