extends PieceType
class_name King2i

const king2i_state_form := {
	"team": Accessor.types.TYPE.TEAM,
	"moved": false,
	"position": Vector2i(),
	"rook axes": Vector2i(1, 0)
	}

func _init(): 
	name = "King2i"
	state_form.merge(king2i_state_form, true)

func option_castle(king:Piece, b:Board, o:Vector2i, rook:Piece, ro:Vector2i) -> void:
	option_move(king, b, o)
	option_move(rook, b, ro)

#hook the movement function to update moves
func option_move(p,b,o):
	p = super.option_move(p,b,o)
	p.state["moved"] = true
	return p

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
func generate_options(p:Piece, b:=Accessor.current_board) -> Dictionary:
	
	var o := {}
	var p_state = p.get_state()
	add_options_from_positions(o, squares, p, b)
	
	if p_state["moved"]:
		return o
	
	var ra = p_state["rook axes"]
	var c1 = can_castle_to(ra, p, b)
	var c2 = can_castle_to(-ra, p, b)
	if c1: o[c1[0][1]] = option_castle.bind(p, b, c1[0][1], c1[1], c1[0][0])
	if c2: o[c2[0][1]] = option_castle.bind(p, b, c2[0][1], c2[1], c2[0][0])
	
	return o
	
func can_castle_to(direction:Vector2i, p:Piece, b:Board):
	var is_empty = func (_p, b, pos): return b.get_piece(pos) == null
	var positions = spaces_from_line_directions([direction], p, b, is_empty, 3)[0]
	if positions.size() < 2:
		return
	
	var rook = b.get_piece(b._traverse(positions.back(), positions.back() + direction))
	if !(rook is Piece && rook.type is Rook2i) :
		return
	
	var r_state = rook.get_state()
	if !(r_state["team"] == p.get_state()["team"] and !r_state["moved"]):
		return
	
	return [positions, rook]
	
	
