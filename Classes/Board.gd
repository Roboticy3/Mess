class_name Board
extends Node

@export var position_type:Variant.Type = TYPE_VECTOR2I
var shape

@export var node_paths:Array[NodePath]

var piece_types:Array[PieceType]

var starting_state := {}

#the board stores its state at the beginning of each turn
#each state is a dictionary including pieces and variables that can change during a game
var states:Array[Dictionary] = [starting_state.duplicate()]

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
	
	add_state()
	move_piece(get_piece(Vector2i(0, 1)), Vector2i(4, 4))
	print(StaticFuncs.shaped_state_to_string(shape, get_state(0)))
	print(self)

#everybody shut up new class just dropped
var add_node:Callable = func (v:Node) -> bool:
	if v is Piece: 
		v = v as Piece
		
		add_piece(v)
		return true
	elif v is Bound:
		v = v as Bound
		
		if !shape.has(v): shape.append(v)
		return true
	
	return false

func add_piece(p:Piece) -> void:
	p.starting_turn = states.size() - p.states.size()
	var p_ss:Dictionary = p.starting_state
	if !p.states.is_empty(): p_ss = p.get_state()
	
	states[states.size() - 1][p_ss["position"]] = p

func get_piece(pos:Variant):
	var s := get_state()
	if !s.has(pos): return null
	
	var p = s[pos]
	if !(p is Piece): return null
	return p

func move_piece(p:Piece, new_pos:Variant) -> void:
	var s := get_state()
	var p_s := p.get_state()
	var pos:Variant = p_s["position"]
	
	s.erase(pos)
	s[new_pos] = p
	p.get_state()["position"] = new_pos

func generate_options():
	var s := get_state()
	var o := s.duplicate()
	
	for pos in s:
		if !(s[pos] is Piece): continue
		var p := s[pos] as Piece
		
		o[pos] = p.generate_options(self)
		print(o[pos])
	
	return o

func move(p:Piece, option:Callable):
	option.call(p, self)

func add_state():
	if states.size() == 0: 
		states = [{}]
		return
	states.append(get_state().duplicate(true))

func get_state(turn := states.size() - 1) -> Dictionary:
	return states[turn]

func _to_string():
	
	if states.is_empty():
		return "Board (empty)"
	
	if position_type != TYPE_VECTOR2I:
		return "Board (cannot display)"
	
	var result := "Board:\n"
	var s = get_state()
	
	return StaticFuncs.shaped_state_to_string(shape, s)
