extends Node

@export var chat_window: TextEdit
@export var visitors_menu: OptionButton

var children: Array[Node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	children = get_children()
	for c in children:
		visitors_menu.add_item(c.name)

	_on_option_button_item_selected(	visitors_menu.selected)
	
func _on_option_button_item_selected(index: int) -> void:
	for i in range(children.size()):
		children[i].enable(index == i)
	chat_window.grab_focus()
