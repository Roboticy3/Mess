extends Node
class_name Team

#if Pieces are placed as children of a Team, the Team's starting state will "cascade" onto the pieces, adjusting their direction
@export var starting_state:Dictionary = {"direction":Vector2i(0, 1)}

@export var node_paths:Array[NodePath] = [NodePath(".")]

#a team with higher priority will be placed closer to the beginning of the teams array in a Board
#the highest priority team on a Board goes first
@export var priority:int = 0

func _ready():
	starting_state["team"] = self
	for p in node_paths:
		var v = get_node(p)
		Accessor.get_children_recursive(v, cascade_state)

var cascade_state := func (v:Node):
	if v is Piece:
		v.state.merge(starting_state, true)

#i hate this
##why do you hate this?
func _to_string():
	return "Team<" + name + ">"
