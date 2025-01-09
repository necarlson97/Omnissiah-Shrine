extends TextureRect

var target_color

func _ready() -> void:
	target_color = ThemeDB.get_project_theme().get_color("dark", "CSS")
	
func _process(delta: float) -> void:
	modulate = modulate.lerp(target_color, 0.04)

func was_pressed():
	modulate = Color.WHITE
