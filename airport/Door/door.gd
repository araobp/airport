extends Node3D

var forced_open = false
@onready var state_machine = $AnimationTree["parameters/playback"]
	
func _process(_delta):
	if len($SensingArea.get_overlapping_bodies()) > 0:
		if state_machine.get_current_node() != "Open":
			state_machine.travel("Open")
	elif state_machine.get_current_node() == "Open" and not forced_open:
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
