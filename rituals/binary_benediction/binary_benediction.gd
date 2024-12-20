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

	current_hymn_index = randi_range(0, all_hymn_data.size()-1)
	create_hymn(all_hymn_data[current_hymn_index])

func create_hymn(hymn_data: Dictionary):
	print("Playing hymn: " + hymn_data["name"])

	# Load the first line of the hymn
	for line_data in hymn_data["lines"]:
		var new_staff = Staff.create(line_data)
		add_child(new_staff)
		new_staff.position.y = y
		y += new_staff.total_height + margin
		staffs_to_play.append(new_staff)

func _input(event: InputEvent):
	if event is InputEventKey and event.is_pressed():
		var key = event.keycode
		if key in [KEY_KP_1, KEY_KP_2, KEY_KP_3]:
			var pitch_int = key - KEY_KP_1
			advance_pointer(pitch_int)
		if key in [KEY_1, KEY_2, KEY_3]:
			var pitch_int = key - KEY_1
			advance_pointer(pitch_int)

var current_staff: Staff
func advance_pointer(pressed_line: int):
	# TODO when we run out
	if current_staff == null or current_staff.is_done():
		current_staff = staffs_to_play.pop_front()
	if current_staff == null:
		current_hymn_index += 1
		create_hymn(all_hymn_data[current_hymn_index])
	else:
		current_staff.advance_cursor(pressed_line)

var cam_speed = 10
func _process(delta: float) -> void:
	if current_staff:
		$CamHolder.position = $CamHolder.position.lerp(current_staff.position, cam_speed * delta)
