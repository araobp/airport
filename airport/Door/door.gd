extends Node3D

var min_num_bodies = 10000
var state_machine
var forced_open = false

func _ready():
	state_machine = $AnimationTree["parameters/playback"]

func _process(delta):
	var num_boies = len($SensingArea.get_overlapping_bodies())
	min_num_bodies = min(min_num_bodies, num_boies)

	if num_boies > min_num_bodies:
		if state_machine.get_current_node() != "Open":
			state_machine.travel("Open")
	else:
		if state_machine.get_current_node() == "Open" and not forced_open:
			state_machine.travel("Close")
		
func door_control(control):
	var state_machine = $AnimationTree["parameters/playback"]

	match control:
		"open":
			state_machine.travel("Open")
			forced_open = true
		"close":
			state_machine.travel("Close")
			forced_open = false

	return control
