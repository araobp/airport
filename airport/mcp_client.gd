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

	$ChatWindow.grab_focus()

var processing = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_text_indent"):
		$ChatWindow.visible = not $ChatWindow.visible
		if $ChatWindow.visible:
			$ChatWindow.grab_focus()

	if !processing and Input.is_key_pressed(KEY_ENTER) and $ChatWindow.text != "":
		processing = true
		var text = $ChatWindow.text
		var response_text = await gemini.chat(
			text,
			mcp_server
			)
		$ChatWindow.insert_text_at_caret("Robot: {response_text}\nYou: ".format({"response_text": response_text}), -1)
		$ChatWindow.scroll_vertical = 10000
		processing = false
