extends Node

var mcp_server
var gemini

var lastText = ""

@export var first_person : CharacterBody3D
@export var camera_resolution_height: int = 360

var utilities = preload("res://utilities.gd").new()

func _capture_image():

	var image = get_viewport().get_texture().get_image()
	
	# Resize the image to make the size smaller
	var h = image.get_height()
	var w = image.get_width()
	var camera_resolution_width = w * camera_resolution_height / h
	image.resize(camera_resolution_width, camera_resolution_height, Image.INTERPOLATE_BILINEAR)
	
	# Encode the image to Base64
	var b64image = Marshalls.raw_to_base64(image.save_jpg_to_buffer())
	
	return b64image

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
		"area": $"../McpServer".get_area({"name": first_person.name})
		})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mcp_server = get_parent().get_node("McpServer")
	var callback_ref = output_text
	gemini = load("res://gemini.gd").new(
			$HTTPRequest,
			callback_ref
		)

	var tools = mcp_server.list_tools()

	$ChatWindow.grab_focus()
	const WELCOME_MESSAGE = "Hit Tab key to hide or show this chat window. Ctrl-q to quit this simulator.\nWelcome to ABC Airport! What can I help you?\n\nYou: "
	$ChatWindow.insert_text_at_caret(WELCOME_MESSAGE)
	lastText = WELCOME_MESSAGE

var processing = false

func _add_text(text):
	$ChatWindow.insert_text_at_caret(text, -1)
	$ChatWindow.scroll_vertical = 10000
	lastText = $ChatWindow.text

func output_text(response_text):
	print("AI: " + response_text)
	# To make sure that the string ends with "\n\n" always
	response_text = response_text.dedent() + "\n"
	_add_text("AI: " + response_text)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_text_indent"):
		$ChatWindow.visible = not $ChatWindow.visible
		if $ChatWindow.visible:
			$ChatWindow.grab_focus()

	if !processing and Input.is_key_pressed(KEY_ENTER) and $ChatWindow.text != "":
		processing = true

		var query = utilities.get_newly_added_lines(lastText, $ChatWindow.text).replace("You: ", "")
		print("You: " + query)
		
		$ChatWindow.visible = false
		await get_tree().process_frame
		var base64_image = await _capture_image()
		$ChatWindow.visible = true
		$ChatWindow.grab_focus()
				
		await gemini.chat(
			query,
			_system_instruction(),
			mcp_server,
			base64_image
			)
		
		_add_text("\nYou: ")
		processing = false
