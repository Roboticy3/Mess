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
	
	var up_one:Vector2i = to_global(p_state, Vector2i(0, 1))
	if !b_state.has(up_one):
		options[up_one] = move_up_one
	
	
	
	return options

var move_up_one := func (p:Piece, b:Board) -> void:
	var p_state = p.get_state()
	b.move_piece(p, to_global(p_state, Vector2i(0, 1)))

func to_global(s:Dictionary, position):
	var by:Vector2i = s["direction"]
	var bx := Vector2i(by.y, by.x)
	var px:Vector2i = bx * position.x
	var py:Vector2i = by * position.y
	return px + py + s["position"]
	
