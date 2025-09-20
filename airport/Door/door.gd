extends Node3D

var forced_open = false
@onready var state_machine = $AnimationTree["parameters/playback"]
	
func _process(_delta):
	var visitors_in_the_area = false
	for body in $SensingArea.get_overlapping_bodies():
		if body.is_in_group("Visitors"):
			visitors_in_the_area = true
			if state_machine.get_current_node() != "Open":
				state_machine.travel("Open")
			
	if !visitors_in_the_area:
		if state_machine.get_current_node() == "Open" and not forced_open:
			state_machine.travel("Close")
		
func door_control(control):
	match control:
		"open":
			state_machine.travel("Open")
			forced_open = true
		"close":
			state_machine.travel("Close")
			forced_open = false

	return control
