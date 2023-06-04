extends PieceType
class_name Queen2i

const queen2i_state_form := {
	"position": Vector2i()
}

func _init():
	name = "Queen2i"
	state_form.merge(queen2i_state_form, true)

const directions:Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(1, -1),
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, -1)
]
func generate_options(p:Piece, b:Board) -> Dictionary:
	var o := {}
	add_options_from_line_directions(o, directions, p, b)
	return o
