extends Node

var mcp_server
var gemini

@export var enable_gemini = false

const SYSTEM_INSTRUCTION  = "You are an AI agent good at controling facilities of the building"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mcp_server = get_parent().get_node("McpServer")
	gemini = load("res://gemini.gd").new(
			$HTTPRequest,
			SYSTEM_INSTRUCTION
		)

	var tools = mcp_server.list_tools()
	
	if enable_gemini:
		# await gemini.chat("My name is araobp. Wait for one seconds, open the gate, wait for three seconds, then close it.", mcp_server)
		await gemini.chat("My name is araobp. Wait for two seconds, open the gate.", mcp_server)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
