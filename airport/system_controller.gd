extends Node3D

var gemini

const SYSTEM_INSTRUCTION  = "You are an AI agent good at controling facilities of the building"

func greeting(args):
	var message = "hello " + args["my_name"]
	print(message)
	return message
	
func gate_control(args):
	if args["control"] == "open":
		$MockGate/AnimationTree.open()
	elif args["control"] == "close":
		$MockGate/AnimationTree.close()
		
func timer(args):
	var seconds = args["seconds"]
	await get_tree().create_timer(seconds).timeout
	return "timer expired"

const GREETING_FUNCTION = {
	"name": "greeting",
	"description": """
	A function to print "Hello" with the name.
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

const GATE_CONTROL_FUNCTION = {
	"name": "gate_control",
	"description": """
	A function to open or close the gate.
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

const TIMER_FUNCTION = {
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

const FUNCTION_DECLARATIONS = [
	GREETING_FUNCTION,
	GATE_CONTROL_FUNCTION,
	TIMER_FUNCTION
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gemini = load("res://gemini.gd").new(
			$HTTPRequest,
			self,
			null,
			SYSTEM_INSTRUCTION
		)
		
	await gemini.chat("My name is araobp. Open the gate, wait for three seconds, then close it.", FUNCTION_DECLARATIONS)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
