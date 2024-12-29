# Juice.gd
extends Node2D

# Global static list of all active juice nodes
static var juice_nodes: Array = []

# Any time player performance changes, trigger the subclasses that
# care about that
var player_performance: int:
	set(value):
		if value != last_player_performance:
			# Notify subclasses of the change
			on_performance_change(value, last_player_performance)
			last_player_performance = value
		player_performance = value
var last_player_performance: int = 0

# Automatically register subclasses to keep track of them
func _ready() -> void:
	juice_nodes.append(self)
func _exit_tree() -> void:
	juice_nodes.erase(self)

# 'Abstract' method for subclasses to handle performance changes
func on_performance_change(new_value: int, old_value: int) -> void:
	pass 

# 'Abstract' method for subclasses to implement per-frame logic
func _process(delta: float) -> void:
	pass
