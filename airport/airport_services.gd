extends Node3D

@export var LAST_N = 128

@onready var doors = $Doors.get_children()

var utilities = load("res://utilities.gd").new()

var user_data = []

var _gemini = null

func get_gemini():
	if not _gemini:
		_gemini = load("res://gemini.gd").new(
			$HTTPRequest,
			Globals.gemini_api_key,
			Globals.gemini_model
		)
	return _gemini
	
func greeting(visitor_id):
	var message = visitor_id + ", welcome to ABC Airport!"
	# print(message)
	return message

func door_control(zone_id, control):
	if zone_id.ends_with("-w"):
		zone_id = zone_id.replace("-w", "").replace("-D-", "-E-")
	elif zone_id.ends_with("-e"):
		zone_id = zone_id.replace("-e", "")
	
	var doors_found = false
	for door in doors:
		if door.name.begins_with(zone_id):
			await door.door_control(control)
			doors_found = true
	if doors_found:
		return "Operation completed"
	else:
		return "Door not found"

const LOG_FILE_PATH = "res://locations.json"

func record_log(visitor_id, zone_id, amenities):
	var current_time_string = Time.get_datetime_string_from_system()
	var record = {"time": current_time_string, "visitor_id": visitor_id, "zone_id": zone_id, "amenities": amenities}
	user_data.append(record)
	print(record)
	
	var file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(record) + ",")  # Append record
		file.close()
	else:
		push_error("Cannot open locations.json")

func list_amenities_nearby(visitor_id, zone_id="unknown", amenity="unknown"):
	var log_data = utilities.get_last_n_lines(LOG_FILE_PATH, LAST_N)
	if log_data:
		var query = """
		An airport visitor (Visitor ID: {visitor_id}) is currently near Zone {zone_id}.
		Please guide the visitor to the {amenity} category, referring to the log data.
		- If both the zone and category are unknown, please list all amenities.
		- If the zone is unknown, please list all amenities within that category.
		- If the category is unknown, please list all amenities near that zone.
		"""
				
		query = query.format({"visitor_id": visitor_id, "zone_id": zone_id, "amenity": amenity})
		query += """
		## Log data
		
		{log_data}
		""".format({"log_data": log_data})
		
		const system_instruction = """
		You are an AI assistant serving as an information desk at an airport.
		Please DO NOT include visitor_id in your response, since visitor_id is private.
		"""
		
		var result = await get_gemini().chat(
			query,
			system_instruction
		)
			
		print("AMENITIES: ", result)
		return result

	else:
		push_error("Cannot open " + LOG_FILE_PATH)
		return "System error"
