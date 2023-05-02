extends Node
class_name Team

@export var starting_state:Dictionary = {"direction":Vector2i(0, 1)}

@export_node_path var starting_pieces_path := NodePath(".")

func _ready():
	starting_state["team"] = self
	StaticFuncs.get_children_recursive(get_node(starting_pieces_path), cascade_state)

var cascade_state := func (v:Node):
	if v is Piece:
		v.starting_state.merge(starting_state, true)

#i hate this
func _to_string():
	return "Team<" + name + ">"
