extends Node

@export var first_person : CharacterBody3D
@export var camera_resolution_height: int = 360
@export_enum("gemini-2.0-flash", "gemini-2.5-flash") var llm_model: String = "gemini-2.5-flash"

@onready var	 mcp_server = get_node("/root/McpServer")
@onready var chat_window = $CanvasLayer/ChatWindow

var gemini
var gemini2

var last_text = ""

# Local tool
const CAMERA_TOOL = {
	"name": "take_photo",
	"description": """
	Know the visitor's surroundings from a picture taken with the onboard camera of the visitor's wearable device.
	This function uses LLM for image recognition.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"name": {
				"type": "string",
				"description": "Name of the person visiting the airport."
			}
		},
	"required": ["name"],
	}
}

const LOCAL_TOOLS = [
	CAMERA_TOOL
]

func list_tools():
	var tools = LOCAL_TOOLS.duplicate(true)
	for tool in tools:
		tool["name"] = "{server_name}.{tool_name}".format({"server_name": self.name, "tool_name": tool["name"]}) 
	return tools

func _system_instruction():
	return """You are an AI agent good at controlling the facilities or amenities of ABC Airport.  
You are also good at recognizing the attached image captured by the onboard camera of my wearable device.

My name is {name}. I am visiting the airport, and I am currently in {area}.  
When asked something, you take an action in the area I am currently in.

If you do not know where I am, call the function to determine the area first before taking further actions.  
If the area is unknown, you simply give a general reply such as "Which area do you want to ...".  
If you are asked "What can you do?" or something similar, show me the available function-calling features for the airport.

When you are executing functions in order, output some text before calling each function to explain what you are going to do with the function at each function call step.
Instead of mentioning function names, just mention what you are going to do.

Do not use consecutive '\n' (something like '\n\n') when you output some text. Just use '\n'.
""".format({
		"name": first_person.name,
		"area": mcp_server.get_area({"name": first_person.name})
	})
	

func take_photo(visitor_name):
	# Note: visitor_name if for future use
	var base64_image = first_person.capture_image(camera_resolution_height)
	const QUERY = "Recognize the attached image and output detailed explanations on it"		
	var result = await gemini2.chat(
		QUERY,
		_system_instruction(),
		base64_image
		)
	return result


var processing = false

# Insert text at caret in TextEdit
func _insert_text(text):
	chat_window.insert_text_at_caret(text, -1)
	chat_window.scroll_vertical = 10000
	last_text = chat_window.text

# Callback function to output response text from Gemini
func output_text(response_text):
	print("AI: " + response_text)
	# To make sure that the string ends with "\n\n" always
	response_text = response_text.strip_edges() + "\n"
	_insert_text("AI: " + response_text)

# MCP servers (mimicked)
var mcp_servers
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var function_declarations = mcp_server.list_tools()
	function_declarations.append_array(self.list_tools())
	
	mcp_servers = {
		"ref": {
			mcp_server.name: mcp_server,
			self.name: self
		},
		"tools": [
			{
				"functionDeclarations": function_declarations
			}
		]
	}
	
	gemini = load("res://gemini.gd").new(
			$HTTPRequest,
			llm_model,
			true  # enable history
		)
	gemini2 = load("res://gemini.gd").new(
			$HTTPRequest,
			llm_model,
			false  # disable history
		)

	chat_window.grab_focus()
	const WELCOME_MESSAGE = "Hit Tab key to hide or show this chat window. Ctrl-q to quit this simulator.\nWelcome to ABC Airport! What can I help you?\n\nYou: "
	chat_window.insert_text_at_caret(WELCOME_MESSAGE)
	last_text = WELCOME_MESSAGE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_text_indent"):
		chat_window.visible = not chat_window.visible
		if chat_window.visible:
			chat_window.grab_focus()
			Globals.mode = Globals.MODE.CHAT
		else:
			Globals.mode = Globals.MODE.CONTROL
			
	if !processing and Input.is_key_pressed(KEY_ENTER) and chat_window.text != "":
		processing = true

		var query = chat_window.text.replace(last_text, "")
		print("You: " + query)
						
		await gemini.chat(
			query,
			_system_instruction(),
			null,
			mcp_servers,
			output_text
			)
		
		_insert_text("\nYou: ")
		processing = false
