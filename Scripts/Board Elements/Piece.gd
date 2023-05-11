extends Node
class_name Piece

@export var type:PieceType

@export var starting_state:Dictionary = {"position":null,"team":null}

var states:Array[Dictionary]
var starting_turn := 0

var options:Dictionary

func _ready():
	for k in type.state_form:
		if !starting_state.has(k):
			starting_state[k] = type.state_form[k]
		elif typeof(starting_state[k]) != typeof(type.state_form[k]):
			push_error("starting_state pair (", k, ": ", starting_state[k], ") does not match the type of the state_form pair (", k, ": ", type.state_form[k], "), aborting piece creation.")
			free()
			return
	
	states = [starting_state]

func generate_options(b:Board) -> void:
	options = type.generate_options(self, b)

func to_global(position):
	return type.to_global(get_state(), position)

func get_state(turn := states.size() - 1) -> Dictionary:
	return states[turn]

func get_position() -> Variant:
	return get_state()["position"]

func get_team():
	return get_state()["team"]