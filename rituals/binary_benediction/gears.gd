extends AnimatedSprite2D

# We track user input presses with timestamps (in seconds).
var input_times := []        # queue (array) of press timestamps
var inputs_per_second: float = 0.0   # smoothed value over time
var max_presses_per_second: float = 4.0  # define a "ceiling" for max input rate

func _ready() -> void:
	play()
	speed_scale = 0.0

func _input(event: InputEvent) -> void:
	# Keep track of the note plays 
	if BinaryBenediction.get_note_key(event) > -1:
		# Record the current time in seconds
		input_times.append(Time.get_ticks_msec() / 1000.0)

func _process(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0

	# (Remove timestamps older than 1 second to keep only presses in the last second)
	while input_times.size() > 0 and input_times[0] < current_time - 1.0:
		input_times.pop_front()
	var inputs_per_second_instant = float(input_times.size())

	# Smooth the instantaneous value into inputs_per_second (exponential-like smoothing)
	inputs_per_second = lerp(inputs_per_second, inputs_per_second_instant, 0.1)

	# Map that smoothed inputs_per_second value onto a 0–10 “gear speed”
	
	var speed = remap(inputs_per_second, 0.0, max_presses_per_second, 0.0, 10.0)
	speed_scale = speed

	var spark_particles = $SparkParticles2D as GPUParticles2D
	# Scale "amount" from 0–100 based on speed 0–10
	#spark_particles.amount = remap(speed, 0.0, 10.0, 1, 100)
	
	# TODO
	spark_particles.amount_ratio = remap(speed, 5.0, 10.0, 0.0, 1.0)

	var mat := spark_particles.process_material as ParticleProcessMaterial
	mat.initial_velocity_max = remap(speed, 0.0, 10.0, 0, 750)
	mat.initial_velocity_min = remap(speed, 0.0, 10.0, 0, 500)
