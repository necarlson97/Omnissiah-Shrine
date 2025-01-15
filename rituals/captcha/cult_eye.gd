extends AnimatedSprite2D
class_name CultEye

@export var binary_string: String = (
	"010101000100100001000101010110010010000001010011010001010100010100100000010110010100111101010101"	
)
var wait_time_multiplier = 2.0 # Adds dead space
var speed_multiplier = 1.0

func _ready():
	play()
	_play_next()

# Pop the first character, add it to the back, and process
func _play_next():
	var current_char = binary_string[0]
	binary_string = binary_string.substr(1) + current_char  # Rotate the string
	
	if current_char == "1": _play_animation()
	else: _wait_for_animation_duration()

func _play_animation():
	speed_scale = speed_multiplier
	play()
	print("Playing animation for %s"%get_duration())
	await get_tree().create_timer(get_duration()).timeout
	_play_next()

# Wait for the duration of the animation and then call _play_next
func _wait_for_animation_duration():
	speed_scale = 0
	print("Doing nothing for %s"%get_duration())
	await get_tree().create_timer(get_duration()).timeout
	_play_next()

func get_duration() -> float:
	# TODO for now, assuming 30fps
	return (
		(wait_time_multiplier * sprite_frames.get_frame_count("default") / 30.0)
		/ speed_multiplier
	)

func faster():
	# Swap to a faster blinking mode
	speed_multiplier = 3.0
	wait_time_multiplier = 1.0
	modulate = Color.WHITE
