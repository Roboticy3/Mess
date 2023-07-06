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
#technically, the turn starts when the new state is added, since the length of the states array increases
#the only way players should cause a turn is by getting options from generate_options() and adding a new state to play them on

#the board behaves differently based on this variable, and it should not change after the start of a game
#build = true implies that states are constructed fully, allowing for checkmate
#build = false implies a more efficient, functional option generation
#functions prefixed g_ are meant to be used when build is false
#functions prefixed b_ are meant to be used when build is true
#mutators should be able to handle both cases if they are not prefixed
var build := false

var position_type = TYPE_NIL

#the shape of the board and the teams on it
@export var shape:Array[Bound]
@export var teams:Array[Team]

#the sources of the board's objects in the SceneTree, optionally used to fill shape, teams, and the pieces in starting_state
@export var node_paths:Array[NodePath] = [NodePath(".")]

#the initial state of the board, can contain Pieces and Variants
var starting_state := {}

#the board stores its state at the beginning of each turn
#each state is a dictionary including pieces and variables that can change during a game
#each state should store its own copies of pieces and values for other states of the board
var states:Array[Dictionary] = [starting_state.duplicate()]
#only used when build is false
var current_state := starting_state

#first board flagged as active will be set to Accessor's current_board
var active := true

func _init():
	if active: Accessor.current_board = self

#run when the board and all of the nodes in node_paths are loaded to fill the board with pieces. shapes, etc
func fill_nodes():
	for v in node_paths:
		Accessor.get_children_recursive(get_node(v), add_node)
	#sort the teams array by the priority assigned to each team
	teams.sort_custom(func (t1:Team, t2:Team) -> bool: return t1.priority > t2.priority)
	
#everybody shut up new class just dropped
#call this with a node to add it to the board individually
var add_node:Callable = func (v:Node) -> bool:
	if v is Piece: 
		v = v as Piece
		
		add_existing_piece(v)
		return true
	elif v is Bound:
		v = v as Bound
		
		shape.append(v)
		return true
	elif v is Team:
		v = v as Team
		
		teams.append(v)
	
	return false

### STATE MUTATORS
#only call after calling add_state()!

#add a piece that was already in the SceneTree
func add_existing_piece(p:Piece) -> void:
	p.starting_turn = states.size() - 1
	add_piece(p)

#add a piece, even if it is not in the SceneTree
func add_piece(p:Piece):
	var p_s = p.state
	get_state()[p_s["position"]] = p
	current_state[p_s["position"]] = p

#move piece p to a new position on the active state
#adds a Removed in the old position of the piece in generated mode
func move_piece(p:Piece, new_pos) -> Piece:
	var s := current_state
	var p_s := p.get_state()
	var pos = p_s["position"]
	
	var p_new:Piece
	p_new = copy_piece(p)

	p_new.last = s.get(new_pos)
	var r = Removed.new()
	r.last = p
	get_state()[pos] = r
	
	var n_s := p_new.get_state()
	n_s["position"] = new_pos
	
	s.erase(pos)
	add_piece(p_new)
	
	return p_new

###STATE GENERATORS

func g_options() -> void:
	var s := current_state
	var k := s.keys()
	var v := s.values()
	
	for i in k.size():
		var p = v[i]
		if !(p is Piece): continue
		
		p.generate_options(self)

func g_call_option(o:Callable):
	add_state()
	o.call()
	g_options()

#create a new turn by calling an option on a piece
#creates a new state and fills it by calling the given option on the given piece
func call_option(p:Piece, o) -> bool:
	
	var p_o := p.options
	if !p.options.has(o):
		return false
	
	if build:
		add_state(p_o[o], true)
		b_options()
	else:
		g_call_option(p_o[o])
	
	states[-1].make_read_only()
	
	return true

#similar to generate options, except it generates the states resulting from each option as the values, instead of the Callables themselves
func b_options(depth:=1) -> void:
	
	if depth < 1:
		return
	
	var s := current_state.duplicate()
	var k := s.keys()
	var v := s.values()
	
	for i in k.size():
		var p = v[i]
		if !(p is Piece): continue
		
		p.generate_options(self)
		if p.options.is_empty():
			k[i] = Removed
	
	for i in k.size():
		if k[i] is Object and k[i] == Removed: continue
		
		var p = v[i]
		if !(p is Piece): continue
		
		var o_k = p.options.keys()
		var o_v = p.options.values()
		
		for j in o_k.size():
			var o = o_v[j]

			var new_s = b_state_from_key_val(k, v)
			add_state(new_s)
			o.call()
			
			b_options(depth - 1)
			p.options[o_k[j]] = states.pop_back()
			
			current_state = s.duplicate()

#copy all the pieces in a state cut down by b_options
func b_state_from_key_val(k:Array, v:Array) -> Dictionary:
	
	var new_s = {}
	
	for i in k.size():
		if k[i] is Object and k[i] == Removed: continue
		
		var p = v[i]
		if !(p is Piece): continue
		
		new_s[k[i]] = p
	
	return new_s

func add_state(s:={}, merge:=false):
	states.append(s)
	
	if merge:	merge_state(states[-1])

#undo and return the undone state
func undo() -> Dictionary:
	
	if states.size() == 1:
		return {}
	
	var s:Dictionary = states.pop_back()
	
	if build:
		current_state = get_state()
	else:
		for pos in s:
			var p = s[pos]
			current_state[pos] = p.last
	
	return s

#fill the current_state from every generated state
func g_rebuild_current():
	
	current_state = states[0].duplicate()
	var i := 1
	while i < states.size():
		
		merge_state(states[i])
		
		i += 1

func merge_state(s:Dictionary):
	for pos in s:
		var p = s[pos]
		if !(p is Removed):
			current_state[pos] = p
		else:
			current_state.erase(pos)

###GETTERS

func get_piece(pos, s:=current_state):
	if !s.has(pos): return null
	
	var p = s[pos]
	if !(p is Piece): return null
	return p

func get_state(turn := states.size() - 1) -> Dictionary:
	return states[turn]

func get_team(pos=null, turn := states.size() - 1) -> Team:
	
	if typeof(pos) == position_type:
		var p:Piece = get_piece(pos)
		var t:Team
		if p: t = p.get_team()
		
		return t
	
	if teams.is_empty():
		return null
	
	return teams[turn % teams.size()]

#returns false if the input position is out of bounds
func has_position(pos) -> bool:
	for s in shape:
		if s.has_position(pos):
			return true
	return false

#implemented by inheritors
func get_winner(_state:=current_state) -> Team:
	return

#traverse (WIP) allow moves to interact with the Board's shape, currently just returns to if its in bounds
func traverse(from, to):
	var v = from + to - from
	
	if has_position(v):
		return v
	
	return null

func copy_piece(p:Piece) -> Piece:
	var new_p:Piece = Piece.new()
	var pp = p.get_parent()
	
	new_p.type = p.type
	new_p.state = p.state.duplicate()
	new_p.starting_turn = states.size() - 1
	
	pp.add_child(new_p)
	
	return new_p
