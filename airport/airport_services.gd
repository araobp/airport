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
	zone_id = zone_id.replace("-w", "").replace("-e", "")
	for door in doors:
		if door.name.begins_with(zone_id):
			await door.door_control(control)
	return

const LOCATIONS_JSON_FILE = "res://locations.json"

func record_log(visitor_id, zone_id, amenities):
	var current_time_string = Time.get_datetime_string_from_system()
	var record = {"time": current_time_string, "visitor_id": visitor_id, "zone_id": zone_id, "amenities": amenities}
	user_data.append(record)
	print(record)
	
	var file = FileAccess.open(LOCATIONS_JSON_FILE, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(record) + ",")  # Append record
		file.close()
	else:
		push_error("Cannot open locations.json")

func list_amenities_nearby(visitor_id, zone_id:Variant=null, amenity:Variant=null):
	var log_data = utilities.get_last_n_lines(LOCATIONS_JSON_FILE, LAST_N)
	if log_data:
		var query
		if zone_id and not amenity:
			query = """
			An airport visitor (visitor_id: {visitor_id}) is currently in the vicinity of {zone_id}.
			Please list all the amenities in the surrounding area, referring to the log data.
			"""
		elif not zone_id and amenity:
			query = """
			Please list all {amenity} with its "zone_id" in the airport, referring to the log data.
			"""
		elif zone_id and amenity:
			query = """
			An airport visitor (visitor_id: {visitor_id}) is currently near zone {zone_id}.
			Please navigate the visitor to {amenity}, referring to the log data.
			"""
		else:
			push_error("Invalid arguments")
			return "Invalid arguments"
				
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
		push_error("Cannot open " + LOCATIONS_JSON_FILE)
		return "System error"
