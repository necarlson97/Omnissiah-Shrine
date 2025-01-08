extends Node2D

@export var all_symbols: Array[Texture2D]
var correct_symbols: Array[Texture2D]
var pointer_index = 0

func _ready() -> void:
	# Get a random subet of the symbols
	all_symbols.shuffle()
	var symbols_to_use = all_symbols.slice(0, 15)
	# 4 of them will form our password
	var correct_symbols = all_symbols.slice(0, 4)
	symbols_to_use.shuffle()
	
	for c in $Numpad.get_children():
		c = c as TextureRect
		if c.name == "blank":
			continue
		c.texture = symbols_to_use.pop_front()
	
	var i = 0
	for c in $Entry.get_children():
		c = c as TextureRect
		c.texture = correct_symbols[i]
		i += 1

func _input(event: InputEvent):
	if not (event is InputEventKey and event.is_pressed()):
		return
		
	var keys_to_names = {
		KEY_KP_1: "1",
		KEY_KP_2: "2",
		KEY_KP_3: "3",
		KEY_KP_4: "4",
		KEY_KP_5: "5",
		KEY_KP_6: "6",
		KEY_KP_7: "7",
		KEY_KP_8: "8",
		KEY_KP_9: "9",
		KEY_SLASH: "slash",
		KEY_ASTERISK: "*",
	}
	
	print(event.keycode)
	print(keys_to_names)
	print(keys_to_names[event.keycode])
		
	if event.keycode in keys_to_names:
		var texture = $Numpad.get_node(keys_to_names[event.keycode]).texture
		var current_entry = $Entry.get_node("%s"%pointer_index) as TextureRect
		current_entry.texture = texture
		pointer_index += 1
	
	if event.is_action_pressed("ui_text_backspace"):
		pointer_index -= 1
	pointer_index = clamp(pointer_index, 0, 3)
		
func _process(delta: float) -> void:
	var current_entry = $Entry.get_node("%s"%pointer_index) as TextureRect
	$Pointer.global_position.x = current_entry.global_position.x
