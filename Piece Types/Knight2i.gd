extends PieceType
class_name Knight2i

const knight2i_state_form := {
		"position": Vector2i()
		}

func _init():
	name = "Knight2i"
	state_form.merge(knight2i_state_form, true)

const squares:Array[Vector2i] = [
	Vector2i(-2, 1),
	Vector2i(-1, 2),
	Vector2i(1, 2),
	Vector2i(2, 1),
	Vector2i(2, -1),
	Vector2i(1, -2),
	Vector2i(-1, -2),
	Vector2i(-2, -1)
]
func generate_options(p:Piece, b:Board) -> Dictionary:
	
	var p_state := p.get_state()
	var o := {}
	
	for sq in squares:
		var option = to_global(p_state, sq)
		
		print(sq, option)
		
		if option && b.get_team(option) != p.get_team():
			o[option] = option_move
		
	
	return o
