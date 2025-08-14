extends Node3D

@onready var doors = $Doors.get_children()

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func door_control(zone_id, control):
	zone_id = zone_id.replace("-w", "").replace("-e", "")
	for door in doors:
		if door.name.begins_with(zone_id):
			await door.door_control(control)
	return
