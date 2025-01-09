extends TextureRect
var start_pos: Vector2
var velocity = Vector2()
var max_distance : float
var speed = 80.0

# How strongly we steer back when near or beyond the boundary.
var boundary_steer_strength = 0.03

func _ready() -> void:
	start_pos = position
	velocity = Vector2.RIGHT.rotated(randf() * TAU).normalized() * speed
	max_distance = (get_rect().size).x / 4

func _process(delta: float) -> void:
	# Pick a small random turn angle each step
	var max_turn_angle = deg_to_rad(10)
	var turn_amount = randf_range(-max_turn_angle, max_turn_angle)
	velocity = velocity.rotated(turn_amount)
	
	# If we're outside or near the boundary, steer back
	var dist_from_center = position.distance_to(start_pos)
	if dist_from_center > max_distance * 0.9:
		# direction back to center
		var dir_to_center = (start_pos - position).normalized()
		# steer velocity partway toward that direction
		velocity = velocity.lerp(dir_to_center * speed, boundary_steer_strength)
	else:
		# keep speed consistent
		velocity = velocity.normalized() * speed

	# update position
	position += velocity * delta
