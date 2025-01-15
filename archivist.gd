extends Node
class_name Archivist

static func load_day_info(day: int=-1) -> Dictionary:
	if day == -1:
		day = Kronos.get_day_of_year()
	var json = JSON.new()

	var filename = "user://day_%s.json"%str(day)
	var file = FileAccess.open(filename, FileAccess.READ)
	if file != null:
		var error = json.parse(file.get_as_text())
		if error != OK:
			push_error(
				"JSON Parse Error: %s in %s at line %s"%
				[json.get_error_message(), filename, json.get_error_line()]
			)
			return {}
		file.close()

	return json.data if json.data else {}

static func save_day_info(data: Dictionary, day: int=-1) -> void:
	if day == -1:
		day = Kronos.get_day_of_year()
	var json = JSON.new()

	var filename = "user://day_%s.json"%str(day)
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(json.stringify(data))
	file.close()
	
	print("Saved to %s:"%filename)
	print(data)
