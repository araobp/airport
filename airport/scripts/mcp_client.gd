extends Node

@export var chat_window: TextEdit

var utilities = load("res://scripts/utilities.gd").new()

@onready var visitor: CharacterBody3D = $"../"
@onready var wearable_device : Node3D = $"../WearableDevice"

@onready var	 gemini = load("res://scripts/gemini.gd").new(
			$HTTPRequest,
			Globals,
			true  # enable history
		)
		
@onready var gemini2 = load("res://scripts/gemini.gd").new(
			$HTTPRequest,
			Globals,
			false  # disable history
		)

##### Local tools #####
const SURROUNDINGS_TOOL = {
	"name": "take_surroundings",
	"description": """
	This function analyzes a picture of a visitor's surroundings to extract a zone ID.
	Upon successful recognition of both the zone and its surroundings, it calls a data logging function to record the user's visit.
	If they are not clear, output the most recent zone ID and the type of amenity from our chat history.
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

func capture_image_local():
	return await wearable_device.capture_image(visitor.camera_resolution_height, false)

func take_surroundings(_args):
	var base64_image = await wearable_device.capture_image(visitor.camera_resolution_height, false)
	var base64_image_wide = await wearable_device.capture_image(visitor.camera_resolution_height, true)
	
	var query = """
	I am {visitor_id}, which is also my Visitor ID.

	Please analyze the image from my wearable device's onboard camera. The analysis should provide a detailed description of my surroundings.

	If you identify an alphanumeric string with three hyphen-connected sections in the image, extract it and output that string as the zone ID.

	Additionally, if the string's color is green, append "-e" to the end and mention that . If the string's color is orange, append "-w". For example, if the extracted string is "2F-E-1" and the string is green, the output should be "2F-E-1-e"; if the string is orange, the output should be "2F-E-1-w".

	Output the final result in the following JSON format.

	If you do not identify such an alphanumeric string in the image, output "unknown" in the JSON format.

	If you identify multiple zone IDs in the image, please select the one in the center if you are confident in its accuracy. If there is no zone ID in the center, select the one that is closest (the largest) if you are confident in its accuracy. Do not mention any other node IDs.

	Output "zone_id_description_for_human" for a visitor to identify the ID on the wall. For example, "2F-D-11 in orange printed on the wall".

	You should output only the JSON data with no additional explanations.
	""".format({"visitor_id": visitor.visitor_id})
	
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
	
	var system_instruction = "You are an AI assistant good at image recognition."
	
	var result = await gemini2.chat(
		query,
		system_instruction,
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
	var column = chat_window.get_caret_column()
	var line = chat_window.get_caret_line()
	caret_pos_limit = [column, line]

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
	# List all the tools	
	var mcp_server = visitor.mcp_server

	var function_declarations = mcp_server.list_tools()
	function_declarations.append_array(self.list_tools())
	
	# print(function_declarations)
	
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
	
	chat_window.grab_focus()
	last_text = chat_window.text

# Steps of the visitor (accelerometer simulation)
var previous_steps = 0
var delta_steps = 0

# Rotation of the visitor (gyrometer simulation)
var previous_rotation_degrees = Vector3(0, 90, 0)
var delta_rotation_degrees_y = 0

var caret_pos_limit = [0, 0]

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
		delta_steps = wearable_device.steps - previous_steps
		previous_steps = wearable_device.steps
		
		# Calculate Delta rotation
		var delta_rotation_degrees = wearable_device.rotation_degrees - previous_rotation_degrees
		previous_rotation_degrees = wearable_device.rotation_degrees
		delta_rotation_degrees_y = delta_rotation_degrees.y  # Y-axis rotation
		
		var system_instruction = """
		You are the ABC Airport Concierge AI. You manage airport amenities and services in partnership with the wearable_device's wearable device.

		Your wearable_device ID is {visitor_id}.

		Your primary goal is to assist me. If you don't know the answer to a question, first get a visual of my surroundings by taking a picture, then respond.

		When performing a series of actions, always state what you are about to do before you do it. Do not mention function names.

		When a function requires a location and an amenity, use the most recent zone ID and amenity from our chat history.

		Do not use consecutive '\n' (something like '\n\n') when you output some text. Just use '\n'.
		""".format({
				"visitor_id": visitor.visitor_id
			})
			
		print("delta steps:" + str(delta_steps), ", delta rotation: ", str(delta_rotation_degrees_y))
		
		if abs(delta_steps) > visitor.delta_steps_threshold or abs(delta_rotation_degrees_y) > visitor.delta_rotation_threshold:
			query = """
			Take a picture to understand surroudings of the visitor, then respond to the following query:
				
			""" + query
	
		print(query)

		await gemini.chat(
			query,
			system_instruction,
			null,
			mcp_servers,
			null,
			output_text,
			self
			)
		
		_insert_text("\nYou: ")
		
		processing = false


func _input(event):
	if event is InputEventMouseButton or event is InputEventKey:
		call_deferred("_check_caret_position")
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE:
			_check_caret_position()

# Prevents the user from editing the previous conversation history by checking the caret position.
# If the caret is in a read-only area, it moves it to the beginning of the editable area.
func _check_caret_position():
	var line_limit = caret_pos_limit[1]
	var current_line = chat_window.get_caret_line()
	var current_column = chat_window.get_caret_column()

	var corrected = false
		
	if current_line < line_limit:
		chat_window.set_caret_line(caret_pos_limit[1])
		corrected = true
	elif current_line == caret_pos_limit[1] and current_column <= caret_pos_limit[0]:
		chat_window.set_caret_column(caret_pos_limit[0])
		corrected = true

	if corrected:
		get_viewport().set_input_as_handled()
