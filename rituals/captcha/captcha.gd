extends Node2D

@export var all_symbols: Array[Texture2D]
var correct_symbols: Array[Texture2D]
var pointer_index = 0

var next_scene_path = "res://rituals/binary_benediction/binary_benediction.tscn"

func _ready() -> void:
	# Start load on next scene
	ResourceLoader.load_threaded_request(next_scene_path)
	
	var numpad_keys = $Numpad.get_children().filter(func(c): return c.name != "blank")
	var entries = $Entry.get_children()
	
	# Get a random subet of the symbols
	all_symbols.shuffle()
	var symbols_to_use = all_symbols.slice(0, numpad_keys.size())
	# 4 of them will form our password
	var correct_symbols = symbols_to_use.slice(0, entries.size())
	symbols_to_use.shuffle()
	
	all_symbols[0].resource_path
	
	for c in numpad_keys:
		c = c as TextureRect
		c.texture = symbols_to_use.pop_front()
	
	var i = 0
	for c in entries:
		c = c as EntryChar
		c.set_correct_texture(correct_symbols[i])
		i += 1

func _input(event: InputEvent):
	if not (event is InputEventKey and event.is_pressed()):
		return
		
	# If we are already done here, move on
	if get_correct_ratio() >= 1:
		next_scene_is_ready()
	
	var keys = [
		"1", "2", "3",
		"4", "5", "6",
		"7", "8", "9",
		"slash", "*"
	]
	
	for key in keys:
		if event.is_action_pressed(key):
			var numpad_key = $Numpad.get_node_or_null(key)
			if numpad_key:
				numpad_key.was_pressed()
				var texture = numpad_key.texture
				var current_entry = $Entry.get_node("%s"%pointer_index) as EntryChar
				
				voice_omnissiah()
				if current_entry.check_texture(texture):
					pointer_index += 1
				check_complete()
	
	if event.is_action_pressed("ui_text_backspace"):
		pointer_index -= 1
	pointer_index = clamp(pointer_index, 0, 3)

func get_correct_ratio() -> float:
	var correct_count = $Entry.get_children().map(func(ec):
		ec = ec as EntryChar
		return 1 if ec.is_correct() else 0
	).reduce(func(acc, x): return acc + x, 0)  # 'Sum'
	return float(correct_count) / $Entry.get_children().size()
	
func check_complete():
	var ratio = get_correct_ratio()
	$Cable.ratio = ratio
	if ratio < 1:
		return
	$Label.text = "PRESS ANY TO CONT."
	# TODO flash text
	# TODO anything for reveal text? Turn green and lock in?
	$Numpad/blank.lock_in()
	$BinaryBabble.done()
	var good_color = ThemeDB.get_project_theme().get_color("good", "CSS")
	$Pointer.stop(good_color)
		
func _process(delta: float) -> void:
	var current_entry = $Entry.get_node("%s"%pointer_index) as EntryChar
	$Pointer.global_position.x = current_entry.get_global_rect().get_center().x

func voice_omnissiah():
	# have each keypress read out his name,
	# one syllable at a time
	var syllable_filenames = ["(sec)0m", "n^i", "s(pri)a^i", "@"]
	var audio = Note.get_syllable_audio_stream(syllable_filenames[pointer_index])
	$AudioStreamPlayer2D.stream = audio
	$AudioStreamPlayer2D.play()

func next_scene_is_ready():
	var progress : Array[float]
	var loading_status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	# Check the loading status:
	match loading_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			print("Loading: %s"%progress[0])
		ResourceLoader.THREAD_LOAD_LOADED:
			# When done loading, change to the target scene:
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(next_scene_path))
		ResourceLoader.THREAD_LOAD_FAILED:
			# Well some error happend:
			print("Error. Could not load Resource")
