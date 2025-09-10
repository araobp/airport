class_name Gemini

extends Node

# Gemini API
var _api

# Reference to HTTPRequest node
var _http_request

# Chat history per instance of this class
var _enable_history: bool = false
var chat_history = []

const MAX_CHAT_HISTORY_LENGTH = 16

const INCLUDE_THOUGHTS = true

# Chat history log flie path (for debug purposes)
const CHAT_HISTORY_LOG_PATH = "res://log/chat_history.txt"

# Default callback function
func _output_text(text):
	print("DEFAULT OUTPUT: ", text, "\n\n")

# Constructor	
func _init(http_request, gemini_props, enable_history=false):
	var api = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent".format({"model": gemini_props.gemini_model})
	_api = api + "?key=" + gemini_props.gemini_api_key
	_http_request = http_request
	_enable_history = enable_history
		
# Chat with Gemini
#func chat(query, system_instruction, base64_images=null, mcp_servers=null, json_schema=null, callback:Callable=_output_text, locals=null):
func chat(query, system_instruction, base64_images=null, mcp_servers=null, json_schema=null, callback:Callable=_output_text):
	
	var thought_signature = null

	const headers = [
		"Content-Type: application/json",
		"Accept-Encoding: identity"
	]
	
	var system_instruction_ = {
		"parts": [
			{"text": system_instruction}
		]
	}
	
	# Sometimes, Gemini stops chat by just sending a thought and not a full response. 
	# This is a workaround.
	query += "\n\nAfter you have thought through the problem, please provide a concise final answer only when you have not provided it yet."
	
	var content = {
			"role": "user",
			"parts": [
				{
					"text": query,
				},
			],
		}
	
	if base64_images:
		for image in base64_images:
			content["parts"].append({
				"inline_data": {
					"mime_type":"image/jpeg",
					"data": image
				}
			})

	var contents
	if _enable_history:
		chat_history.append(content)
		if len(chat_history) > MAX_CHAT_HISTORY_LENGTH:
			# Calculate the starting index
			var start_index = max(0, chat_history.size() - MAX_CHAT_HISTORY_LENGTH)
			# Use slice() to get the last n elements
			chat_history = chat_history.slice(start_index)
		contents = chat_history + [content]
	else:
		contents = [content]
	
	# Payload
	var payload = {
		"system_instruction": system_instruction_,
		"contents": contents,
		"generation_config": {
			"thinking_config": {
				"thinking_budget": -1,  # Turn on dynamic thinking
				"include_thoughts": INCLUDE_THOUGHTS
			}
		}
	}
	
	# Request JSON Output
	if json_schema:
		var generationConfig = payload["generation_config"]
		generationConfig["response_mime_type"] = "application/json"
		generationConfig["response_schema"] = json_schema
	
	# Function calling
	if mcp_servers:
		payload["tools"] = mcp_servers["tools"]

	var response_text = null

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
		# print(body.get_string_from_utf8())
		var json = JSON.parse_string(body.get_string_from_utf8())
		print(json)
		var candidate
		var parts
		if json and "candidates" in json and len(json["candidates"]) > 0:
			candidate = json["candidates"][0]
			#print(candidate)
			if "content" in candidate:
				parts = candidate["content"]["parts"]
			else:
				push_error("No content in Gemini response: ", candidate)
		else:
			print(json)
			push_error(json)
			chat_history.clear()
			return

		var finishChatSession = true
		
		var content_in_res = {
			"role": "model",
			"parts": parts
		}
		
		if _enable_history:
			chat_history.append(content_in_res)
		contents.append(content_in_res)
		
		for part in parts:
			if "text" in part:
				response_text = part["text"]
				# Output text via callback
				if not response_text.begins_with("**"):  # not "thought" from LLM
					callback.call(response_text)
				
			if "thoughtSignature" in part:
				thought_signature = part["thoughtSignature"]
				# print("thought_signature: ", thought_signature)
				
			# Function calling case
			if "functionCall" in part:
				var function_call = part["functionCall"]
				var function = function_call["name"].split("_")  # <mcp_server_name>.<function_name>
				
				var mcp_server_name = function[0]
				function.remove_at(0)
				var func_name = ("_").join(function)
				var args = function_call["args"]
				print(func_name, "(", args, ")", "\n\n")	
				
				# Outputs from local functions
				#for k in args:
				#	if k.ends_with("_local"):
				#		args[k] = await Callable(locals, k).call()
				
				# Call function via Callable
				var ref = mcp_servers["ref"][mcp_server_name]
				var callable = Callable(ref, func_name)
				var result = await callable.call(args)
				var content_from_func = null
				
				if "as_content" in args and args["as_content"] == true:
					content_from_func = result["content"]	
					result = result["result"]

				var content_func_res = [
					{
						"role": "function",
						"parts": {
							"functionResponse": {
								"name": function_call["name"],
								"response": result
							}
						}
					}
				]
				
				if content_from_func:
					content_func_res.append(content_from_func)
				
				if _enable_history:
					chat_history = chat_history + content_func_res
				
				contents.append_array(content_func_res)
				
				finishChatSession = false
					
		if finishChatSession:
			break

	var file = FileAccess.open(CHAT_HISTORY_LOG_PATH, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(contents))
		file.close()
	else:
		push_error("Cannot open ", CHAT_HISTORY_LOG_PATH)

	if callback == _output_text:	
		return response_text
	else:  # response_text already returned via callback
		return ""
