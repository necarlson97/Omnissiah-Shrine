extends Line2D
class_name Barline

# Wave properties
# TODO wave could be set by the 'hot' meter
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
	var point_count = 20
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

func trigger_wave(center_x: float, good=true):
	curr_center = center_x
	curr_amplitude = wave_amplitude  # Reset amplitude for a new wave
	wave_timer.start()
	
	# Set a color that we will lerp back to white from
	var color = "good"
	if not good:
		color = "bad"
	default_color = ThemeDB.get_project_theme().get_color(color, "CSS")
	
	move_resolution(center_x)

func move_resolution(center_x: float):
	# Move the 'resolution' of the wave to focus around the center
	# of this new wave (but still maintain the first and last poitns)
	
	# How far along the line this new center of the wave is:
	var start = points[0].x
	var last_idx = points.size()-1
	var end = points[last_idx].x
	var total_width = end-start
	var center_ratio = remap(center_x, start, end, 0.0, 1.0)
	
	var get_spaced_x = func(ratio_distance) -> float:
		# Takes a 'ratio_distance' [0-1] of how far this point is away
		# from the epicenter of the new wave, and returns a x value
		# for how far to space the points. Smaller when closer to the epicenter,
		# more spaced out when further away (quadratic distribution)
		
		var num_intervals = last_idx
		# Minimum spacing is a fraction of the total width, ensuring non-zero spacing
		var min_spacing = total_width / pow(num_intervals, 2)
		# Maximum spacing is adjusted dynamically to ensure intervals sum to total_width
		var max_spacing = total_width / min_spacing
		return lerp(min_spacing, max_spacing, ratio_distance)
		
	# TODO DEBUG REMOVE
	if $Debug:
		for c in $Debug.get_children():
			c.queue_free()
	else:
		var debug = Node2D.new()
		debug.set_name("Debug")
		add_child(debug)

	var x = start
	print("Center ratio: %s"%center_ratio)
	for i in points.size():
		var point = points[i]
		
		# How far along the line we are [0-1]
		var point_ratio = float(i) / last_idx
		# How far away from the center we are [0-1]
		var ratio_distance = abs(center_ratio - point_ratio)
		var x_spacing = get_spaced_x.call(ratio_distance)
		
		points[i] = Vector2(x, point.y)
		# TODO DEBUGGING REMOVE
		print("  %s (%s) = %s (%s)"%[point_ratio, ratio_distance, round(x_spacing), round(x)])
		var debug_box = preload("res://debug_box.tscn").instantiate()
		$Debug.add_child(debug_box)
		debug_box.position = points[i]
		x += x_spacing
		
	# End must be fixed
	points[last_idx] = Vector2(end, points[last_idx].y)

func _update_wave():
	# Gradually decay the wave
	curr_amplitude *= wave_decay
	if curr_amplitude < 0.01:
		curr_amplitude = 0
		
	for i in points.size():
		var point = points[i]
		var distance = abs(point.x - curr_center)
		var decay = pow(wave_decay, distance)
		var distance_factor = sin((distance * wave_frequency) + (Time.get_ticks_msec() / 1000.0 * wave_speed))
		var y_offset = distance_factor * curr_amplitude * decay
		points[i] = Vector2(point.x, y_offset)
		
	# Lerp color back towards white
	default_color = default_color.lerp(Color.WHITE, 1-wave_decay)

	# Once wave is set to rest at 0, we can stop timer and reset color fully
	if curr_amplitude == 0:
		curr_amplitude = 0
		default_color = Color.WHITE
