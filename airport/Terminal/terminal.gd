extends Node3D

var areas = {}

@onready var AREAS = $Areas.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	areas.clear()
	for area in AREAS:
		var persons = area.get_overlapping_bodies()
		for person in persons:
			areas[person.name] = area.name
			
func get_area(name):
	if name in areas:
		return areas[name]
	else:
		return "unknown"
