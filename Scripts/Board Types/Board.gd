class_name Board
extends Node

#Board that manages the game

#Board is described by two states, the current_state and the states
#current_state shows everything that is currently on the board
#states describes the changes created by each turn
#pieces stored in states are unique, duplicated from the same piece on the last turn, 
#	turn is synonimous with the length of the states array
#pieces in current_state are references to pieces in states, and does not store duplications

#passing a turn can be described by adding a new state, and then making modifications to it
#using provided functions should update both the new state and current_state in sync
#technically, the turn starts when the new state is added, since the length of the states array increases
#the only way players should cause a turn is by getting options from generate_options() and adding a new state to play them on

var shape:Array[Bound]
var teams:Array[Team]

@export var node_paths:Array[NodePath] = [NodePath(".")]

var piece_types:Array[PieceType]

var starting_state := {}

#the board stores its state at the beginning of each turn
#each state is a dictionary including pieces and variables that can change during a game
var states:Array[Dictionary] = [starting_state.duplicate()]
var current_state := starting_state

#run when the board and all of the nodes in node_paths are loaded to fill the board with pieces. shapes, etc
func fill_nodes():
	for v in node_paths:
		Accessor.get_children_recursive(get_node(v), add_node)
	
	teams.sort_custom(func (a:Team, b:Team): return a.priority > b.priority)
	Accessor.a_print(str(teams))
	
#everybody shut up new class just dropped
#call this with a node to add it to the board individually
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
		
		if p.get_team() != get_state_team(): 
			p.options = {}
			continue
		
		p.generate_options(self)

#create a new turn by calling an option on a piece
#creates a new state and fills it by calling the given option on the given piece
func call_option(p:Piece, o) -> bool:
	
	var p_o := p.options
	if p_o.has(o):
		add_state()
		p_o[o].call(p, self, o)
		Accessor.a_print(str(self) + " played option " + str(o) + " found in piece" + str(p))
		generate_options()
		return true
	Accessor.a_print(str(self) + " no option " + str(o) + " found in piece" + str(p))
	return false

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