class_name Board
extends Node

#Board that manages the game

#Board is described by two states, the current_state and the states
#current_state shows everything that is currently on the board
#states describe the changes created by each turn
#pieces stored in states are unique, duplicated from the same piece on the last turn, 
#	turn is synonimous with the length of the states array
#pieces in current_state are references to pieces in states, and does not store duplications

#passing a turn can be described by adding a new state, and then making modifications to it
#technically, the turn starts when the new state is added, since the length of the states array increases
#the only way players should cause a turn is by getting options from generate_options() and adding a new state to play them on

#a state is made up of BoardElements, which store a reference to whatever BoardElement was in the same key last turn

#the board behaves differently based on this variable, and it should not change after the start of a game
#build = true implies that states are constructed fully, allowing for checkmate
#build = false implies a more efficient, functional option generation
#functions prefixed g_ are meant to be used when build is false
#functions prefixed b_ are meant to be used when build is true
#mutators should be able to handle both cases if they are not prefixed
var build := true

var position_type = TYPE_NIL

#the sources of the board's objects in the SceneTree, optionally used to fill shape, teams, and the pieces in starting_state
#anything outside of the Board's section of the SceneTree may not be loaded by the time the Board is loaded
@export var node_paths:Array[NodePath] = [NodePath(".")]

#max shapes and teams, set to 0 to ignore
@export var max_shape := 0
@export var max_teams := 0

#the initial state of the board, can contain Pieces and Variants
@export var starting_state := {
	"teams":[],
	"shape":[]}

#the board stores its state at the beginning of each turn
#each state is a dictionary including pieces and variables that can change during a game
#each state should store its own copies of pieces and values for other states of the board
var states:Array[Dictionary]
var current_state:Dictionary

#first board flagged as active will be set to Accessor's current_board
var active := true

### INITIALIZATION, MAY BE OVERRIDEN BY INHERITORS

func _init():

	if active: Accessor.current_board = self
	
	states = [starting_state.duplicate()]
	current_state = starting_state.duplicate()

var team_sort := func (a, b): return a.priority > b.priority
#run when the board and all of the nodes in node_paths are loaded to fill the board with pieces. shapes, etc
func fill_nodes():
	var ts = get_teams()
	var ss = get_shape()
	var a := add_node.bind(ts, ss)
	for v in node_paths:
		Accessor.get_children_recursive(get_node(v), a)
	get_teams().sort_custom(team_sort)

func _ready():
	fill_nodes()
	
	if build:b_options()
	else:g_options()
	
	Accessor.a_print(str(self))
	
#everybody shut up new class just dropped
#call this with a node to add it to the board individually
var add_node:Callable = func (v:Node, t, s) -> bool:
	if v is Piece: 
		v = v as Piece
		
		add_piece(v)
		return true
	elif v is Bound:
		v = v as Bound
		
		if (max_shape == 0 || s.size() < max_shape): s.append(v)
		else: Accessor.a_print("Could not add " + str(v) + ", max shape exceeded")
		return true
	elif v is Team:
		v = v as Team
		
		if (max_teams == 0 || t.size() < max_teams): t.append(v)
		else: Accessor.a_print("Could not add " + str(v) + ", max teams exceeded")
	
	return false

func end_game(winner:Team):
	print(winner)

### STATE MUTATORS

#add a piece, even if it is not in the SceneTree
func add_piece(p:Piece, pos=null) -> void:
	if pos == null: pos = p.get_position()
	
	var old_p = get_piece(pos)
	if old_p != null:
		remove_piece(old_p, pos, p)
	else:
		get_state()[pos] = p
	
	current_state[pos] = p
	p.state["turn"] = get_turn()

func remove_piece(p:Piece, pos=null, r=Removed.new()):
	r.last = p
	
	if pos == null: pos = p.get_position()
	get_state()[pos] = r
	current_state.erase(pos)
	
	return r

func add_element(e, k) -> void:
	var old_e = current_state.get(k)
	if old_e != null:
		remove_element(old_e, k, e)
	else:
		get_state()[k] = e
	
	current_state[k] = e

func remove_element(e, k, r=Removed.new()):
	r.last = e
	
	get_state()[k] = r
	current_state.erase(k)
	
	return r

