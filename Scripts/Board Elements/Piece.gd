extends Node
class_name Piece

@export var type:PieceType

@export var starting_state:Dictionary = {"position":null}

var state:Dictionary
var starting_turn := 0

var options:Dictionary

func _ready():
	if !state.is_empty():
		return
	
	for k in type.state_form:
		if !starting_state.has(k):
			starting_state[k] = type.state_form[k]
		elif typeof(starting_state[k]) != typeof(type.state_form[k]):
			push_error("starting_state pair (", k, ": ", starting_state[k], ") does not match the type of the state_form pair (", k, ": ", type.state_form[k], "), aborting piece creation.")
			call_deferred("free")
			return
	
	state = starting_state

func generate_options(b:=Accessor.current_board, set:=true) -> Dictionary:
	var res := type.generate_options(self, b)
	if set: options = res
	return res

func to_global(position, b:=Accessor.current_board):
	return type.to_global(state, b, position)
func get_position() -> Variant:
	return state["position"]
	
func get_state() -> Dictionary:
	return state

func get_team():
	return state["team"]

func _to_string():
	var result := "Piece:<" + str(type)
	result += " at " + str(get_position()) + ", from " + str(get_team()) + ", " + str(state) + ">"
	return result
