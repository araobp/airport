extends Node3D

func greeting(my_name):
	var message = "Hello " + my_name
	print(message)
	return message
			
func timer(tree, seconds):
	await tree.create_timer(seconds).timeout
	return "timer expired"
