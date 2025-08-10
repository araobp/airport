extends Node3D

func gate_control(control):
	var state_machine = $AnimationTree["parameters/playback"]

	match control:
		"open":
			state_machine.travel("Open")
		"close":
			state_machine.travel("Close")

	return control
