extends PieceType
class_name Pawn2i

const pawn2i_state_form := {
		"position": Vector2i(), 
		"direction": Vector2i(),
		"distance": 0
		}

func _init():
	name = "pawn2i"
	state_form.merge(pawn2i_state_form, true)

func generate_options(p:Piece, b:Board)->Dictionary:
	var options := {}
	
	if !(p.type is Pawn2i):
		push_error("PieceType Pawn2i can only generate options for Pawn2i pieces")
		return options
	
	var p_state = p.get_state()
	var b_state = b.get_state()
	
	#forward step
	var up_one:Vector2i = to_global(p_state, Vector2i(0, 1))
	if !b.get_piece(up_one):
		options[up_one] = option_move
	
	#diagonal takes
	var diag_right:Vector2i = to_global(p_state, Vector2i(1, 1))
	var diag_left:Vector2i = to_global(p_state, Vector2i(-1, 1))
	var take_right = b.get_team(diag_right)
	var take_left = b.get_team(diag_left)
	
	if take_right && take_right != p.get_team():
		options[diag_right] = option_move
	if take_left && take_left != p.get_team():
		options[diag_left] = option_move
	
	#double forward step
	var up_two = to_global(p_state, Vector2i(0, 2))
	
	if p_state["moves"] == 0 && !b.get_piece(up_one) && !b.get_piece(up_two):
		options[up_two] = option_move
	
	return options

func to_global(s:Dictionary, position):
	var by:Vector2i = s["direction"]
	var bx := Vector2i(by.y, by.x)
	var px:Vector2i = bx * position.x
	var py:Vector2i = by * position.y
	var result = Accessor.traverse_board(s["position"], px + py + s["position"])
	if result: return result
	return s["position"]
	
