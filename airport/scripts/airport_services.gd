extends Node3D

@export var LAST_N = 128

@onready var doors = $Doors.get_children()

var utilities = load("res://scripts/utilities.gd").new()
	
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


func get_product_info(visitor_id, zone_id, amenity, base64_image):
		return "$3"
