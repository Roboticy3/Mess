extends PieceType
class_name Knight2i

const knight2i_state_form := {
		"position": Vector2i()
		}

func _init():
	name = "knight2i" #lower case so single-character representation differs from King2i
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
func generate_options(p:Piece, b:=Accessor.current_board) -> Dictionary:
	var o := {}
	add_options_from_positions(o, squares, p, b)
	return o
