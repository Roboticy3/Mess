extends PieceType
class_name Pawn2i

const pawn2i_state_form := {
		"moved": false,
		"position": Vector2i(), 
		"direction": Vector2i(0, 1),
		"distance": 0
		}

func _init():
	name = "pawn2i"
	state_form.merge(pawn2i_state_form, true)

func option_move(p,b,o):
	p = super.option_move(p,b,o)
	p.state["moved"] = true
	return p

func generate_options(p:Piece, b:=Accessor.current_board)->Dictionary:
	
	var options := {}
	
	var p_state = p.get_state()
	
	#forward step
	var up_one:Vector2i = to_global(p_state, b, Vector2i(0, 1))
	if !b.get_piece(up_one):
		options[up_one] = option_move.bind(p, b, up_one)
	
	#diagonal takes
	var diag_right:Vector2i = to_global(p_state, b, Vector2i(1, 1))
	var diag_left:Vector2i = to_global(p_state, b, Vector2i(-1, 1))
	var take_right = b.get_team(diag_right)
	var take_left = b.get_team(diag_left)
	
	if take_right && take_right != p.get_team():
		options[diag_right] = option_move.bind(p, b, diag_right)
	if take_left && take_left != p.get_team():
		options[diag_left] = option_move.bind(p, b, diag_left)
	
	#double forward step
	var up_two = to_global(p_state, b, Vector2i(0, 2))
	
	if !p_state["moved"] && !b.get_piece(up_one) && !b.get_piece(up_two):
		options[up_two] = option_move.bind(p, b, up_two)
	
	return options

func to_global(s:Dictionary, b:Board, position):
	var by:Vector2i = s["direction"]
	var bx := Vector2i(by.y, by.x)
	var px:Vector2i = bx * position.x
	var py:Vector2i = by * position.y
	var result = b._traverse(s["position"], px + py + s["position"])
	if result: return result
	return s["position"]
	
