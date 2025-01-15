extends Node
class_name Kronos
# Master of time

static func get_imperial_date() -> String:
	# Returns the str date in our stylization the 40k imperial format:
	# check # (0 for earth) . year fraction . year . millenium
	# Year Fraction - each year is divided into 1000 equal parts, numbered 001-000
	# (apx 8 hours and 45 minutes each)
	# E.g: for 18 July 2005 at 4pm
	# July 18th is the 200th day of 2005
	# So 4m woulb be the 200 x 24 + 16 = 4816 hour of the year
	# Multiplied by the 'Makr Constant': 0.11407955. 4816 x 0.11407955 = 549.41.
	# So 549 is the year fraction. Always round down
	# E.g.: 18 July 2005 at 4pm would become:
	# 0.549.005.M3
	var datetime = Time.get_datetime_dict_from_system()
	
	# Extract date components
	var year = datetime.year
	var day_of_year = get_day_of_year(datetime)
	var hour_of_day = datetime.hour
	var minute_of_hour = datetime.minute
	var second_of_minute = datetime.second
	
	# Calculate the year fraction
	var days_in_year = get_days_in_year(datetime)
	var total_seconds_in_year = days_in_year * 24 * 3600
	var seconds_per_fraction = total_seconds_in_year / 1000
	
	var seconds_elapsed = (
		(day_of_year - 1) * 24 * 3600
		+ hour_of_day * 3600
		+ minute_of_hour * 60
		+ second_of_minute
	)
	var year_fraction = seconds_elapsed / seconds_per_fraction
	var millennium = year / 1000 + 1

	return "0.%03d.%03d.M%d" % [year_fraction, year % 1000, millennium]

static func get_day_of_year(datetime=null) -> int:
	# Returns day of the year (current or given datetime)
	if datetime == null:
		datetime = Time.get_datetime_dict_from_system()
	
	var days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if is_leap_year(datetime.year):
		days_in_months[1] = 29 # Adjust for leap year
	
	var day_of_year = 0
	for i in range(datetime.month - 1):
		day_of_year += days_in_months[i]
	day_of_year += datetime.day
	
	return day_of_year

static func get_days_in_year(datetime=null):
	if datetime == null:
		datetime = Time.get_datetime_dict_from_system()
	return 366 if is_leap_year(datetime.year) else 365

static func is_leap_year(year: int) -> bool:
	# Checks if a year is a leap year
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
