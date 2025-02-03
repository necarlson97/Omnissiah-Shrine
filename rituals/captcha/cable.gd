extends AnimatedSprite2D

# Set by outside class
var ratio = 0.0
# How fast it 'catches up
var speed = 10
var current_frame: float = 0.0

func _ready() -> void:
	play()
	speed_scale = 0.0

func _process(delta: float) -> void:
	# Play/reverse 'up to the ratio'. So if the animation is currently at the
	# end, but the ratio is suddenly set to 0.5, it will reverse until it
	# gets to the middle of the animation, and slowly stop	
	if ratio >= 1:
		done()
		
	# Compute how many frames in the current animation
	var total_frames = sprite_frames.get_frame_count(animation)
	var target_frame = ratio * float(total_frames - 1)
	
	current_frame = lerpf(current_frame, target_frame, speed * delta)
	frame = int(current_frame)
	
var is_done = false
func done():
	if is_done:
		return
	is_done = true
	# Time it out so it becomes visible when the 'thunk' sound is heard
	await get_tree().create_timer(0.8).timeout
	power_flowing()
	
var max_speed = -1.0
var variance = -1.0
func power_flowing():
	$SparkParticles2D.emitting = true
	$DataFlowParticles.emitting = true
	
	# Set the paricles to initially be slow,
	# but ramp up to their speed over time
	max_speed = $DataFlowParticles.process_material.initial_velocity_max
	variance = max_speed - $DataFlowParticles.process_material.initial_velocity_min
	
	var duration = 8.0
	create_tween().tween_property($DataFlowParticles.process_material, "initial_velocity_max",
		max_speed, duration
	).from(variance)
	create_tween().tween_property($DataFlowParticles.process_material, "initial_velocity_min",
		max_speed - variance, duration
	).from(0)
