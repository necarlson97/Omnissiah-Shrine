extends Line2D
class_name Barline

# Wave properties
# TODO wave could be set by the 'hot' meter
var wave_resolution = 100
var wave_amplitude: float = -100.0  # Height of the wave
var wave_decay: float = 0.9  # Damping factor for the wave
var wave_stiffness: float = 4000.0  # how "springy" the connections are

# Timer for wave animation
var wave_timer: Timer

# For the 'string sim' of 'plucking' this line
var velocities = range(wave_resolution).map(func(_i): return 0.0)
var displacements = range(wave_resolution).map(func(_i): return 0.0)

var rest_color = Color.DIM_GRAY

static func create(index: int, height: float) -> Barline:
	var new = preload("res://rituals/binary_benediction/barline.tscn").instantiate() as Barline
	# Thankfully, we can set height before or after assigning child
	new.position.y = height
	new.get_node("Label").text = str(index)
	return new
	
func _ready():
	setup_line()

func setup_line():
	default_color = rest_color
	width = 5
	var margin = BinaryBenediction.margin
	var max_width = get_viewport().size.x - 2 * margin
	var x_step = max_width / wave_resolution
	var x = margin
	
	# Set the label near the start of the line
	$Label.position = Vector2(x-30, -10)
	
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
	# Find the point closest to x and move it up to amplitude
	
	# Sort points by their distance to center_x, then pick the closest
	# TODO could do algebraic but this is more robust in a way
	var idx_dist_pairs = []
	for i in range(points.size()):
		idx_dist_pairs.append([i, abs(points[i].x - center_x)])
	idx_dist_pairs.sort_custom(func(a, b): return a[1] < b[1])
	var closest_idx = idx_dist_pairs[0][0]
	# Don't ever move the anchored first and last
	closest_idx = clamp(closest_idx, 1, points.size()-1)
	
	# Pluck the line at the closest point
	displacements[closest_idx] = wave_amplitude
	
	# Set a color that we will lerp back to white from
	var color_name = "good" if good else "bad"
	var color = ThemeDB.get_project_theme().get_color(color_name, "CSS")
	default_color = color
	
	wave_timer.start()
	
	# Also, lets play a little particle effect
	# TODO is this good? Should we do something else?
	$GPUParticles2D.modulate = color
	$GPUParticles2D.restart()
	$GPUParticles2D.position.x = center_x

func _update_wave():
	# Spread the wave with simple spring elastics (fixed ends) and
	# gradually decay
	var delta = wave_timer.wait_time

	# Compute accelerations based on neighbors
	var accelerations = range(wave_resolution).map(func(_i): return 0.0)

	# Ends are fixed for simplicity - no displacement change.
	# Or you could treat them as anchored to 0 displacement.
	for i in range(1, wave_resolution - 1):
		var left = displacements[i - 1]
		var right = displacements[i + 1]
		var center = displacements[i]
		var target = (left + right) / 2.0
		var error = target - center
		accelerations[i] = wave_stiffness * error

	# Integrate velocities and positions
	for i in range(1, wave_resolution - 1):
		velocities[i] += accelerations[i] * delta
		velocities[i] *= wave_decay  # apply damping
		displacements[i] += velocities[i] * delta

	# Update line points
	for i in range(wave_resolution):
		var p = points[i]
		# Vertical displacement only
		points[i] = Vector2(p.x, displacements[i])
		
	# Lerp color back towards rest color
	default_color = default_color.lerp(rest_color, 0.01)

	# Once wave is set to rest at 0, we can stop timer and reset color fully
	if _is_wave_at_rest():
		default_color = rest_color
		wave_timer.stop()

func _is_wave_at_rest() -> bool:
	var threshold = 0.1
	for i in range(wave_resolution):
		if abs(displacements[i]) > threshold or abs(velocities[i]) > threshold:
			return false
	return true
