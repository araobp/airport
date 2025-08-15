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

func record_user_data(visitor_id, zone_id, amenities):
	user_data.append({"visitor_id": visitor_id, "zone_id": zone_id, "amenities": amenities})
	print(user_data)
	return
	
