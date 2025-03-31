extends Node

@export_file var next_scene_path

func _ready() -> void:
	# Start load on next scene asap
	print("Loading "+next_scene_path)
	ResourceLoader.load_threaded_request(next_scene_path)
	
func next() -> bool:
	var progress : Array[float]
	var loading_status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	# Check the loading status:
	match loading_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			print("Loading: %s"%progress[0])
			return false
		ResourceLoader.THREAD_LOAD_LOADED:
			# When done loading, change to the target scene:
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(next_scene_path))
			return true
		ResourceLoader.THREAD_LOAD_FAILED:
			# Well some error happend:
			print("Error. Could not load Resource")
			return false
	print("Status of load uknown: %s"%loading_status)
	return false
