extends Node

var utilities = load("res://utilities.gd").new()
@onready var airport_services = $Airport

const GREETING_TOOL = {
	"name": "greeting",
	"description": """
	A function to output a welcome message with the Visitor ID.
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

const DOOR_CONTROL_TOOL = {
	"name": "door_control",
	"description": """
	A function to open or close the door.
	If the zone ID is unknown, this function is not called.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"zone_id": {
				"type": "string",
				"description": "Zone ID where the door is located."
			},
			"control": {
				"type": "string",
				"enum": ["open", "close"]
			}
		},
		"required": ["zone_id", "control"]
	}
}

const TIMER_TOOL = {
	"name": "timer",
	"description": """
	A function to wait for a while.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"seconds": {
				"type": "integer",
				"description": "A timeout value from 1 to 60 in seconds for the timer to wait for a while."
			},
		},
		"required": ["seconds"],
	}
}

const USER_DATA_RECORDER_TOOL = {
	"name": "record_user_data",
	"description": """
	This function is called after an image capture from a visitor's wearable device.
	If the generative AI analysis successfully identifies both a zone ID and an amenity, the resulting text data is used to record the amenity's location.
	This function is automatically called based on the AI agent's decision.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string",
				"description": "Visitor ID"
			},
			"zone_id": {
				"type": "string",
				"description": "Zone ID identified by generative AI from images of a visitor's surroundings."
			},
			"amenities": {
				"type": "string",
				"description": "Amenities identified by generative AI from images of a visitor's surroundings."
			}
		},
		"required": ["visitor_id", "zone_id", "amenities"],
	}
}

const TOOLS = [
	GREETING_TOOL,
	DOOR_CONTROL_TOOL,
	TIMER_TOOL,
	USER_DATA_RECORDER_TOOL
]

func list_tools():
	var tools = TOOLS.duplicate(true)
	for tool in tools:
		tool["name"] = "{server_name}.{tool_name}".format({"server_name": self.name, "tool_name": tool["name"]}) 
	return tools
	
func greeting(args):
	return await airport_services.greeting(args["visitor_id"])
	
func door_control(args):
	var zone_id = args["zone_id"]
	var control = args["control"]
	return await airport_services.door_control(zone_id, control)

func record_user_data(args):
	var visitor_id = args["visitor_id"]
	var zone_id = args["zone_id"]
	var amenities = args["amenities"]
	return await airport_services.record_user_data(visitor_id, zone_id, amenities)
	
func timer(args):
	return await utilities.timer(get_tree(), args["seconds"])
