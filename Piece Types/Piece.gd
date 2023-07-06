extends Node
class_name Piece

@export var type:PieceType

@export var starting_state:Dictionary = {"position":null}

var state:Dictionary

var options:Dictionary

var last

func _ready():
	if !state.is_empty():
		return
	
	for k in type.state_form:
		var v = starting_state.get(k)
		var f = type.state_form[k]
		
		if v is NodePath:
			v = get_node_or_null(v)
		
		var custom_type = f is Accessor.types.TYPE
		
		if v == null:
			starting_state[k] = f
		elif custom_type && Accessor.types.of(v) != f:
			push_error("starting_state pair (", k, ": path to ", v, ") does not match the custom type of the state_form pair (", k, ": ", Accessor.types.get_name(f), "), aborting piece creation.")
			call_deferred("free")
			return
		elif !custom_type && (typeof(v) != typeof(type.state_form[k])):
			push_error("starting_state pair (", k, ": ", v, ") does not match the type of the state_form pair (", k, ": ", f, "), aborting piece creation.")
			call_deferred("free")
			return
	
	state = starting_state

func generate_options(b:=Accessor.current_board, apply:=true) -> Dictionary:
	var res := {}
	if get_team() == b.get_team(): res = type.generate_options(self, b)
	if apply: options = res
	return res

func to_global(position, b:=Accessor.current_board):
	return type.to_global(state, b, position)
func get_position() -> Variant:
	return state["position"]
	
func get_state() -> Dictionary:
	return state

func get_team():
	return state.get("team")

func _to_string():
	var result := "Piece:<" + str(type)
	result += " at " + str(get_position()) + ", " + str(state) + ">"
	return result
