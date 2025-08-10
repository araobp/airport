extends Node

# Gemini 2.5 Flash Model endpoint
#const MODEL = "gemini-2.5-flash"
const MODEL = "gemini-2.0-flash"

var GEMINI_API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent".format({"model": MODEL})

# Gemini API Key
var GEMINI_API_KEY_FILE_PATH = "res://gemini_api_key_env.txt"
var GEMINI_API_KEY = ""

var SYSTEM_INSTRUCTION
var HTTP_REQUEST

# Get an environment variable in the file
func _get_environment_variable(filePath):
	var file = FileAccess.open(filePath, FileAccess.READ)
	var content = file.get_as_text()
	content = content.strip_edges()
	return content

func _init(http_request, system_instruction="") -> void:

	GEMINI_API_KEY = _get_environment_variable(GEMINI_API_KEY_FILE_PATH)
	HTTP_REQUEST = http_request
	SYSTEM_INSTRUCTION = system_instruction
	
func chat(query, mcp_server=null):
	
	const headers = [
		"Content-Type: application/json",
		"Accept-Encoding: identity"
	]

	var contents = [
  		{
			"role": "user",
			"parts": [
	  			{
					"text": query,
	  			},
			],
  		}
	]

	var payload = {
		"contents": contents
	}
	
	if mcp_server:
		var function_declarations = mcp_server.list_tools()
		
		payload["tools"] = [
			{
				"functionDeclarations": function_declarations
			}
		]
	
	var response_text = null

	while true:
		
		var err = HTTP_REQUEST.request(
			GEMINI_API + "?key=" + GEMINI_API_KEY,
			headers,
			HTTPClient.METHOD_POST,
			JSON.stringify(payload)
		)
		
		if err != OK:
			return

		var res = await HTTP_REQUEST.request_completed

		var body = res[3]
		
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		print(json)
		var candidate = json["candidates"][0]
		var parts = candidate["content"]["parts"]

		var functionCalled = false
				
		for part in parts:
			if "text" in part:
				response_text = part["text"]
				# print(response_text)
				
			if "functionCall" in part:
				var functionCall = part["functionCall"]
				var func_name = functionCall["name"]
				var args = functionCall["args"]
				print(func_name, args)	
				
				var callable = Callable(mcp_server, func_name)
				var result = await callable.call(args)
				
				var functionResponsePart = {
					"name": func_name,
					"response": {
						"result": result
					}
				}
				
				contents.append(
					{
						"role": "model",
						"parts": [
							{
								"functionCall": functionCall
							}
						]
					}
				)
				
				contents.append(
					{
						"role": "user",
						"parts": [
							{
								"functionResponse": functionResponsePart,
							}
						]
					}
				)
				
				functionCalled = true
					
		if not functionCalled:
			break
			
	return response_text
