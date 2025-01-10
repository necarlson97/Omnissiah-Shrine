extends AudioStreamPlayer2D
class_name ClickPlayer

# How often the timer fires is s
var interval = 0.05
@onready var timer = Timer.new()

# The str of 1s and 0s that tells it when to play and when to not
var binary_score: String = "101"

func set_binary_score(text: String):
	binary_score = StaffBinary.byte_to_string(hash(text))

func _ready() -> void:
	timer.wait_time = interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(play_click)

var idx = 0
func play_click():
	var s = binary_score[idx]
	pitch_scale = 0.8 if s == "0" else 1.0
	if s == "1":
		play()
	idx = (idx + 1) % binary_score.length()
