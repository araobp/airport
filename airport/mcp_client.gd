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
const SURROUNDINGS_TOOL = {
	"name": "take_surroundings",
	"description": """
	This function analyzes a picture of a visitor's surroundings to extract a zone ID.
	Upon successful recognition of both the zone and its surroundings, it calls a data logging function to record the user's visit.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string",
				"description": "Visitor ID"
			},
		},
		"required": ["visitor_id"],
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
	SURROUNDINGS_TOOL,
	QUIT_TOOL
]

func list_tools():
	var tools = LOCAL_TOOLS.duplicate(true)
	for tool in tools:
		tool["name"] = "{server_name}_{tool_name}".format({"server_name": self.name, "tool_name": tool["name"]}) 
	return tools

func _system_instruction(visitor_id, delta_steps_, delta_rotation_degrees_y_):
	return """
	You are an AI agent that controls and manages the amenities of ABC Airport.

	My name is {visitor_id}, which is also my Visitor ID, and I am visiting the airport.

	You can also recognize images captured by the onboard camera of my wearable device.

	According to the pedometer in my wearable device, I have advanced {delta_steps} steps since the last inquiry.
	According to the device's gyroscope, my gaze has rotated {delta_rotation_degrees_y} degrees on the vertical axis since the last inquiry. A negative rotation value means clockwise, and a positive value means counter-clockwise.

	Please refer to our past conversation history, as well as the steps and rotation information, to answer my various questions to the best of your ability.

	Please take a picture of my surroundings before making an action if any of the following conditions apply:
	- You don't know how to answer my question.
	- I have advanced over 5 steps since the last query.
	- My gaze has rotated over 20 degrees on the vertical axis since the last query.
	
	When executing functions in order, describe what you are about to do before calling each function. Do not mention the function names themselves.

	Do not use consecutive '\n' (something like '\n\n') when you output some text. Just use '\n'.
	""".format({
			"visitor_id": visitor_id,
			"delta_steps": delta_steps_,
			"delta_rotation_degrees_y": round(delta_rotation_degrees_y_)
		})
		
func take_surroundings(args):
	print(args)
	var visitor_id = args["visitor_id"]
	
	var base64_image = await first_person.capture_image(camera_resolution_height, false)
	var base64_image_wide = await first_person.capture_image(camera_resolution_height, true)
	
	var query = """
	I am {visitor_id}, which is also my Visitor ID.

	Please recognize my surroundings from a picture taken with the onboard camera of my wearable device.

	If you identify an alphanumeric string with three hyphen-connected sections in the image, extract it and output that string as the zone ID.

	Additionally, if the string's color is green, append "-e" to the end and mention that . If the string's color is orange, append "-w". For example, if the extracted string is "2F-E-1" and the string is green, the output should be "2F-E-1-e"; if the string is orange, the output should be "2F-E-1-w".

	Output the final result in the following JSON format.

	If you do not identify such an alphanumeric string in the image, output "unknown" in the JSON format.

	If you identify multiple zone IDs in the image, please select the one in the center if you are confident in its accuracy. If there is no zone ID in the center, select the one that is closest (the largest) if you are confident in its accuracy. Do not mention any other node IDs.

	Output "zone_id_description_for_human" for a visitor to identify the ID on the wall. For example, "2F-D-11 in orange printed on the wall".

	You should output only the JSON data with no additional explanations.
	""".format({"visitor_id": visitor_id})
	
	const json_schema = {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string"
			},
			"zone_id": {
				"type": "string"
			},
			"zone_id_description_for_human": {
				"type": "string"				
			},
			"surroundings": {
				"type": "string"
			}
		},
		"required": ["visitor_id", "zone_id", "zone_id_description_for_human", "surroundings"]
	}
		
	var result = await gemini2.chat(
		query,
		_system_instruction(first_person.name, delta_steps, delta_rotation_degrees_y),
		[ base64_image, base64_image_wide ],
		null,
		json_schema
		)

	# Remove the code block notation: ```json{...}```
	result = result.replace("```json", "").replace("```", "")
	print(result)
	var json = JSON.parse_string(result)
	if json:
		return JSON.stringify(json)
	else:  # JSON parse failed
		return "unknown"


func quit(_args):
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
	# Share Gemini API key with other scripts
	# Note: sharing a secret key is not normal in a real case.
	Globals.gemini_api_key = gemini_api_key
	Globals.gemini_model = gemini_model

	# List all the tools	
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

# Steps of the first person
var previous_steps = 0
var delta_steps = 0

# Rotation of the first person
var previous_rotation_degrees = Vector3(0, 90, 0)
var delta_rotation_degrees_y = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
		
		# Calculate Delta steps
		delta_steps = first_person.steps - previous_steps
		previous_steps = first_person.steps
		print(delta_steps)
		
		# Calculate Delta rotation
		var delta_rotation_degrees = first_person.rotation_degrees - previous_rotation_degrees
		previous_rotation_degrees = first_person.rotation_degrees
		delta_rotation_degrees_y = delta_rotation_degrees.y  # Y-axis rotation
		
		await gemini.chat(
			query,
			_system_instruction(first_person.name, delta_steps, delta_rotation_degrees_y),
			null,
			mcp_servers,
			null,
			output_text
			)
		
		_insert_text("\nYou: ")
		processing = false
