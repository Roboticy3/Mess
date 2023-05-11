extends Node
class_name Team

@export var starting_state:Dictionary = {"direction":Vector2i(0, 1)}

@export var node_paths:Array[NodePath] = [NodePath(".")]

@export var priority:int = 0

func _ready():
	starting_state["team"] = self
	for v in node_paths:
		Accessor.get_children_recursive(get_node(v), cascade_state)

var cascade_state := func (v:Node):
	if v is Piece:
		v.starting_state.merge(starting_state, true)

#i hate this
func _to_string():
	return "Team<" + name + ">"
