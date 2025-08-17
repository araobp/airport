extends Node3D
			
func timer(tree, seconds):
	await tree.create_timer(seconds).timeout
	return "timer expired"

func quit(tree):
	tree.quit()

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
