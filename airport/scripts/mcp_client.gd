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

##### For chat analysis #####
@onready var	 gemini2 = load("res://scripts/gemini.gd").new(
			$HTTPRequest,
			Globals,
			true  # enable history
		)		

##### Local tools ##################################################################################

const SURROUNDINGS_TOOL = {
	"name": "take_surroundings",
	"description": """
	This function takes a picture of the visitor's surroundings from an onboard camera of the visitor's wearable device, and outputs a Base64-encoded image URL.
	This function outputs two images:
	- Normal Field-of-View image
	- Wide Field-of-View image

	How to analyze the images:
	- If you identify an alphanumeric string with three hyphen-connected sections in the image, extract it and output that string as the zone ID. Additionally, if the string's color is green, append "-e" to the end and mention that . If the string's color is orange, append "-w". For example, if the extracted string is "2F-E-1" and the string is green, the output should be "2F-E-1-e"; if the string is orange, the output should be "2F-E-1-w".
	- If you identify multiple zone IDs in the image, please select the one in the center if you are confident in its accuracy. If there is no zone ID in the center, select the one that is closest (the largest) if you are confident in its accuracy. Do not mention any other node IDs.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string",
				"description": "Visitor ID"
			},
			"as_content": {
				"type": "boolean",
				"description": "this value MUST be always true"
			}
		},
		"required": ["visitor_id", "as_content"],
	}
}

func capture_image_local():
	return await wearable_device.capture_image(visitor.camera_resolution_height, false)

func take_surroundings(_args):
	var base64_image = await wearable_device.capture_image(visitor.camera_resolution_height, false)
	var base64_image_wide = await wearable_device.capture_image(visitor.camera_resolution_height, true)
	
	var content = { 
		"role": "user",
		"parts": [
	  		{
				"text": "Here are the images you requested, and the first one is normal FOV image, and the second one is wider FOV image. Go on to the next step as you planned before.",
	  		},
			{
				"inline_data": {
					"mime_type":"image/jpeg",
					"data": base64_image
				}
			},
			{
				"inline_data": {
					"mime_type":"image/jpeg",
					"data": base64_image_wide
				}
			}
		]
	}

	return {
		"result": {
			"reulst":
			"Took a picutre, analyze the following content which is a Base64-encoded image URL as you requested."
		},
		"content": content
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

func quit(_args):
	return await utilities.quit(get_tree())

const USER_FEEDBACK_TOOL = {
	"name": "analyze_user_feedback",
	"description": """
	If a query contains a user feedback or an emotional expression (a complaint or praise) regarding the result of a generative AI's processing on the airport services, call this function.
	The analysis result will be saved in a separate file as long-term memory for later use.
	If some sort of user feed back registration service is available in the context of where I am now, call the service after having received the result from this tool.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"query": {
				"type": "string",
				"description": "A query containing a user feedback or an emotinal expression."
			}
		},
		"required": ["query"]
	}
}

func analyze_user_feedback(args):
	
	var previous_query = args["query"]
	
	var system_instruction = """
		You are the ABC Airport Concierge AI. You manage airport amenities and services in partnership with the wearable_device's wearable device.

		My Visitor ID is {visitor_id}. Your primary goal is to assist me.
		""".format({
				"visitor_id": visitor.visitor_id
			})
	
	var prompt = """
	The previous query contains a user feedback or an emotional expression (a complaint or praise).
	Extract which part of the chat history the expression is directed at.
	In the case of a complaint, consider how the processing could be improved to work more effectively.
	In the case of praise, summarize the successful processing steps.
	Output the results in JSON data following the JSON schema.
	
	## Previous query
	{previous_query}
	
	""".format({
		"previous_query": previous_query
	})
	
	# Set chat history for emotinal analysis on this visitor	
	var content_func_res = [
		{
			"role": "function",
			"parts": {
				"functionResponse": {
					"name": "analyze_user_feedback",
					"response": {"result": "user feedback analyisis completed"}
				}
			}
		}
	]
	
	# Copy the chat history to another gemini instance for user feedback analysis
	gemini2.chat_history = gemini.chat_history.duplicate(true)
	# Request for user feedback analysis
	var json = await gemini2.chat(
		prompt,
		system_instruction,
		null,
		null,
		utilities.JSON_SCHEMA_FOR_USER_FEEDBACK
	)
	
	print("**********", json)
	return JSON.parse_string(json)


################################################################################

var processing = false

# MCP servers (mimicked)
var mcp_servers

var guidelines = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# List all the tools	
	var mcp_server = visitor.mcp_server

	var function_declarations = mcp_server.list_tools()
	function_declarations.append_array(self.list_tools())
	
	# TODO: this kind of info retrieval is also necessary aside MCP.
	# - user profile
	# - guidelines
	# What is the best way to retrive this kind of info? Plug&Play manner?
	var guidelines_ = mcp_server.retrieve_guidelines()
	guidelines.append({mcp_server.name: guidelines_})
	
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

		var query = chat_window.query
		
		# Calculate Delta steps
		delta_steps = wearable_device.steps - previous_steps
		previous_steps = wearable_device.steps
		
		# Calculate Delta rotation
		var delta_rotation_degrees = wearable_device.global_rotation_degrees - previous_rotation_degrees
		previous_rotation_degrees = wearable_device.global_rotation_degrees
		delta_rotation_degrees_y = delta_rotation_degrees.y  # Y-axis rotation
		
		var system_instruction = """
		You are the ABC Airport Concierge AI. You manage airport amenities and services in partnership with the wearable_device's wearable device.

		My Visitor ID is {visitor_id}.

		Your primary goal is to assist me. If you don't know the answer to a question, first get a visual of my surroundings by taking a picture, then respond.

		When performing a series of actions, always state what you are about to do before you do it. Do not mention function names.

		When a function requires a location and an amenity, use the most recent zone ID and amenity from our chat history.

		Do not use consecutive '\n' (something like '\n\n') when you output some text. Just use '\n'.
		
		Consult the following guidelines:
			
		{guidelines}
		
		""".format({
				"visitor_id": visitor.visitor_id,
				"guidelines": guidelines
			})
			
		print("delta steps:" + str(delta_steps), ", delta rotation: ", str(delta_rotation_degrees_y))
		
		if abs(delta_steps) > visitor.delta_steps_threshold or abs(delta_rotation_degrees_y) > visitor.delta_rotation_threshold:
			query = """
			Take a picture to understand surroudings of the visitor, then respond to the following query:
				
			""" + query
	
		#print(query)

		await gemini.chat(
			query,
			system_instruction,
			null,
			mcp_servers,
			null,
			chat_window.output_message,
#			self
			)
		
		chat_window.insert_message("\nYou: ")
		
		processing = false

const LOCAL_TOOLS = [
	SURROUNDINGS_TOOL,
	QUIT_TOOL,
	USER_FEEDBACK_TOOL
]

func list_tools():
	var tools = LOCAL_TOOLS.duplicate(true)
	for tool in tools:
		tool["name"] = "{server_name}_{tool_name}".format({"server_name": self.name, "tool_name": tool["name"]}) 
	return tools
