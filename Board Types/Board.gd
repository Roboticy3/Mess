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
var build := true

var position_type = TYPE_NIL

#the shape of the board and the teams on it
var shape:Array[Bound]
var teams:Array[Team]
#max shapes and teams, set to 0 to ignore
@export var max_shape := 0
@export var max_teams := 0

#the sources of the board's objects in the SceneTree, optionally used to fill shape, teams, and the pieces in starting_state
#anything outside of the Board's section of the SceneTree may not be loaded by the time the Board is loaded
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

### INITIALIZATION, MAY BE OVERRIDEN BY INHERITORS

func _init():
	if active: Accessor.current_board = self

#run when the board and all of the nodes in node_paths are loaded to fill the board with pieces. shapes, etc
func fill_nodes():
	for v in node_paths:
		Accessor.get_children_recursive(get_node(v), add_node)
	#sort the teams array by the priority assigned to each team
	teams.sort_custom(func (a:Team, b:Team) -> bool: return a.priority > b.priority)

func _ready():
	fill_nodes()
	if build: b_options()
	else: g_options()
	Accessor.a_print(str(self))
	
#everybody shut up new class just dropped
#call this with a node to add it to the board individually
var add_node:Callable = func (v:Node) -> bool:
	if v is Piece: 
		v = v as Piece
		
		add_existing_piece(v)
		return true
	elif v is Bound:
		v = v as Bound
		
		if (max_shape == 0 || shape.size() < max_shape): shape.append(v)
		else: Accessor.a_print("Could not add " + str(v) + ", max shape exceeded")
		return true
	elif v is Team:
		v = v as Team
		
		if (max_teams == 0 || shape.size() < max_teams): teams.append(v)
		else: Accessor.a_print("Could not add " + str(v) + ", max teams exceeded")
	
	return false

### STATE MUTATORS
#only call after calling add_state()!

#add a piece that was already in the SceneTree
func add_existing_piece(p:Piece) -> void:
	add_piece(p)

#add a piece, even if it is not in the SceneTree
func add_piece(p:Piece, pos=null) -> void:
	if pos == null: pos = p.get_position()
	get_state()[pos] = p
	current_state[pos] = p

func remove_piece(p:Piece, pos=null) -> void:
	var r = Removed.new()
	r.last = p
	
	if pos == null: pos = p.get_position()
	get_state()[pos] = r
	current_state.erase(pos)

#move piece p to a new position on the active state
#adds a Removed in the old position of the piece in generated mode
func move_piece(p:Piece, new_pos) -> Piece:
	
	var s := current_state
	var p_s := p.get_state()
	var pos = p_s["position"]
	
	var p_new:Piece
	p_new = copy_piece(p)

	p_new.last = s.get(new_pos)
	remove_piece(p, pos)
	
	var n_s := p_new.get_state()
	n_s["position"] = new_pos
	
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
func b_options(depth:=2) -> void:
	
	if depth < 1:
		return
	
	var s := current_state.duplicate()
	var k := s.keys()
	var v := s.values()
	
	#create a base for every new state to be created at this depth
	#contains a copy of all pieces which have options, with the options filled out
	var b_new_s := {}
	for i in k.size():
		var p = v[i]
		if !(p is Piece): 
			k[i] = null
			continue
		
		p.options = {}
		var options:Dictionary = p.generate_options(self, false)
		
		if options.is_empty():
			k[i] = null
			continue
		
		var new_p := copy_piece(p)
		new_p.options = options
		
		b_new_s[k[i]] = new_p
		v[i] = new_p
	
	merge_state(b_new_s, s)
	
	#build states from options, by applying each option to the base new state
	for i in k.size():
		if k[i] == null: continue
		var p:Piece = v[i]
		
		var options := p.options
		var o_k := options.keys()
		var o_v := options.values()
		
		for j in o_k.size():
			
			if o_v[j] is Dictionary:
				add_state(o_v[j])
			
			elif o_v[j] is Callable:
				var new_s := duplicate_state(b_new_s)
				add_state(new_s)
				merge_state(new_s)
				o_v[j].call()
			
			var l := should_lose(get_team_idx())
			
			if depth == 1 && l:
				print(Accessor.shaped_2i_state_to_string(current_state, shape))
				print(l)
			
			b_options(depth - 1)
			
			options[o_k[j]] = states.pop_back()
			current_state = s.duplicate()

func add_state(s:={}, merge:=false):
	states.append(s)
	
	if merge: merge_state(states[-1])

#undo and return the undone state
func undo() -> Dictionary:
	
	if states.size() == 1:
		return {}
	
	var s:Dictionary = states.pop_back()
	tear_state(s)
	
	b_options()
	
	return s

func merge_state(s:Dictionary, target:=current_state):
	var k := s.keys()
	var v := s.values()
	
	for i in k.size():
		var p = v[i]
		if !(p is Removed):
			if p is Piece:
				var x = target.get(k[i])
				p.last = x
			
			target[k[i]] = p
		else:
			target.erase(k[i])

func tear_state(s:Dictionary, target:=current_state):
	var k := s.keys()
	var v := s.values()
	
	for i in k.size():
		var p = v[i]
		if p is Removed or p is Piece:
			var l = p.last
			if l is Piece:
				target[k[i]] = l
			else:
				target.erase(k[i])


func duplicate_state(s:Dictionary) -> Dictionary:
	var new_s := s.duplicate()
	
	var k := s.keys()
	var v := s.values()
	
	for i in k.size():
		var p = v[i]
		if p is Piece:
			new_s[k[i]] = copy_piece(p)
	
	return new_s

###GETTERS

func get_piece(pos, s:=current_state):
	if !s.has(pos): return null
	
	var p = s[pos]
	if !(p is Piece): return null
	return p

func is_playable(p:Piece) -> bool:
	var t = p.get_team()
	return t == null || t == get_team()

func get_state(turn := get_turn()) -> Dictionary:
	return states[turn]

func get_team(pos=null, turn := get_turn()) -> Team:
	
	if typeof(pos) == position_type:
		var p:Piece = get_piece(pos)
		var t:Team
		if p: t = p.get_team()
		
		return t
	
	if teams.is_empty():
		return null
	
	return teams[turn % teams.size()]

func get_turn() -> int:
	return states.size() - 1

func get_team_idx(turn := get_turn()) -> int:
	if teams.is_empty():
		return -1
	
	return turn % teams.size()

#returns false if the input position is out of bounds
func has_position(pos) -> bool:
	for s in shape:
		if s.has_position(pos):
			return true
	return false

func copy_piece(p:Piece) -> Piece:
	var new_p:Piece = Piece.new()
	var pp = p.get_parent()
	
	new_p.type = p.type
	new_p.last = p.last
	new_p.state = p.state.duplicate()
	
	pp.add_child(new_p)
	
	return new_p

### DESIGNED TO BE OVERRIDDEN BY INHERITORS

func should_win(team_idx:int) -> bool:
	return false

func should_lose(team_idx:int) -> bool:
	return false

#traverse (WIP) allow moves to interact with the Board's shape, currently just returns to if its in bounds
func traverse(from, to):
	var v = from + to - from
	
	if has_position(v):
		return v
	
	return null

func _to_string() -> String:
	return "Board " + str(shape) + " | " + str(teams) + " (build " + str(build) + ", turn " + str(get_turn()) + ")"
