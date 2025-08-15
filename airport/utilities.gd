extends Node3D
			
func timer(tree, seconds):
	await tree.create_timer(seconds).timeout
	return "timer expired"

func quit(tree):
	tree.quit()
