extends Node

# Gemini 2.5 Flash Model endpoint
#const MODEL = "gemini-2.5-flash"
const MODEL = "gemini-2.0-flash"

var GEMINI_API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent".format({"model": MODEL})

# Gemini API Key
var GEMINI_API_KEY_FILE_PATH = "res://gemini_api_key_env.txt"
var GEMINI_API_KEY = ""

var HTTP_REQUEST

# Get an environment variable in the file
func _get_environment_variable(filePath):
	var file = FileAccess.open(filePath, FileAccess.READ)
	var content = file.get_as_text()
	content = content.strip_edges()
	return content

func _init(http_request):

	GEMINI_API_KEY = _get_environment_variable(GEMINI_API_KEY_FILE_PATH)
	HTTP_REQUEST = http_request
	
func chat(query, system_instruction, mcp_server=null, base64_image=null):
	
	const headers = [
		"Content-Type: application/json",
		"Accept-Encoding: identity"
	]
	
	var system_instruction_ = {
		"parts": [
			{"text": system_instruction}
		]
	}
		
	var content = {
			"role": "user",
			"parts": [
	  			{
					"text": query,
	  			},
			],
  		}
		
	if base64_image:
		content["parts"].append({
			"inline_data": {
				"mime_type":"image/jpeg",
				"data": base64_image
			}
		})
	
	var contents = [content]

	var payload = {
		"system_instruction": system_instruction_,
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
		# print(payload)
		
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
