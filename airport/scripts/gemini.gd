class_name Gemini

extends Node

# Gemini API
var _api

# Reference to HTTPRequest node
var _http_request

# Chat history
var chat_history = []
var _enable_history
const MAX_CHAT_HISTORY_LENGTH = 32

# Default callback function
func _output_text(text):
	print("default output: " + text)

# Constructor	
func _init(http_request, gemini_props, enable_history=false):
	var api = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent".format({"model": gemini_props.gemini_model})
	_api = api + "?key=" + gemini_props.gemini_api_key
	_http_request = http_request
	_enable_history = enable_history
	# print(model)

# Chat with Gemini
func chat(query, system_instruction, base64_images=null, mcp_servers=null, json_schema=null, callback:Callable=_output_text, locals=null):
	
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
	
	if base64_images:
		for image in base64_images:
			content["parts"].append({
				"inline_data": {
					"mime_type":"image/jpeg",
					"data": image
				}
			})

	# payload to be sent to Gemini Chat API
	if len(chat_history) > MAX_CHAT_HISTORY_LENGTH:
		# Calculate the starting index
		var start_index = max(0, chat_history.size() - MAX_CHAT_HISTORY_LENGTH)
		# Use slice() to get the last n elements
		chat_history = chat_history.slice(start_index)

	var contents = chat_history + [content]
	var payload = {
		"system_instruction": system_instruction_,
		"contents": contents
	}

	# Note: Base64 image data is not appended to the chat history
	if _enable_history:
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

	# print(payload)

	while true:
		# Call Gemini Chat API
		var err = _http_request.request(
			_api,
			headers,
			HTTPClient.METHOD_POST,
			JSON.stringify(payload)
		)
		
		if err != OK:
			return error_string(err)

		var res = await _http_request.request_completed
		var body = res[3]
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		var candidate
		var parts
		if json and "candidates" in json and len(json["candidates"]) > 0:
			candidate = json["candidates"][0]
			parts = candidate["content"]["parts"]
		else:
			print(json)
			push_error(json)
			chat_history.clear()
			return

		var functionCalled = false
		
		var content_in_res = {
			"role": "model",
			"parts": parts
		}
		
		if _enable_history:
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
				var function = function_call["name"].split("_")  # <mcp_server_name>.<function_name>
				
				var mcp_server_name = function[0]
				function.remove_at(0)
				var func_name = ("_").join(function)
				var args = function_call["args"]
				print(func_name, "(", args, ")")	
				
				# Outputs from local functions
				for k in args:
					if k.ends_with("_local"):
						args[k] = await Callable(locals, k).call()
				
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
				
				if _enable_history:
					chat_history.append(content_func_res)
				contents.append(content_func_res)
				
				functionCalled = true
					
		if not functionCalled:
			break
	
	if callback == _output_text:	
		return response_text
	else:  # response_text already returned via callback
		return ""
