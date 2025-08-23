extends Node

enum MODE {CHAT, CONTROL}

var mode: MODE = MODE.CHAT

var gemini_api_key: String = ""
var gemini_model: String = ""
