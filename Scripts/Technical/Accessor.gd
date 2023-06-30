extends Node

var current_board:Board

const types := preload("res://Scripts/Technical/CustomTypes.gd")

func _ready():
	get_children_recursive(
	get_tree().root,
	func (v): if v is Board && v.active: current_board = v
	)

static func get_children_recursive(v:Node, action:Callable = func (): pass) -> Array[Node]:
	var stk:Array[Node] = [v]
	var fnd := {}
	while !stk.is_empty():
		v = stk.pop_back()
		
		action.call(v)
		
		if !fnd.has(v):
			fnd[v] = 0
			for w in v.get_children(): 
				stk.push_back(w)
	return stk

func shaped_2i_state_to_string(state:Dictionary, shape:Array[Bound]=current_board.shape, 
	display_mode:int = 0, position_type = current_board.position_type) -> String:
	
	if position_type != TYPE_VECTOR2I:
		return "Not 2i"
	
	var result := ""
	for s in shape:
		result += str(s) + ":\n"
		var bs = s.get_size()
		
		var i:int = bs[1]
		while i >= 0:
			var j := 0
			while j <= bs[0]:
				var pos := Vector2i(j, i)
				var p = state.get(pos)
				if p is Piece:
					result += piece_single_character_display(state[pos], display_mode) + " "
				elif p is Removed:
					result += "~ "
				else:
					result += ". "
				
				j += 1
				
			result += "\n"
			i -= 1
		
		result += "\n"
	
	return result

static func piece_single_character_display(p:Piece, display_mode:int = 0) -> String:
	match display_mode:
		0:
			return p.type.name.left(1)
		1:
			return p.starting_state["team"].name.left(1) + " "
	return "?"

signal a_print_signal
var a_debug:=""
func a_print(s:String) -> void:
	a_debug += s + "\n"
	emit_signal("a_print_signal")
