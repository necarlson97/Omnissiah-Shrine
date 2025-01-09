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
		
	var keys = [
		"1", "2", "3",
		"4", "5", "6",
		"7", "8", "9",
		"slash", "*"
	]
	
	for key in keys:
		if event.is_action_pressed(key):
			var texture = $Numpad.get_node(key).texture
			var current_entry = $Entry.get_node("%s"%pointer_index) as TextureRect
			current_entry.texture = texture
			pointer_index += 1
	
	if event.is_action_pressed("ui_text_backspace"):
		pointer_index -= 1
	pointer_index = clamp(pointer_index, 0, 3)
		
func _process(delta: float) -> void:
	var current_entry = $Entry.get_node("%s"%pointer_index) as TextureRect
	$Pointer.global_position.x = current_entry.get_global_rect().get_center().x
