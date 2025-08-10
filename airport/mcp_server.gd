extends Node

var utilities = load("res://utilities.gd").new()

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

const GATE_CONTROL_TOOL = {
	"name": "gate_control",
	"description": """
	A function to open or close the gate that can be called as "door" as well).
	""",
	"parameters": {
		"type": "object",
		"properties": {
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
	GATE_CONTROL_TOOL,
	TIMER_TOOL
]

func list_tools():
	return TOOLS
	
func greeting(args):
	return await utilities.greeting(args["my_name"])
	
func gate_control(args):
	var control = args["control"]
	var gate = get_parent().get_node("Gate")
	return await gate.gate_control(control)
		
func timer(args):
	return await utilities.timer(get_tree(), args["seconds"])
