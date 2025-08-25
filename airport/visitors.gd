extends Node

@export var chat_window: TextEdit
@export var visitors_menu: OptionButton

var children: Array[Node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	children = get_children()
	for c in children:
		visitors_menu.add_item(c.name)
	
	for i in range(children.size()):
		remove_child(children[i])
	_on_option_button_item_selected(0)
	
func _on_option_button_item_selected(index: int) -> void:
	var selected_visitor: Node

	var children_ = get_children()
	for i in range(children.size()):
		var c = children[i]
		if index == i:
			add_child(children[i])
			chat_window.grab_focus()
		elif c in children_:
			remove_child(children[i])
