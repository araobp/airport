extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_walking(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func is_walking(walking):
	if walking:
		$AnimationPlayer.play("Woman2Walking")
	else:
		$AnimationPlayer.stop()
