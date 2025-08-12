extends Node

var mcp_server
var gemini

@export var first_person : CharacterBody3D

func _system_instruction():
	return """
	You are an AI agent good at controling facilities or amenities of ABC airport.
	My name is {name}. I am visiting the airport, and I am currently in {area}.
	When asked something, you make an action in the area I am currently in.
	If you do not know where I am, call the function to know the area first before making actions further.
	If the area is unkown, you just make a general reply such as "Which area do you want to ...".
	If you are asked "What can you do?" or something like that, show me the features of function calling for the airport.	
	""".format({
		"name": first_person.name,
		"area": $"../McpServer".get_area({"name": first_person.name})
		})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mcp_server = get_parent().get_node("McpServer")
	gemini = load("res://gemini.gd").new(
			$HTTPRequest
		)

	var tools = mcp_server.list_tools()

	$ChatWindow.grab_focus()
	$ChatWindow.insert_text_at_caret("Hit Tab key to hide or show this chat window. Ctrl-q to quit this simulator.\nWelcome to ABC Airport! What can I help you?\n\nYou: ")

var processing = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_text_indent"):
		$ChatWindow.visible = not $ChatWindow.visible
		if $ChatWindow.visible:
			Globals.chat_window_enabled = true
			$ChatWindow.grab_focus()
		else:
			Globals.chat_window_enabled = false

	if !processing and Input.is_key_pressed(KEY_ENTER) and $ChatWindow.text != "":
		processing = true
		var text = $ChatWindow.text
		var response_text = await gemini.chat(
			text,
			_system_instruction(),
			mcp_server
			)
		$ChatWindow.insert_text_at_caret("AI: {response_text}\nYou: ".format({"response_text": response_text}), -1)
		$ChatWindow.scroll_vertical = 10000
		processing = false
