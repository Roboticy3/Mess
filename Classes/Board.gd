class_name Board
extends Node

#Board that manages the game
#Board is described by two states, the current_state and the states
#current_state shows everything that is currently on the board
#states describes the changes created by each turn
#pieces stored in states are unique, duplicated from the same piece on the last turn, 
#	turn is synonimous with the length of the states array
#pieces in current_state are references to pieces in states, and does not store duplications

@export var position_type:Variant.Type = TYPE_VECTOR2I

var shape:Array
var teams:Array[Team]

@export var node_paths:Array[NodePath]

var piece_types:Array[PieceType]

var starting_state := {}

#the board stores its state at the beginning of each turn
#each state is a dictionary including pieces and variables that can change during a game
var states:Array[Dictionary] = [starting_state.duplicate()]
var current_state := starting_state

#runs when the board first loads
#the board may load before its pieces, so use call_deferred to call functions on pieces from here
func _ready():
	
	match position_type:
		TYPE_VECTOR2I:
			var b2i:Array[Bound2i]
			shape = b2i
		TYPE_VECTOR2:
			var b2d:Array[Bound2d]
			shape = b2d
	
	for v in node_paths:
		StaticFuncs.get_children_recursive(get_node(v), add_node)
	
	#template for a turn
	#new state to modify
	add_state()
	#generate options to use for the turn
	generate_options()
	#select a piece to move
	var square := Vector2i(0, 1)
	var p:Piece = get_piece(square)
	#make a turn on the new state by calling an option on that piece
	call_option(p, Vector2i(1, 2))

	#display first turn
	print(StaticFuncs.shaped_2i_state_to_string(shape, get_state(0)))
	#display changes for second turn
	print(StaticFuncs.shaped_2i_state_to_string(shape, get_state()))
	#display whole second turn
	print(self)
	
	
#everybody shut up new class just dropped
var add_node:Callable = func (v:Node) -> bool:
	if v is Piece: 
		v = v as Piece
		
		add_piece(v)
		return true
	elif v is Bound:
		v = v as Bound
		
		shape.append(v)
		return true
	elif v is Team:
		v = v as Team
		
		teams.append(v)
	
	return false

#editing pieces
#editing pieces will effect the last state in states as well as the current_state
#the assumption is that the last state is the changes on this turn being generated

func add_piece(p:Piece) -> void:
	p.starting_turn = states.size() - p.states.size()
	var p_ss:Dictionary = p.starting_state
	if !p.states.is_empty(): p_ss = p.get_state()
	
	get_state()[p_ss["position"]] = p
	current_state[p_ss["position"]] = p

func get_piece(pos:Variant):
	var s := current_state
	if !s.has(pos): return null
	
	var p = s[pos]
	if !(p is Piece): return null
	return p

func get_team(pos:Variant):
	var p = get_piece(pos)
	if p: return p.get_state()["team"]
	return null

func move_piece(p:Piece, new_pos:Variant) -> void:
	var s := current_state
	var p_s := p.get_state()
	var pos:Variant = p_s["position"]
	
	s.erase(pos)
	s[new_pos] = p
	get_state()[new_pos] = p.duplicate()
	
	p_s["position"] = new_pos
	p_s["changed"] = true

func take_piece(p:Piece) -> void:
	var s := current_state

func generate_options() -> void:
	var s := current_state
	var o := s.duplicate()
	
	for pos in o:
		if !(s[pos] is Piece): continue
		var p := s[pos] as Piece
		
		if p.get_team() != get_state_team(): continue
		
		p.generate_options(self)

func call_option(p:Piece, pos) -> bool:
	if !p.options.has(pos):
		return false
	p.options[pos].call(p, self, pos)
	return true

func move(p:Piece, option:Callable):
	option.call(p, self)

func add_state():
	if states.size() == 0: 
		states = [{}]
		return
	
	states.append({})

func get_state(turn := states.size() - 1) -> Dictionary:
	return states[turn]

func get_state_team(turn := states.size() - 1) -> Team:
	return teams[turn % teams.size()]

func _to_string():
	
	if states.is_empty():
		return "Board (empty)"
	
	if position_type != TYPE_VECTOR2I:
		return "Board (cannot display)"
	
	var result := "Board:\n"
	var s = current_state
	
	return StaticFuncs.shaped_2i_state_to_string(shape, s)
