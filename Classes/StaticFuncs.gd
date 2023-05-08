class_name StaticFuncs

static func get_children_recursive(v:Node, action:Callable = func (): pass) -> Array[Node]:
	var stk:Array[Node] = [v]
	var fnd := Dictionary()
	while !stk.is_empty():
		v = stk.pop_back()
		
		action.call(v)
		
		if !fnd.has(v):
			fnd[v] = 0
			for w in v.get_children(): 
				stk.push_back(w)
	return stk

static func shaped_2i_state_to_string(shape:Array[Bound2i], state:Dictionary, display_mode:int = 0) -> String:
	var result := ""
	for b in shape:
		result += str(b) + ":\n"
		var bs:Vector2i = b.get_size()
		
		var i := bs.y
		while i >= 0:
			var j := 0
			while j <= bs.x:
				var pos := Vector2i(j, i)
				if state.has(pos):
					result += piece_single_character_display(state[pos], display_mode) + " "
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
			return p.type.name[0]
		1:
			return p.starting_state["team"].name.substr(0, 1) + " "
	return "?"
