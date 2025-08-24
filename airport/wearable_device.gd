extends Node3D

@export var fov: float = 60  # in degrees
@export var fov_wide: float = 120  # in degrees
# Step stride
@export var stride: float = 0.6  # 60 cm

@onready var camera_3d = $Camera3D

# Step counter (accelerometer simulation)
var pos: Vector3 = Vector3.ZERO
var sigma_delta_d: float = 0.0
var steps: int = 0

func _ready() -> void:
	self.fov = fov
	pos = position  # Initial position of the first person

func _physics_process(delta: float) -> void:
	# Delta distance
	var delta_d = (pos - position).length()
	sigma_delta_d += delta_d
	pos = position
	# Step
	if sigma_delta_d > stride:
		steps += 1
		sigma_delta_d = 0.0

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
