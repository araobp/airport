extends Node

# Gemini 2.5 Flash Model endpoint
var MODEL
var GEMINI_CHAT_API

# Reference to HTTPRequest node
var HTTP_REQUEST

# Chat history
var chat_history = []
const MAX_CHAT_HISTORY_LENGTH = 32
var ENABLE_HISTORY

# Default callback function
func _output_text(text):
	print("default output: " + text)

# Constructor	
func _init(http_request, gemini_api_key, model="gemini-2.0-flash", enable_history=false):
	MODEL = model
	var api = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent".format({"model": MODEL})
	GEMINI_CHAT_API = api + "?key=" + gemini_api_key
	HTTP_REQUEST = http_request
	ENABLE_HISTORY = enable_history
	# print(model)

# Chat with Gemini
func chat(query, system_instruction, base64_image=null, mcp_servers=null, json_schema=null, callback:Callable=_output_text):
	
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
	var content_ = content.duplicate(true)
	
	if base64_image:
		content["parts"].append({
			"inline_data": {
				"mime_type":"image/jpeg",
				"data": base64_image
			}
		})
	
	# payload to be sent to Gemini Chat API
	if len(chat_history) > MAX_CHAT_HISTORY_LENGTH:
		chat_history = chat_history[-MAX_CHAT_HISTORY_LENGTH]
	var contents = chat_history + [content]
	var payload = {
		"system_instruction": system_instruction_,
		"contents": contents
	}

	# Note: Base64 image data is not appended to the chat history
	if ENABLE_HISTORY:
		chat_history.append(content_)
	# print("chat history: " + str(chat_history))
	
	# Request JSON Output
	if json_schema:
		payload["generation_config"] = {
		"response_mime_type": "application/json",
		"response_schema": json_schema
		}
	
	# Function calling
	if mcp_servers:		
		payload["tools"] = mcp_servers["tools"]

	var response_text = null

	while true:
		# print(payload)
		# Call Gemini Chat API
		var err = HTTP_REQUEST.request(
			GEMINI_CHAT_API,
			headers,
			HTTPClient.METHOD_POST,
			JSON.stringify(payload)
		)
		
		if err != OK:
			return

		var res = await HTTP_REQUEST.request_completed
		var body = res[3]		
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		var candidate
		var parts
		if "candidates" in json:
			candidate = json["candidates"][0]
			parts = candidate["content"]["parts"]
		else:
			# print(json)
			chat_history.clear()
			return

		var functionCalled = false
		
		var content_in_res = {
			"role": "model",
			"parts": parts
		}
		
		if ENABLE_HISTORY:
			chat_history.append(content_in_res)
		contents.append(content_in_res)
		#print(chat_history)
		
		for part in parts:
			if "text" in part:
				response_text = part["text"]
				# Output text via callback
				callback.call(response_text)
				# print(response_text)
								
			# Function calling case
			if "functionCall" in part:
				var function_call = part["functionCall"]
				var function = function_call["name"].split(".")  # <mcp_server_name>.<function_name>
				
				var mcp_server_name = function[0]
				var func_name = function[1]
				var args = function_call["args"]
				print(func_name, "(", args, ")")	
				
				# Call function via Callable
				var ref = mcp_servers["ref"][mcp_server_name]
				var callable = Callable(ref, func_name)
				var result = await callable.call(args)
				
				var function_response_part = {
					"name": function_call["name"],
					"response": {
						"result": result
					}
				}
				
				var content_func_res = {
					"role": "user",
					"parts": [
						{
							"functionResponse": function_response_part,
						}
					]
				}
				
				if ENABLE_HISTORY:
					chat_history.append(content_func_res)
				contents.append(content_func_res)
				
				functionCalled = true
					
		if not functionCalled:
			break
	
	if callback == _output_text:	
		return response_text
	else:  # response_text already returned via callback
		return
