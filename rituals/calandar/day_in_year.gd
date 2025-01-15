extends Label


@onready var today = Kronos.get_day_of_year()
@onready var total = Kronos.get_days_in_year()
var currently_displayed = 0.0

func _process(delta: float) -> void:
	# 'Count up' to dispalying the right day
	currently_displayed = lerpf(currently_displayed, today, delta * 3)
	if abs(currently_displayed - today) < 0.1:
		currently_displayed = today
	var str = "%03d/%s  "%[currently_displayed, total]
	text = str
