extends Node

var current_board:Board

const types := preload("res://Scripts/Technical/CustomTypes.gd")

#dfs on SceneTree to get all children of a starting Node v in the scene and perform the given action on them
func get_children_recursive(v:Node, action:Callable = func (): pass) -> Array[Node]:
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

#return the state of a Board2i, with the pieces laid out on a 2d grid, as a string of rows and columns
#requires a shape to bound the grid, I'd like the type to be Array[Bound2i] but typed array casts are still a little half baked, so I have to stay away from them here
func shaped_2i_state_to_string(state:Dictionary, shape:Array, 
	display_mode:int = 0, display_key:="", position_type = current_board.position_type) -> String:
	
	if position_type != TYPE_VECTOR2I:
		return "Not 2i"
	
	var result := "(display mode " + str(display_mode) + ")\n"
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
					result += piece_single_char_display(state[pos], display_mode, display_key) + " "
				elif p is Removed:
					result += "~ "
				else:
					result += ". "
				
				j += 1
				
			result += "\n"
			i -= 1
		
		result += "\n"
	
	return result

#print a piece as a single character based on a piece and display mode, used for drawing states as strings
enum PieceSingleCharDisplayMode {
	INITIAL,
	TEAM_INITIAL,
	STATE_INITIAL #requires an additional state key to be passed
}
func piece_single_char_display(p:Piece, display_mode:PieceSingleCharDisplayMode = PieceSingleCharDisplayMode.INITIAL,
	display_key:="") -> String:
	match display_mode:
		PieceSingleCharDisplayMode.INITIAL:
			return p.type.name.left(1)
		PieceSingleCharDisplayMode.TEAM_INITIAL:
			return p.state["team"].name.left(1)
		PieceSingleCharDisplayMode.STATE_INITIAL:
			var v = p.state.get(display_key)
			if v != null: return str(v).left(1)
	return "?"

#keep a string of debug layout, creating a sort of standard output in-game
#emit a signal whenever a script wants to print to this debug text
#then scripts can also read the text to display it in the ui
signal a_print_signal
var a_debug:=""
func a_print(s:String) -> void:
	a_debug += s + "\n"
	emit_signal("a_print_signal")
