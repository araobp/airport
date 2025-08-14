extends Node

@export var first_person : CharacterBody3D
@export var camera_resolution_height: int = 360
@export var gemini_api_key = ""
@export_enum("gemini-2.0-flash", "gemini-2.5-flash") var gemini_model: String = "gemini-2.5-flash"

var utilities = load("res://utilities.gd").new()

@onready var	 mcp_server = get_node("/root/McpServer")
@onready var chat_window = $CanvasLayer/ChatWindow

var gemini  # for AI Agent processing
var gemini2  # for McpClient local tools

##### Local tools #####
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

const ZOON_TOOL = {
	"name": "get_zone_id",
	"description": """
	A function to get the zone ID of the location where the person is. The zone id represents the visitor's location in the airport."
	""",
	"parameters": {
		"type": "object",
		"properties": {},
		"required": [],
	}
}

const QUIT_TOOL = {
	"name": "quit",
	"description": """
	A function to quit this journey.
	Note: before calling this function, output some goodbye message in text, wait for three seconds then call this function to quit this journey."
	""",
	"parameters": {
		"type": "object",
		"properties": {},
		"required": [],
	}
}


const LOCAL_TOOLS = [
	CAMERA_TOOL,
	ZOON_TOOL,
	QUIT_TOOL
]

func list_tools():
	var tools = LOCAL_TOOLS.duplicate(true)
	for tool in tools:
		tool["name"] = "{server_name}.{tool_name}".format({"server_name": self.name, "tool_name": tool["name"]}) 
	return tools

func _system_instruction():
	return """You are an AI agent that controls the facilities and amenities of ABC Airport. You can also recognize images captured by the onboard camera of my wearable device.

My name is {name}, and I'm visiting the airport.

If you need to know my location, first determine my zone ID before taking any further actions.

When executing functions in order, describe what you are about to do before calling each function. Do not mention the function names themselves.

Do not use consecutive '\n' (something like '\n\n') when you output some text. Just use '\n'.
""".format({
		"name": first_person.name
	})
	

func take_photo(visitor_name):
	# Note: visitor_name if for future use
	var base64_image = await first_person.capture_image(camera_resolution_height)
	const QUERY = "Recognize the attached image and output detailed explanations on it"		
	var result = await gemini2.chat(
		QUERY,
		_system_instruction(),
		base64_image
		)
	return result
	
func get_zone_id(args):
	var base64_image = await first_person.capture_image(camera_resolution_height, true)
	const QUERY = """
	If you identify three alphanumeric strings connected by hyphens in the image,
	extract it and output that string.
	
	Additionally, if the color of the string is green, append "-e" to the end of the string, and if it's orange, append "-w". For example, if the extracted string is 2F-E-1, and the string is green, the output should be 2F-E-1-e; if the string is orange, the output should be 2F-E-1-w.
	Output the final result in the following JSON format.
	
	If you do not identify such three alphanumeric strings in the image, output "unknown" following the JSON format.

	## JSON Format
	
	{"zone_id": "..."}
	"""
	
	const json_schema = {
		"type": "object",
		"properties": {
			"zone_id": {
				"type": "string"
			}
		},
		"required": ["zone_id"]
	}
	
	var result = await gemini2.chat(
		QUERY,
		_system_instruction(),
		base64_image,
		null,
		json_schema
		)

	# Remove the code block notation: ```json{...}```
	result = result.replace("```json", "").replace("```", "")
	print(result)
	var json = JSON.parse_string(result)
	if json:
		return json["zone_id"]
	else:  # JSON parse failed
		return "unknown"


func quit(args):
	return await utilities.quit(get_tree())

var processing = false

######

var last_text = ""

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
			gemini_api_key,
			gemini_model,
			true  # enable history
		)
	gemini2 = load("res://gemini.gd").new(
			$HTTPRequest,
			gemini_api_key,
			gemini_model,
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
			null,
			output_text
			)
		
		_insert_text("\nYou: ")
		processing = false
