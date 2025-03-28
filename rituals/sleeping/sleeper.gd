extends Node

const INACTIVITY_TIMEOUT := 30.0  # seconds before sleeping

var current_scene_path: String = ""
var last_input_time := 0.0
var is_sleeping := false

func _ready():
	last_input_time = Time.get_unix_time_from_system()
	set_process(true)
	Input.set_use_accumulated_input(true)  # ensures we get all input

func _input(event):
	if event.is_pressed():
		_register_input()

func _register_input():
	last_input_time = Time.get_unix_time_from_system()

	if is_sleeping:
		_wake_up()

func _process(_delta):
	if is_sleeping:
		return

	var current_time = Time.get_unix_time_from_system()
	if current_time - last_input_time > INACTIVITY_TIMEOUT:
		_go_to_sleep()

func _go_to_sleep():
	is_sleeping = true
	current_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://rituals/sleeping/sleeping.tscn")

func _wake_up():
	if current_scene_path != "":
		get_tree().change_scene_to_file(current_scene_path)
		is_sleeping = false
		last_input_time = Time.get_unix_time_from_system()
