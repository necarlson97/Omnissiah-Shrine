extends Line2D
class_name Barline

# Wave properties
# TODO wave could be set by the 'hot' meter
var wave_resolution = 50
var wave_amplitude: float = 100.0  # Height of the wave
var wave_frequency: float = 0.2  # Number of oscillations
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
	var x_step = max_width / wave_resolution
	var x = margin
	
	var new_points = []
	for i in range(wave_resolution):
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
	# Debug: For holding debug visuals
	if $Debug:
		$Debug.get_children().map(func(c): c.queue_free())
	else:
		var debug = Node2D.new()
		debug.set_name("Debug")
		add_child(debug)
		
	#var start = points[0].x
	#var end = points[points.size() - 1].x
	# TODO
	var start = BinaryBenediction.margin
	var end = get_viewport().size.x - BinaryBenediction.margin
	var total_width = end - start
	
	# Generate a list of values that spreads from 0 outwards
	# twice as many as we need (minus first and last, as they are static)
	var inner_points = points.size() - 2 
	var spread_offsets = range(inner_points).map(func(i): return pow(i, 2))
	spread_offsets += range(1, inner_points).map(func(i): return -pow(i, 2))
	var max_offset = abs(spread_offsets[spread_offsets.size()-1])
	spread_offsets.sort()   # TODO debug
	print("Offsets:")
	for x in spread_offsets:
		print("  %s"%[round(x)])
	
	spread_offsets = spread_offsets.map(func(x_offset): 
		# Map to within start-end, cutting off any that fall outside
		var x = remap(x_offset, -max_offset, max_offset, -total_width, total_width)
		return center_x + x
	)
	print("Xs:")
	for x in spread_offsets:
		print("  (%s) [%s-%s] %s"%[round(x), start, end, x >= start and x <= end])
	spread_offsets = spread_offsets.filter(func(x): return x >= start and x <= end)
	spread_offsets.sort()
	

	print("%s vs %s"%[spread_offsets.size(), points.size()])
	# We should have 2 less than we need (start and end)
	# If we have an extras, discard them
	while spread_offsets.size() > inner_points:
		if spread_offsets.size() %2 == 0:
			spread_offsets.pop_back()
		else:
			spread_offsets.pop_front()
	spread_offsets = [start] + spread_offsets + [end]
	
	assert(spread_offsets.size() == points.size(), "%s vs %s"%[spread_offsets.size(), points.size()])

	for i in range(points.size()):
		points[i] = Vector2(spread_offsets[i], points[i].y)
		# Debug: add the thin vertical lines to show where the points are
		#var debug_box = preload("res://debug_box.tscn").instantiate()
		#$Debug.add_child(debug_box)
		#debug_box.position = Vector2(points[i].x, 0)
		#debug_box.scale.y = 2 + (4*float(i)/points.size())
		#debug_box.modulate = Color.RED

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
