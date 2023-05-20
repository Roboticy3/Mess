extends Resource
class_name PieceType

var name:StringName = "?"

var state_form:Dictionary = {"team":Team.new(),"moves":0,"position":null,"changed":false}

func generate_options(_p:Piece, _b:Board)->Dictionary:
	return {}

var option_move := func (p:Piece, b:Board, o:Variant) -> void:
	var p_state = p.get_state()
	var p_new = b.move_piece(p, o)

func to_global(s:Dictionary, position):
	return Accessor.traverse_board(s["position"], s["position"] + position)

func _to_string():
	return "PieceType<" + name + ">"