#move piece p to a new position on the active state
#adds a Removed in the old position of the piece in generated mode
#returns the new copy of the Piece
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
	
	add_piece(p_new, new_pos)
	
	return p_new

###STATE GENERATORS

#create a new turn by calling an option on a piece
#creates a new state and fills it by calling the given option on the given piece
func call_option(p:Piece, o) -> bool:
	
	var p_o := p.options
	var option = p_o.get(o)
	if option == null:
		return false
	
	if option is Dictionary:
		add_state(option, true)
	elif option is Callable:
		add_state()
		option.call()
	
	if build: b_options()
	else: g_options()
	
	states[-1].make_read_only()
	
	return true

func g_options() -> void:
	var s := current_state
	var k := s.keys()
	var v := s.values()
	
	for i in k.size():
		var p = v[i]
		if !(p is Piece): continue
		
		p.generate_options(self)

#similar to generate options, except it generates the states resulting from each option as the values, instead of the Callables themselves
var iter := BoardIterator.new()
var iter2 := BoardIterator.new()
func b_options() -> void:
	
	add_state()
	iter2.all_options_iter_full(self, b_check)
	states.pop_back()
	current_state = iter2.state.duplicate()
	if iter2.all_options_did_break():
		Accessor.call_deferred("a_print", str(get_team()) + " is in check!")
	
	iter.all_options_iter_full(self, b_option)

func b_option(pos, piece:Piece, o, option:Callable):
	
	add_state()
	option.call()
	
	iter2.all_options_iter_full(self, b_check)
	
	var new_s = states.pop_back()
	if iter2.all_options_did_break(): 
		piece.options.erase(o)
	else:
		piece.options[o] = new_s
	current_state = iter.state.duplicate()

func b_check(pos, piece:Piece, o, option:Callable):
	
	add_state()
	option.call()
	
	if _evaluate():
		iter2.all_options_should_break()
		if piece.type is Bishop2i:
			print(self)
	
	states.pop_back()
	current_state = iter2.state.duplicate()

func add_state(s:={}, merge:=false):
	states.append(s)
	
	if merge: merge_state(states[-1])

#undo and return the undone state
func undo() -> Dictionary:
	
	if states.size() == 1:
		return {}
	
	var s:Dictionary = states.pop_back()
	tear_state(s)
	
	if build: b_options()
	else: g_options()
	
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
		var l = p.last
		if l is Removed || l == null:
			target.erase(k[i])
		else:
			target[k[i]] = l


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

func get_shape() -> Array:
	var ss = current_state.get("shape")
	if ss == null: return []
	return ss

func get_teams() -> Array:
	var ts = current_state.get("teams")
	if ts == null: return []
	return ts

func get_piece(pos, s:=current_state):
	var p = s.get(pos)
	if p == null: return null
	
	if !(p is Piece): return null
	return p

func get_element(k):
	return current_state.get(k)

func is_playable(p:Piece) -> bool:
	var t = p.get_team()
	var bt = get_team()
	return t == get_team() || bt == null || t == null

func get_state(turn := get_turn()) -> Dictionary:
	if turn < 0: return starting_state
	return states[turn]

func get_team(pos=null, turn := get_turn()) -> Team:
	
	var ts = get_teams()
	
	if typeof(pos) == position_type:
		var p:Piece = get_piece(pos)
		var t:Team
		if p: t = p.get_team()
		
		return t
	
	if ts == null || ts.is_empty():
		return null
	
	return ts[turn % ts.size()]

func get_turn() -> int:
	return states.size() - 1

func get_team_idx(pos=null, turn := get_turn()) -> int:
	
	var ts = get_teams()
	var t := get_team(pos, turn)
	
	if !t:
		return -1
	else:
		return ts.find(t)

#returns false if the input position is out of bounds
func has_position(pos) -> bool:
	var ss = get_shape()
	
	for s in ss:
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

#end the game if a winner is found
func _evaluate() -> bool:
	return false

#_traverse (WIP) allow moves to interact with the Board's shape, currently just returns to if its in bounds
func _traverse(from, to):
	var v = from + to - from
	
	if has_position(v):
		return v
	
	return null
