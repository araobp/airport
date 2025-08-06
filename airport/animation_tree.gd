extends AnimationTree


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func open():
	var state_machine = self["parameters/playback"]
	state_machine.travel("Open")
	
func close():
	var state_machine = self["parameters/playback"]
	state_machine.travel("Close")
	
