extends Node

@onready var	 mcp_server = get_node("/root/McpServer")

var gemini

var lastText = ""

@export var first_person : CharacterBody3D
@export var camera_resolution_height: int = 360

@onready var chatWindow = $CanvasLayer/ChatWindow

var utilities = preload("res://utilities.gd").new()

func _system_instruction():
	return """
	You are an AI agent good at controling facilities or amenities of ABC airport.
	You are also good at recognizing the attached image captured by an onboard camera of my wearable device.

	My name is {name}. I am visiting the airport, and I am currently in {area}.
	When asked something, you make an action in the area I am currently in.

	If you do not know where I am, call the function to know the area first before making actions further.
	If the area is unkown, you just make a general reply such as "Which area do you want to ...".
	If you are asked "What can you do?" or something like that, show me the features of function calling for the airport.	
	""".format({
		"name": first_person.name,
		"area": mcp_server.get_area({"name": first_person.name})
		})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(mcp_server.name)
	var callback_ref = output_text
	gemini = load("res://gemini.gd").new(
			$HTTPRequest,
			callback_ref
		)

	var tools = mcp_server.list_tools()

	chatWindow.grab_focus()
	const WELCOME_MESSAGE = "Hit Tab key to hide or show this chat window. Ctrl-q to quit this simulator.\nWelcome to ABC Airport! What can I help you?\n\nYou: "
	chatWindow.insert_text_at_caret(WELCOME_MESSAGE)
	lastText = WELCOME_MESSAGE

var processing = false

func _add_text(text):
	chatWindow.insert_text_at_caret(text, -1)
	chatWindow.scroll_vertical = 10000
	lastText = chatWindow.text

func output_text(response_text):
	print("AI: " + response_text)
	# To make sure that the string ends with "\n\n" always
	response_text = response_text.dedent() + "\n"
	_add_text("AI: " + response_text)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_text_indent"):
		chatWindow.visible = not chatWindow.visible
		if chatWindow.visible:
			chatWindow.grab_focus()
			Globals.mode = Globals.MODE.CHAT
		else:
			Globals.mode = Globals.MODE.CONTROL
			
	if !processing and Input.is_key_pressed(KEY_ENTER) and chatWindow.text != "":
		processing = true

		var query = utilities.get_newly_added_lines(lastText, chatWindow.text).replace("You: ", "")
		print("You: " + query)
		
		var base64_image = first_person.capture_image(camera_resolution_height)
				
		await gemini.chat(
			query,
			_system_instruction(),
			mcp_server,
			base64_image
			)
		
		_add_text("\nYou: ")
		processing = false
