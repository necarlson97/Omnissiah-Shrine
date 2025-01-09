extends RichTextLabel

func _ready() -> void:
	text = ""
	# Create and set up a repeating timer
	var timer = Timer.new()
	timer.wait_time = 1.0       # every 1 second
	timer.autostart = true      # starts automatically
	timer.one_shot = false      # repeats
	add_child(timer)

	# Connect the timer's timeout signal
	timer.timeout.connect(_on_timer_timeout)
	
	# So we can receive key press events
	set_focus_mode(FocusMode.FOCUS_ALL)

func _on_timer_timeout() -> void:
	# Get the current time in milliseconds, convert to binary
	var bin_str = byte_to_string(Time.get_ticks_msec())
	text = bin_str + "\n" + text

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Convert the key's scancode to binary
		var bin_str = byte_to_string(event.keycode)
		text = bin_str + "\n" + text

func byte_to_string(byte: int, length=20) -> String:
	var bin_str = ""
	for i in range(length):
		bin_str = str(byte & 1) + bin_str
		byte >>= 1
	return bin_str
