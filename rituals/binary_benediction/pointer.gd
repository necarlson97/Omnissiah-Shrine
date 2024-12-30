extends Sprite2D

# Pulse settings
var pulse_speed = 0.8  # How fast the pulse cycles per second
var time_accumulator = 0.0  # Tracks elapsed time

func _process(delta):
	time_accumulator += delta * pulse_speed
	# Calculate alpha value using a sine wave (scaled to range [0, 1])
	var alpha = (sin(time_accumulator * TAU) + 1.0) / 2.0
	modulate.a = alpha

func reset_pulse():
	# Sets the alpha back to 1 and continue from there
	time_accumulator = 0.0
