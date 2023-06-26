extends Board
class_name Board2i

func _init():
	position_type = TYPE_VECTOR2I

func _ready():
	
	#fill the board
	fill_nodes()
	
	#generate options to use for the turn
	build = true
	b_options()
#	g_options()
	
	Accessor.a_print(str(self))

func _to_string():
	
	if states.is_empty():
		return "Board (empty)"
	
	var result := "Board (turn " + str(states.size() - 1) + "):\n"
	var s = current_state
	
	result += Accessor.shaped_2i_state_to_string(s)
	
	return result
