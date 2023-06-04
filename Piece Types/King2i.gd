extends PieceType
class_name King2i

const king2i_state_form := {
	"position": Vector2i(),
	"rook axes": Vector2i(1, 0)
	}

func _init(): 
	name = "King2i"
	state_form.merge(king2i_state_form, true)

func castle_option(king:Piece, b:Board, o:Vector2i) -> void:
	pass

const squares:Array[Vector2i] = [
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
	var p_state = p.get_state()
	add_options_from_positions(o, squares, p, b)
	
	var ra = p_state["rook axes"]
	var vacancies := {}
	var is_empty = func (p, b, pos): return b.get_piece(pos) == null
	add_options_from_line_directions(vacancies, [ra], p, b, null, is_empty, 2)
	
	return o
	
	
	
