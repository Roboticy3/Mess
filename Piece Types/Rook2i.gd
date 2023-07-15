extends PieceType
class_name Rook2i

const rook2i_state_form := {
	"position": Vector2i(),
	"moved": false
}

func _init():
	name = "rook2i"
	state_form.merge(rook2i_state_form, true)

#track the movement of the rook to tell the king if it can castle
func option_move(p,b,o):
	p = super.option_move(p,b,o)
	p.state["moved"] = true
	return p

const directions:Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(-1, 0)
]
func generate_options(p:Piece, b:=Accessor.current_board) -> Dictionary:
	var o := {}
	add_options_from_line_directions(o, directions, p, b)
	return o
