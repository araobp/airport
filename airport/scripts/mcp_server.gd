extends Node

var utilities = load("res://scripts/utilities.gd").new()
@onready var airport_services = $Airport

@export var network_graph_output_path = "../data/network_graph.js"

@onready var gemini: Gemini = load("res://scripts/gemini.gd").new(
		$HTTPRequest,
		Globals
	)

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
	"description": """
	This function is called to log the zone ID and amenities when they are recognized from images captured by a visitor's wearable device's camera.
	Please be sure to call this function every when the zone ID and amenities are recognized confidently.
	The zone ID must contain an -e or -w suffix. If it does not, this function should not be called.
	""",
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
				A Base64-encoded string representing an image of the product, captured by the visitor's wearable device. This value should always be an empty string ("") as the function will populate it with a local image capture function when called.
				"""
			}	
		},
		"required": ["visitor_id", "zone_id", "amenity", "capture_image_local"],
	}
}

const MANAGEMENT_TOOL = {
	"name": "initiate_management",
	"description": """
	This function initiate ABC airport management processes. An authorized person can call this function.
	""",
	"parameters": {
		"type": "object",
		"properties": {
			"visitor_id": {
			"type": "string",
			"description": "The unique identifier for the visitor. Here the visitor means an authorized person for managing this airport."
			}
		},
		"required": ["visitor_id"]
	}
}

var USER_FEEDBACK_TOOL = {
	"name": "register_user_feedback",
	"description": """
	This function saves user feedback, previously analyzed by another program, to a database.
	""",
	"parameters": utilities.JSON_SCHEMA_FOR_USER_FEEDBACK
}

func register_user_feedback(args):
	utilities.save_it_as_long_term_memory(USER_FEEDBACK_PATH, JSON.stringify(args))
	
func retrieve_guidelines():
	var file = FileAccess.open(GUIDELINES_PATH, FileAccess.READ)
	if file:
		var guidelines = file.get_as_text()
		return {"guidelines": guidelines}
	else:
		return {"guidelines": null}

var TOOLS = [
	GREETING_TOOL,
	DOOR_CONTROL_TOOL,
	TIMER_TOOL,
	LOGGING_TOOL,
	AMENITIES_TOOL,
	SHOPS_TOOL,
	MANAGEMENT_TOOL,
	USER_FEEDBACK_TOOL
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
	

const LOCATIONS_PATH = "res://mcp_server_memory/locations.txt"

func record_log(args):
	var visitor_id = args["visitor_id"]
	var zone_id = args["zone_id"]
	var amenities = args["amenities"]
	
	var current_time_string = Time.get_datetime_string_from_system()
	#var record = {"time": current_time_string, "visitor_id": visitor_id, "zone_id": zone_id, "amenities": amenities}
	#user_data.append(record)
	#print(record)
	
	var record = "{time},{visitor_id},{zone_id},{amenities}".format({
		"time": current_time_string,
		"visitor_id": visitor_id,
		"zone_id": zone_id,
		"amenities": amenities
		}
	)
	
	utilities.save_it_as_long_term_memory(LOCATIONS_PATH, record, "time,visitor_id,zone_id,amenities")

const LAST_N_LOCATIONS = 128

func list_amenities_nearby(args):
	var visitor_id = args["visitor_id"]
	var zone_id = args["zone_id"] if "args_id" in args else "unknown"
	var amenity = args["amenity"] if "amenity" in args else "unknown"

	var locations_data = utilities.get_last_n_lines(LOCATIONS_PATH, LAST_N_LOCATIONS)
	if locations_data:
		var query = """
		An airport visitor (Visitor ID: {visitor_id}) is currently near Zone {zone_id}.
		Please guide the visitor to the {amenity} category, referring to the log data.
		- If both the zone and category are unknown, please list all amenities.
		- If the zone is unknown, please list all amenities within that category.
		- If the category is unknown, please list all amenities near that zone.
		""".format({"visitor_id": visitor_id, "zone_id": zone_id, "amenity": amenity})
				
		query = query.format({"visitor_id": visitor_id, "zone_id": zone_id, "amenity": amenity})
		query += """
		## Log data
		
		{locations_data}
		""".format({"locations_data": locations_data})
		
		const system_instruction = """
		You are an AI assistant serving as an information desk at an airport.
		Please DO NOT include visitor_id in your response, since visitor_id is private.
		"""
		
		var result = await gemini.chat(
			query,
			system_instruction
		)
			
		print("AMENITIES: ", result)
		return {"result": result}

	else:
		push_error("Cannot open " + LOCATIONS_PATH)
		return {"result": "Could not get any info due to a system error"}


func get_product_info(args):
	var visitor_id = args["visitor_id"]
	var zone_id = args["zone_id"]
	var amenity = args["amenity"]
	var base64_image = args["capture_image_local"]
	return await airport_services.get_product_info(visitor_id, zone_id, amenity, base64_image)

const LAST_N_USER_FEEDBACK = 128

const USER_FEEDBACK_PATH = "res://mcp_server_memory/user_feedback.txt"
const GUIDELINES_PATH = "res://mcp_server_memory/guidelines.txt"

func initiate_management(args):
	
	if args["visitor_id"] != Globals.ADMIN:
		return {
			"result": "Error: unauthorized personel accessed this service."
		}

	### Manage locations ##########################################################################
	
	var locations_data = utilities.get_last_n_lines(LOCATIONS_PATH, LAST_N_LOCATIONS)

	const system_instruction_locations = """
	You are a data processing assistant. Your task is to convert the provided log data into a JSON object suitable for vis.js network visualization.
	The output must ONLY be the JSON object, with no additional text or explanation.
	The JSON object should have two top-level keys: "nodes" and "edges".
	Each entry in the log data represents a record of a visitor's interaction with an amenity at a specific zone.
	- Create nodes for each unique 'visitor_id', 'zone_id', and 'amenities'.
	- 'visitor_id' nodes should represent the visitor.
	- 'zone_id' nodes should represent the location.
	- 'amenities' nodes should represent the type of amenity. For these nodes, summarize the name to a single, concise term (e.g., "Kiosk in ..." should become "Kiosk").
	- Create edges to show the flow: 'visitor_id' -> 'zone_id' -> 'amenities'.
	- Do not include the 'time' in the output.
	"""

	var query_locations = """
	Generate a network graph for vis.js from the following log data.
	The log data is a list of JSON objects, each with 'time', 'visitor_id', 'zone_id', and 'amenities' fields.

	## Log data

	{locations_data}
	""".format({"locations_data": locations_data})

	# json_schema for vis.js generated by gemini-2.5-flash
	const json_schema = {
		"type": "object",
		"properties": {
			"nodes": {
				"type": "array",
				"items": {
					"type": "object",
					"properties": {
						"id": {
							"type": "string",
							"description": "Unique identifier for the node."
						},
						"label": {
							"type": "string",
							"description": "Text to be displayed on the node."
						},
						"title": {
							"type": "string",
							"description": "Hover text for the node."
						},
						"group": {
							"type": "string",
							"description": "Identifier for node grouping (optional)."
						}
					},
					"required": [
						"id",
						"label"
					]
				}
			},
			"edges": {
				"type": "array",
				"items": {
					"type": "object",
					"properties": {
						"from": {
							"type": "string",
							"description": "The 'id' of the node where the edge starts."
						},
						"to": {
							"type": "string",
							"description": "The 'id' of the node where the edge ends."
						},
						"label": {
							"type": "string",
							"description": "Text to be displayed on the edge."
						},
						"arrows": {
							"type": "string",
							"description": "Direction of the arrow(s), e.g., 'to', 'from', 'to;from'."
						}
					},
					"required": [
						"from",
						"to"
					]
				}
			}
		},
		"required": [
			"nodes",
			"edges"
		]
	}

	# Generate network graph for vis.js
	var network_graph_for_vis = await gemini.chat(
		query_locations,
		system_instruction_locations,
		null,
		null,
		json_schema
	)
	
	network_graph_for_vis = "export const data = {network_graph_for_vis};".format({"network_graph_for_vis": network_graph_for_vis})

	var file_graph = FileAccess.open(network_graph_output_path, FileAccess.WRITE)
	if file_graph != null:
		file_graph.store_string(network_graph_for_vis)
		file_graph.close()

	### Manage user feedback ######################################################################
	var user_feedback_data = utilities.get_last_n_lines(USER_FEEDBACK_PATH, LAST_N_USER_FEEDBACK)

	const system_instruction_feedback = """
	Assume the role of a Quality Assurance expert.
	Your objective is to analyze the attached user feedback from visitors at ABC Airport.
	"""
	
	var query_feedback = """
	Based on the analysis attached, distill the key insights into actionable guidelines for our AgenticAI.
	These guidelines should instruct the AI on how to more effectively handle complex visitor requests.
	Please format your final output in markdown.		
	
	## Analysis
		
	{analysis}
	""".format({"analysis": user_feedback_data})

	# Generate network graph for vis.js
	var guidelines = await gemini.chat(
		query_feedback,
		system_instruction_feedback,
	)
	
	var file_guidelines = FileAccess.open(GUIDELINES_PATH, FileAccess.WRITE)
	if file_guidelines != null:
		file_guidelines.store_string(guidelines)
		file_guidelines.close()

	print("MANAGEMENT: ", network_graph_for_vis)
	return {"result": "management processes completed"}


func timer(args):
	await utilities.timer(get_tree(), args["seconds"])
	return {"result": "timer expired"}
	
