extends CharacterBody3D

@onready var camera_3d = $Camera3D
@export var fov: float = 60  # in degrees
@export var fov_wide: float = 120  # in degrees

# Step stride
@export var stride: float = 0.6  # 60 cm

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const CAMERA_SENS = 0.003

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Step counter (accelerometer simulation)
var pos: Vector3 = Vector3.ZERO
var sigma_delta_d: float = 0.0
var steps: int = 0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Camera3D.fov = fov
	
	pos = position  # Initial position of the first person
	
func _input(event):
	if Globals.mode == Globals.MODE.CONTROL and event is InputEventMouseMotion:
		rotation.y -= event.relative.x * CAMERA_SENS
		rotation.x -= event.relative.y * CAMERA_SENS
		rotation.x = clamp(rotation.x, -0.5, 1.2)

func _physics_process(delta):
	
	# Delta distance
	var delta_d = (pos - position).length()
	sigma_delta_d += delta_d
	pos = position
	# Step
	if sigma_delta_d > stride:
		steps += 1
		sigma_delta_d = 0.0

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Globals.mode == Globals.MODE.CONTROL:
		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		move_and_slide()

func capture_image(camera_resolution_height, enable_wide_fov=false):

	if enable_wide_fov:
		camera_3d.fov = fov_wide
		await get_tree().process_frame
		
	var image = $"..".get_viewport().get_texture().get_image()
	
	# Resize the image to make the size smaller
	var h = image.get_height()
	var w = image.get_width()
	var camera_resolution_width = w * camera_resolution_height / h
	image.resize(camera_resolution_width, camera_resolution_height, Image.INTERPOLATE_BILINEAR)
	
	# Encode the image to Base64
	var b64image = Marshalls.raw_to_base64(image.save_jpg_to_buffer())
	
	if enable_wide_fov:
		camera_3d.fov = fov
	
	return b64image
