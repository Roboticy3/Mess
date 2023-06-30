extends PieceType
class_name Bishop2i

const bishop2i_state_form := {
	"position": Vector2i()
}

func _init():
	name = "bishop2i"
	state_form.merge(bishop2i_state_form, true)

const directions:Array[Vector2i] = [
	Vector2i(1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(-1, -1)
]
func generate_options(p:Piece, b:=Accessor.current_board) -> Dictionary:
	var o := {}
	if p.get_team() != b.get_team(): return o
	add_options_from_line_directions(o, directions, p, b)
	return o
