extends CharacterBody3D

@export var markers: Node3D
var marker_nodes
var idx = 0
var go = true

const SPEED = 1
const JUMP_VELOCITY = 4.5
const MIN_DISTANCE = 1.0
const ROTATION_SPEED = 2.0

func _ready() -> void:
	marker_nodes = markers.get_children()

func _forward():
	var f = marker_nodes[idx].position - position
	if f.length() < MIN_DISTANCE:
		if go:
			if idx < marker_nodes.size() - 1:
				idx += 1
			else:
				go = false
		else:
			if idx > 0:
				idx -= 1
			else:
				go = true
			
	return f.normalized()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var f = _forward() * SPEED
	if f:
		velocity.x = move_toward(velocity.x, f.x, delta*SPEED*0.3)
		velocity.z = move_toward(velocity.z, f.z, delta*SPEED*0.3)
		rotation.y = move_toward(rotation.y,  f.angle_to(Vector3.FORWARD), delta*SPEED*0.3)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	### Smooth rotaion on y axis ###
	# Create a target basis and convert it to a quaternion
	var target_basis = Basis.looking_at(f, Vector3.UP)
	var target_quat = target_basis.get_rotation_quaternion()
	# Get the character's current rotation as a quaternion
	var current_quat = transform.basis.get_rotation_quaternion()
	# Spherical linear interpolate from the current rotation to the target
	var interpolated_quat = current_quat.slerp(target_quat, delta * ROTATION_SPEED)
	# Apply the new rotation back to the character's transform
	transform.basis = Basis(interpolated_quat)

	move_and_slide()
