extends PieceType
class_name Pawn2D

const pawn2d_state_form := {
		"position": Vector2i(), 
		"direction": Vector2i(),
		"distance": 0}

func _init():
	name = "Pawn2D"
	state_form.merge(pawn2d_state_form, true)

func generate_options(p:Piece, b:Board)->Dictionary:
	var options := {}
	
	if !(p.type is Pawn2D):
		push_error("PieceType Pawn2D can only generate options for Pawn2D pieces")
		return options
	
	var p_state = p.get_state()
	var b_state = b.get_state()
	
	#forward step
	var up_one:Vector2i = to_global(p_state, Vector2i(0, 1))
	if !b.get_piece(up_one):
		options[up_one] = move
	
	#diagonal takes
	var diag_right:Vector2i = to_global(p_state, Vector2i(1, 1))
	var diag_left:Vector2i = to_global(p_state, Vector2i(-1, 1))
	var tr = b.get_team(diag_right)
	var tl = b.get_team(diag_left)
	
	if tr && tr != p.get_team():
		options[diag_right] = move
	if tl && tl != p.get_team():
		options[diag_left] = move
	
	#double forward step
	var up_two = to_global(p_state, Vector2i(0, 2))
	
	if p_state["moves"] == 0 && !b.get_piece(up_one) && !b.get_piece(up_two):
		options[up_two] = move
	
	return options

var move := func (p:Piece, b:Board, o:Variant) -> void:
	var p_state = p.get_state()
	var p_new = b.move_piece(p, o)

func to_global(s:Dictionary, position):
	var by:Vector2i = s["direction"]
	var bx := Vector2i(by.y, by.x)
	var px:Vector2i = bx * position.x
	var py:Vector2i = by * position.y
	return px + py + s["position"]
	
