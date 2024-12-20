extends Line2D

# Wave properties
var wave_amplitude: float = 10.0  # Height of the wave
var wave_frequency: float = 10.0  # Number of oscillations
var wave_speed: float = 3.0       # Speed of the wave animation
var wave_decay: float = 0.95      # Damping factor for the wave
var wave_center: float = 0.0      # X position of the wave origin

# Timer for wave animation
var wave_timer: Timer

func _ready():
	wave_timer = Timer.new()
	wave_timer.wait_time = 0.016  # 60 FPS
	wave_timer.one_shot = false
	wave_timer.connect("timeout", self, "_update_wave")
	add_child(wave_timer)

func trigger_wave(center_x: float):
	wave_center = center_x
	wave_amplitude = 10.0  # Reset amplitude for a new wave
	wave_timer.start()

func _update_wave():
	var points = []
	var line_width = get_viewport().size.x - 2 * margin
	var step = line_width / (points_in_line - 1)  # Points resolution

	for i in range(points_in_line):
		var x = margin + i * step
		var distance = abs(x - wave_center)
		var decay = pow(wave_decay, distance)
		var y_offset = sin((distance * wave_frequency) + (OS.get_ticks_msec() / 1000.0 * wave_speed)) * wave_amplitude * decay
		points.append(Vector2(x, base_height + y_offset))

	self.points = points

	# Gradually decay the wave
	wave_amplitude *= wave_decay
	if wave_amplitude < 0.1:
		wave_timer.stop()
