extends Node
class_name Piece

@export var type:PieceType

@export var starting_state:Dictionary = {"position":null}

var states:Array[Dictionary]
var starting_turn := 0

var options:Dictionary
var o_states:Dictionary

func _ready():
	for k in type.state_form:
		if !starting_state.has(k):
			starting_state[k] = type.state_form[k]
		elif typeof(starting_state[k]) != typeof(type.state_form[k]):
			push_error("starting_state pair (", k, ": ", starting_state[k], ") does not match the type of the state_form pair (", k, ": ", type.state_form[k], "), aborting piece creation.")
			call_deferred("free")
			return
	
	states = [starting_state]

func generate_options(b:=Accessor.current_board, set:=true) -> Dictionary:
	var res := type.generate_options(self, b)
	if set: options = res
	return res

func to_global(position, b:=Accessor.current_board):
	return type.to_global(get_state(), b, position)

func get_state(turn := states.size() - 1) -> Dictionary:
	return states[turn]

func add_state():
	states.append(get_state().duplicate())

func get_position() -> Variant:
	return get_state()["position"]

func get_team():
	return get_state()["team"]

func _to_string():
	var result := "Piece:<" + str(type)
	if states.size() > 0:
		result += " at " + str(get_position()) + ", from " + str(get_team()) + ", " + str(get_state()) + ">"
	else:
		result += ", not ready>"
	return result
