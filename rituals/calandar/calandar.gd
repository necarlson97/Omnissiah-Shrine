extends Node2D


func _ready() -> void:
	set_days()

func set_days():
	# Create all X days of the year
	var unset_color = ThemeDB.get_project_theme().get_color("dark", "CSS")
	var today_color = ThemeDB.get_project_theme().get_color("bad", "CSS")
	var grid = $CanvasLayer/Control/MarginContainer/VBoxContainer/GridContainer
	
	var today = Kronos.get_day_of_year()
	for i in range(Kronos.get_days_in_year()):
		var new_day_node = preload(
			"res://rituals/calandar/day_progress.tscn").instantiate() as ProgressBar
		grid.add_child(new_day_node)
		var day_data = Archivist.load_day_info(i)
		
		if day_data == {}:
			set_bg_color(new_day_node, unset_color)
			new_day_node.value = 0
		else:
			new_day_node.value = day_data.get("correct ratio", 0.0)
		
		if i == today:
			set_bg_color(new_day_node, today_color)
	
func set_bg_color(pb: ProgressBar, color:Color):
	var bg_box: StyleBoxFlat = pb.get_theme_stylebox("background").duplicate()
	bg_box.bg_color = color
	pb.add_theme_stylebox_override("background", bg_box)

func _input(event: InputEvent):
	if not (event is InputEventKey and event.is_pressed()):
		return
	$SceneSwapper.next()
