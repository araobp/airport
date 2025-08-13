extends Node

var utilities = load("res://utilities.gd").new()

@onready var terminal = $Airport/Terminal
var doors = {}

func _ready():
	var door_objects = $Airport/Doors.get_children()
	for obj in door_objects:
		# print(obj)
		doors[obj.name] = obj

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
	If the area name is unknown, this function is not called.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"area": {
				"type": "string",
				"description": "Area name where the door is located."
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

const AREA_TOOL = {
	"name": "get_area",
	"description": """
	A function to get an area name where the person is."
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"name": {
				"type": "string",
				"description": "Name of the person"
			},
		},
		"required": ["name"],
	}
}

const QUIT_TOOL = {
	"name": "quit",
	"description": """
	A function to quit this journey.
	Note: before calling this function, output some goodbye message in text, wait for three seconds then call this function to quit this journey."
	"""
}

const TOOLS = [
	GREETING_TOOL,
	DOOR_CONTROL_TOOL,
	TIMER_TOOL,
	AREA_TOOL,
	QUIT_TOOL
]

func list_tools():
	return TOOLS
	
func greeting(args):
	return await utilities.greeting(args["my_name"])
	
func door_control(args):
	var area = args["area"]
	var control = args["control"]
	
	var door = doors[area]
	return await door.door_control(control)
		
func timer(args):
	return await utilities.timer(get_tree(), args["seconds"])

func get_area(args):
	var name = args["name"]
	return await terminal.get_area(name)
	
func quit(args):
	return await utilities.quit(get_tree())
