extends Node

var utilities = load("res://utilities.gd").new()
@onready var airport_services = $Airport

const GREETING_TOOL = {
	"name": "greeting",
	"description": """
	A function to print "Hello" with the name. Then return a message "Hello" to the name.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"my_name": {
				"type": "string",
				"description": "name"
			},
		},
		"required": ["my_name"],
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
		"required": ["control"]
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

const TOOLS = [
	GREETING_TOOL,
	DOOR_CONTROL_TOOL,
	TIMER_TOOL
]

func list_tools():
	var tools = TOOLS.duplicate(true)
	for tool in tools:
		tool["name"] = "{server_name}.{tool_name}".format({"server_name": self.name, "tool_name": tool["name"]}) 
	return tools
	
func greeting(args):
	return await utilities.greeting(args["my_name"])
	
func door_control(args):
	var zone_id = args["zone_id"]
	var control = args["control"]
	return await airport_services.door_control(zone_id, control)
		
func timer(args):
	return await utilities.timer(get_tree(), args["seconds"])
