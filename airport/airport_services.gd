extends Node3D

@onready var doors = $Doors.get_children()

var user_data = []

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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

func record_user_data(visitor_id, zone_id, amenities):
	var current_time_string = Time.get_datetime_string_from_system()
	var record = {"time": current_time_string, "visitor_id": visitor_id, "zone_id": zone_id, "amenities": amenities}
	user_data.append(record)
	print(record)
	
	var file = FileAccess.open(LOCATIONS_JSON_FILE, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(record) + ",")  # Append record
		file.close()	
	else:
		push_error("Cannot open locations.json")

func generate_network_graph():
	var file = FileAccess.open(LOCATIONS_JSON_FILE, FileAccess.READ)
	var data = []
	if file:
		var text = file.get_as_text()
	else:
		push_error("Cannot open locations.json")
	
