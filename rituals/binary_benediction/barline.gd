extends Line2D
class_name Barline

# Wave properties
var wave_amplitude: float = 100.0  # Height of the wave
var wave_frequency: float = 1.0  # Number of oscillations
var wave_speed: float = 5.0       # Speed of the wave animation
var wave_decay: float = 0.95      # Damping factor for the wave

var curr_amplitude: float  
var curr_center: float = 0.0 # X position of the wave origin

# Timer for wave animation
var wave_timer: Timer

static func create(height: float) -> Barline:
	var new = preload("res://rituals/binary_benediction/barline.tscn").instantiate() as Barline
	# Thankfully, we can set height before or after assigning child
	new.position.y = height
	return new
	
func _ready():
	default_color = Color.WHITE
	width = 5
	var margin = BinaryBenediction.margin
	
	var max_width = get_viewport().size.x - 2 * margin
	var point_count = 50
	var x_step = max_width / point_count
	var x = margin
	
	var new_points = []
	for i in range(point_count):
		new_points.append(Vector2(x, 0))
		x += x_step
	points = new_points
		
	wave_timer = Timer.new()
	wave_timer.wait_time = 0.016  # 60 FPS
	wave_timer.one_shot = false
	wave_timer.timeout.connect(_update_wave)
	add_child(wave_timer)

func trigger_wave(center_x: float):
	curr_center = center_x
	curr_amplitude = wave_amplitude  # Reset amplitude for a new wave
	wave_timer.start()

func _update_wave():
	for i in points.size():
		var point = points[i]
		var distance = abs(point.x - curr_center)
		var decay = pow(wave_decay, distance)
		var distance_factor = sin((distance * wave_frequency) + (Time.get_ticks_msec() / 1000.0 * wave_speed))
		var y_offset = distance_factor * curr_amplitude * decay
		points[i] = Vector2(point.x, y_offset)

	# Gradually decay the wave
	curr_amplitude *= wave_decay
	if curr_amplitude < 0.1:
		curr_amplitude = 0
		#wave_timer.stop()
