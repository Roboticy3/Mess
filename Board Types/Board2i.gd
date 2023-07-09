extends Board
class_name Board2i

func _init():
	super._init()
	position_type = TYPE_VECTOR2I

func _to_string():
	
	if states.is_empty():
		return "Board (empty)"
	
	var result:String = super._to_string() + "\n"
	var s = current_state
	
	result += Accessor.shaped_2i_state_to_string(s, shape)
	
	return result
