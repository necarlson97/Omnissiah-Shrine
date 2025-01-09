extends RichTextLabel

var reveal_speed = 0.005
var curr_speed = reveal_speed
var locked_in = false

func _ready() -> void:
	reset_numbers()

func _process(delta: float) -> void:
	visible_ratio += curr_speed
	
	if locked_in:
		curr_speed = reveal_speed * 5
		return
	
	if visible_ratio >= 1:
		curr_speed = reveal_speed * -5
	if visible_ratio <= 0:
		reset_numbers()
		curr_speed = reveal_speed

func reset_numbers():
	# Keep overall leng the same, repalce with random 1s and 0s
	text = "".join(Array(text.split()).map(func(s):
		return "0" if randi() % 2 else "1"
	))
	visible_ratio = 0

func lock_in():
	# We got it correct, little juice to set this as 'locked in'
	locked_in = true
	modulate = ThemeDB.get_project_theme().get_color("good_dark", "CSS")
