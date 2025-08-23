extends Node

var utilities = load("res://utilities.gd").new()
@onready var airport_services = $Airport

const GREETING_TOOL = {
	"name": "greeting",
	"description": """
	A function to output a welcome message with the Visitor ID.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string",
				"description": "Visitor ID"
			},
		},
		"required": ["visitor_id"],
	}
}

const DOOR_CONTROL_TOOL = {
	"name": "door_control",
	"description": "Manages the state of entrance doors. This tool can either open or close a pair of doors at a specified location. The location is identified by a zone ID. This function is only applicable to zones with an ID that matches the pattern '*-D-*-w' or '*-E-*-e'. Do not call this function if the zone ID is not provided or does not match one of these patterns.",
	"parameters": {
		"type": "object",
		"properties": {
			"zone_id": {
				"type": "string",
				"description": "The unique identifier for the zone where the doors are located. Must match the pattern '*-D-*-w' or '*-E-*-e'."
			},
			"control": {
				"type": "string",
				"enum": ["open", "close"],
				"description": "The desired action for the doors."
			}
		},
		"required": ["zone_id", "control"]
	}
}

const TIMER_TOOL = {
	"name": "timer",
	"description": """
	A tool to pause execution for a specified duration. Use this when the user asks you to wait or to set a timer. The timer can be set for a minimum of 1 second and a maximum of 60 seconds.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"seconds": {
				"type": "integer",
				"description": "The number of seconds to wait. Must be between 1 and 60, inclusive."
			},
		},
		"required": ["seconds"],
	}
}

const LOGGING_TOOL = {
	"name": "record_log",
	"description": "Records the location of an amenity identified from a visitor's wearable device. This function is automatically called when the AI successfully identifies a 'zone_id' and an 'amenities' name from an image.",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string",
				"description": "The unique ID of the visitor."
			},
			"zone_id": {
				"type": "string",
				"description": "The ID of the zone where the amenity is located, identified from the image."
			},
			"amenities": {
				"type": "string",
				"description": "The name of the amenity (e.g., 'restroom', 'food court') identified from the image."
			}
		},
		"required": ["visitor_id", "zone_id", "amenities"]
	}
}

const AMENITIES_TOOL = {
	"name": "list_amenities_nearby",
	"description": "Finds nearby amenities for a visitor within an airport. This function can locate specific amenities like restrooms, restaurants, or lounges, given the visitor's current location.",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string",
				"description": "The unique identifier for the visitor."
			},
			"zone_id": {
				"type": "string",
				"description": "The ID of the airport zone or area where the visitor is located, as determined by an image analysis system."
			},
			"amenity": {
				"type": "string",
				"description": "The specific amenity the visitor is searching for (e.g., 'restroom', 'cafe', 'lounge')."
			}
		},
		"required": ["visitor_id"]
	}
}

const SHOPS_TOOL = {
	"name": "get_product_info",
	"description": """
	Retrieves information about a specific product, such as its price, for a visitor at the airport. This tool requires the visitor's ID, their current zone ID, the type of amenity (e.g., 'electronics store', 'duty-free shop'), and a Base64-encoded image of the product. It then searches for and provides details like product name, price, availability, and store location.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
				"type": "string",
				"description": "The unique identifier for the visitor."
			},
			"zone_id": {
				"type": "string",
				"description": "The current zone ID of the visitor within the airport. This ID is determined by analyzing images of the visitor's surroundings to pinpoint their precise location."
			},
			"amenity": {
				"type": "string",
				"description": "The type of shop or amenity the visitor is interested in (e.g., 'restaurant', 'gift shop', 'duty-free')."
			},
			"capture_image_local": {
				"type": "string",
				"description": """
				A Base64-encoded string representing an image of the product, captured by the visitor's wearable device. This value should always be an empty string ("") as the function will populate it with locally cached image data when called.
			}	
		},
		"required": ["visitor_id", "zone_id", "amenity", "capture_image_local"],
	}
}

const TOOLS = [
	GREETING_TOOL,
	DOOR_CONTROL_TOOL,
	TIMER_TOOL,
	LOGGING_TOOL,
	AMENITIES_TOOL,
	SHOPS_TOOL
]

func list_tools():
	var tools = TOOLS.duplicate(true)
	for tool in tools:
		tool["name"] = "{server_name}_{tool_name}".format({"server_name": self.name, "tool_name": tool["name"]}) 
	return tools
	
func greeting(args):
	return await airport_services.greeting(args["visitor_id"])
	
func door_control(args):
	var zone_id = args["zone_id"]
	var control = args["control"]
	return await airport_services.door_control(zone_id, control)

func record_log(args):
	var visitor_id = args["visitor_id"]
	var zone_id = args["zone_id"]
	var amenities = args["amenities"]
	return await airport_services.record_log(visitor_id, zone_id, amenities)

const LAST_N = 128
func list_amenities_nearby(args):
	var visitor_id = args["visitor_id"]
	
	var zone_id = args["zone_id"] if "args_id" in args else "unknown"
	var amenity = args["amenity"] if "amenity" in args else "unknown"
	return await airport_services.list_amenities_nearby(visitor_id, zone_id, amenity)

func get_product_info(args):
	var visitor_id = args["visitor_id"]
	var zone_id = args["zone_id"]
	var amenity = args["amenity"]
	var base64_image = args["capture_image_local"]
	return await airport_services.get_product_info(visitor_id, zone_id, amenity, base64_image)
	
func timer(args):
	return await utilities.timer(get_tree(), args["seconds"])
