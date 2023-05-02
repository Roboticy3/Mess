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

static func shaped_state_to_string(shape:Array[Bound2i], state:Dictionary) -> String:
	var result := ""
	for b in shape:
		result += str(b) + ":\n"
		var bs:Vector2i = b.get_size()
		
		var i := bs.y
		while i >= 0:
			var j := 0
			while j <= bs.x:
				var p := Vector2i(j, i)
				if state.has(p):
					result += state[p].type.name[0] + " "
				else:
					result += ". "
				
				j += 1
				
			result += "\n"
			i -= 1
		
		result += "\n"
	
	return result
	
