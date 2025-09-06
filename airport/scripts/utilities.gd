extends Node3D
			
func timer(tree, seconds):
	await tree.create_timer(seconds).timeout
	return "timer expired"

func quit(tree):
	tree.quit()

const JSON_SCHEMA_FOR_USER_FEEDBACK = {
	"type": "object",
	"properties": {
		"visitor_id": {
			"type": "string",
			"description": "Vistor ID"
		},
		"request": {
			"type": "string",
			"description": "Summary of the user's request from the chat history that the user feedback or emotional expression refers to."
		},
		"response": {
			"type": "string",
			"description": "Summary of the AI's response from the chat history that the user feedback or emotional expression refers to."
		},
		"feedback": {
			"type": "string",
			"description": "The user feedback or emotional state regarding the AI's response.",
			"enum": [
				"good",
				"bad"
			]
		},
		"points": {
			"type": "string",
			"description": "A summary of the specific points the user highlighted."
		},
		"ideal_processing_steps": {
			"type": "string",
			"description": "The ideal processing steps to maximize user satisfaction, based on the user's feedback or emotion."
		}
	},
	"required": [
		"visitor_id",
		"request",
		"response",
		"feedback",
		"points",
		"ideal_processing_steps"
	]
}


# Get an environment variable in the file
func get_environment_variable(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		content = content.strip_edges()
		return content
	else:
		push_error(file_path + " not found")

func get_last_n_lines(path: String, n: int):
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("Error: Could not open file at path '", path, "'")
		return null

	var lines = file.get_as_text().split("\n")
	file.close()
	
	var start_index = max(0, lines.size() - n)
	var last_n_lines = []
	for i in range(start_index, lines.size()):
		last_n_lines.append(lines[i])
		
	return last_n_lines
	

func get_all_children_recursive(node):
	var all_children = []
	
	# Add the immediate children of the current node
	for child in node.get_children():
		all_children.append(child)
		# Recursively call the function to get the children's children
		all_children = all_children + get_all_children_recursive(child)

	return all_children
	
func save_it_as_long_term_memory(path, it, header=null):
	var file = FileAccess.open(path, FileAccess.READ_WRITE)
	if file:
		if file.get_length() == 0 and header:
			file.store_line(header)
		file.seek_end()
		file.store_line(it)  # Append it
		file.close()
		return {"result": "logging completed"}
	else:
		push_error("Cannot open ", path)
		return {"result": "logging failed due to a system error"}		
