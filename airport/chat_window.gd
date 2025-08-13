extends TextEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the evious frame.
func _process(delta: float) -> void:
	if self.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Disable tab key to insert tab space in TextEdit
func _gui_input(event):
	if event.is_action_pressed("ui_focus_next"):
		get_viewport().set_input_as_handled()
		
