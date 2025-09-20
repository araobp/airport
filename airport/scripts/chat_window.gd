# This class extends TextEdit into a chat UI for GenAI.
extends TextEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	const WELCOME_MESSAGE = "Hit Tab key to hide or show this chat window. 'Ctrl-.' to quit this simulator.\nWelcome to ABC Airport! What can I help you?\n\nYou: "
	insert_message(WELCOME_MESSAGE)
	grab_focus()

# Called every frame. 'delta' is the elapsed time since the evious frame.
func _process(_delta: float) -> void:
	if self.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _gui_input(event):
	# Disable tab key to insert tab space in TextEdit
	if event.is_action_pressed("ui_focus_next"):
		get_viewport().set_input_as_handled()
	
	# Caret positon check
	if event is InputEventKey and event.keycode == KEY_BACKSPACE:
		_check_caret_position()
	elif event is InputEventMouseButton or event is InputEventKey:
		call_deferred("_check_caret_position")

var caret_pos_limit = [0, 0]

# Prevents the user from editing the previous conversation history by checking the caret position.
# If the caret is in a read-only area, it moves it to the beginning of the editable area.
func _check_caret_position():
	var line_limit = caret_pos_limit[1]
	var current_line = get_caret_line()
	var current_column = get_caret_column()
	# print("caret", current_line, ",", current_column)
	
	var corrected = false
		
	if current_line < line_limit:
		set_caret_line(caret_pos_limit[1])
		corrected = true
	elif current_line == caret_pos_limit[1] and current_column <= caret_pos_limit[0]:
		set_caret_column(caret_pos_limit[0])
		corrected = true

	if corrected:
		get_viewport().set_input_as_handled()

var last_text = ""

# Insert text at caret in TextEdit
func insert_message(text):
	insert_text_at_caret(text, -1)
	scroll_vertical = 10000
	last_text = self.text
	var column = get_caret_column()
	var line = get_caret_line()
	caret_pos_limit = [column, line]

# Callback function to output response text from Gemini
func output_message(response_text):
	# print("AI: " + response_text)
	# To make sure that the string ends with "\n\n" always
	response_text = response_text.strip_edges() + "\n"
	insert_message("AI: " + response_text)

var query: String = "":
	get:
		return text.replace(last_text, "")
