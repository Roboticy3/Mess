extends Board
class_name Board2i

const position_type = TYPE_VECTOR2I

func _ready():
	
	#now fill the board
	fill_nodes()
	
	#template for a turn
	
	#generate options to use for the turn
	generate_options()
	#select a piece to move
	var square := Vector2i(0, 1)
	var p:Piece = get_piece(square)

func _to_string():
	
	if states.is_empty():
		return "Board (empty)"
	
	var result := "Board:\n"
	var s = current_state
	
	return StaticFuncs.shaped_2i_state_to_string(shape, s)
