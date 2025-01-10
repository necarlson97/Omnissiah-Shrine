extends Label

var speed = 1
func _ready() -> void:
	text = Kronos.get_imperial_date()
	print("Imperial date: %s"%text)
	visible_ratio = 0

func _process(delta: float) -> void:
	visible_ratio += delta * speed
