extends TextureRect
class_name EntryChar

var correct_texture: Texture2D

func check_texture(tex: Texture2D) -> bool:
	texture = tex
	var color_name = "bad"
	if is_correct():
		color_name = "good"
	self_modulate = ThemeDB.get_project_theme().get_color(color_name, "CSS")
	return is_correct()

func set_correct_texture(tex: Texture2D):
	get_node("%s"%name).texture = tex
	correct_texture = tex
	# Set to the 'unset' color
	self_modulate = ThemeDB.get_project_theme().get_color("darker", "CSS")

func is_correct() -> bool:
	return texture == correct_texture
