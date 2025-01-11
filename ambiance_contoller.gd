extends AudioStreamPlayer2D

# TODO goto 4.4 will have typed dicts (thank good) - but for now,
# We'll use an array for now
@export var ambiances: Array[AmbianceSetting]

var current_ambiance: AmbianceSetting = null
var next_ambiance: AmbianceSetting = null

func _ready():
	# Default to the 1st ambiance
	set_ambiance(ambiances[0])

func set_ambiance_by_name(key: String):
	var ambiance = ambiances.filter(func(a): return a.name == key)[0]
	set_ambiance(ambiance)

# Set the next ambiance to transition into
func set_ambiance(ambiance: AmbianceSetting):
	next_ambiance = ambiance
	if current_ambiance == null:
		# Immediately play the new ambiance if no current ambiance exists
		_play_start_clip(next_ambiance)
	else:
		# Play exit clip and schedule transition
		_play_exit_clip()

# Play the current ambiance's exit clip (if it exists)
func _play_exit_clip():
	if current_ambiance and current_ambiance.exit:
		stream = current_ambiance.exit
		play()
		connect("finished", _on_exit_clip_finished)
	else:
		_on_exit_clip_finished()

# Triggered when exit clip finishes
func _on_exit_clip_finished():
	disconnect("finished", _on_exit_clip_finished)
	if next_ambiance:
		_play_start_clip(next_ambiance)

# Play the start clip of the new ambiance (if it exists), then loop the middle audio
func _play_start_clip(ambiance: AmbianceSetting):
	current_ambiance = ambiance
	if ambiance.start:
		stream = ambiance.start
		play()
		connect("finished", _on_start_clip_finished)
	else:
		_on_start_clip_finished()

# Triggered when start clip finishes
func _on_start_clip_finished():
	disconnect("finished", _on_start_clip_finished)
	_play_middle_clip()

# Loop the middle clip of the current ambiance
func _play_middle_clip():
	if current_ambiance.middle:
		stream = current_ambiance.middle
		play()
