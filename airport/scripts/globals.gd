extends Node

var utilities = load("res://scripts/utilities.gd").new()

enum MODE {CHAT, CONTROL}
var mode: MODE = MODE.CHAT

@export_enum("gemini-2.0-flash", "gemini-2.5-flash", "gemma-3-27b-it") var gemini_model: String = "gemini-2.5-flash"
const GEMINI_API_KEY_FILE_PATH = "res://gemini_api_key_env.txt"
var gemini_api_key = utilities.get_environment_variable(GEMINI_API_KEY_FILE_PATH)

const ADMIN = "Admin"
