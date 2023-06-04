extends PieceType

const king2i_state_form := {
		"position": Vector2i()
		}

func init(): 
	name = "King2i"
	state_form.merge(king2i_state_form, true)

const squares:Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1)
]
func generate_options(p:Piece, b:Board):
	
	var p_state := p.get_state()
	var o := {}
	
	for sq in squares:
		var option = to_global(p_state, sq)
		
		if option && b.get_team(option) != p.get_team():
			o[option] = option_move
	
	
	
