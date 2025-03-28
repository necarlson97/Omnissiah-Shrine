extends Node

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
