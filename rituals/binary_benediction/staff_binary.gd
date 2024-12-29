extends Staff
class_name StaffBinary

static func create(note_data: Dictionary) -> Staff:
	var new = preload("res://rituals/binary_benediction/staff_binary.tscn").instantiate() as Staff
	new.line_count = 2
	new.note_data = new.get_note_binary(note_data)
	return new
	
func get_note_binary(note_data: Dictionary) -> Dictionary:
	# Given a dict with note info, return the binary info for that dict
	# Given: {
	#	"text": "Oh spark divine, through circuits flow,",
	# 	"syllables": [{
	#		"espeak": "'oU", "text": "oh", "filename": "(pri)o^u",
	#	}, {
	#		"espeak": "sp'A@k", "text": "spark", "filename": "sp(pri)^a@k",
	#	},
	# 	...]
	# }
	# Returns: {
	#	"text" :"01001111011010000010000001...
	# 	"syllables": [{
	#		"espeak": "z'i@roU", "text": "0", "filename": "z(pri)i@ro^u",
	#	}, {
	#		"espeak": "w'0n", "text": "1", "filename": "w(pri)0n",
	#	},
	# 	...]
	# }
	var espeak_dict = {
		"0": "z'i@roU",
		"1": "w'0n",
	}
	var filename_dict = {
		"0": "z(pri)i@ro^u",
		"1": "w(pri)0n"
	}
	
	# Quick helper to convert a 1 or 0 to a list of info dicts for the notes
	var get_syllable_info = (func(s):
		return {
			"espeak": espeak_dict[s],
			"text": s,
			"filename": filename_dict[s],
		}
	)
	
	# For now, the binary of the entire line was too long,
	# so we hash it and use that
	var string_of_binary = byte_to_string(hash(note_data.get("text", "")))
	return {
		"text": string_of_binary,
		"syllables": Array(string_of_binary.split("")).map(get_syllable_info),
	}
	
func byte_to_string(byte: int) -> String:
	var bin_str = ""
	for i in range(16):
		bin_str = str(byte & 1) + bin_str
		byte >>= 1
	return bin_str
