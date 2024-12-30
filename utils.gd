extends Node3D
class_name Utils

# Functions for finding by script or class name (see 'matches_class')
func get_matching_node(script, allow_null=false):
	return Utils.static_get_matching_node(get_tree().root, script, allow_null)
func get_matching_nodes(script, allow_empty=false) -> Array:
	return Utils.static_get_matching_nodes(get_tree().root, script, allow_empty)
static func static_get_matching_node(node: Node, script, allow_null=false):
	var res = Utils._static_get_matching_node(node, script)
	assert(res != null or allow_null, "Could not find a %s (%s) = %s"%[script, node, res])
	return res
static func static_get_matching_nodes(node: Node, script, allow_empty=false) -> Array:
	var res = Utils._static_get_matching_nodes(node, script)
	assert(res != [] or allow_empty, "Could not find a %s (%s)"%[script, node])
	return res
static func _static_get_matching_node(node: Node, script):
	if Utils.matches_class(node, script): return node
	for child in node.get_children():
		var res = Utils._static_get_matching_node(child, script)
		if res != null: return res
	return null
static func _static_get_matching_nodes(node: Node, script) -> Array:
	if Utils.matches_class(node, script): return [node]
	var res = []
	for child in node.get_children():
		res += Utils._static_get_matching_nodes(child, script)
	return res
	
static func matches_class(obj, klass) -> bool:
	# A more permissive version of is class that checks:
	# * If obj is of the class (exact or subclass)
	# * If obj matches the class_name (e.g., a string was passed in)
	# * If obj is a node that has a script with the class
	# * If obj is a node that has a script with the class_name
	if klass is String or klass is StringName: return matches_class_name(obj, klass)
	else: return matches_class_type(obj, klass)

static func matches_class_name(obj, klass: String) -> bool:
	# Check if the object itself matches the class or any subclass
	if obj.is_class(klass): return true
	# Traverse through attached script and its base scripts
	var script = obj.get_script()
	while script:
		if klass.to_snake_case() in script.get_path(): return true
		script = script.get_base_script()
	return false
	
static func matches_class_type(obj, klass):
	# Check if the object is an instance of the class or inherits from it
	return is_instance_of(obj, klass)
