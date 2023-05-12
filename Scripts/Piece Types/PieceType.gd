extends Resource
class_name PieceType

var name:StringName = "?"

var state_form:Dictionary = {"team":Team.new(),"moves":0,"position":null,"changed":false}

func generate_options(_p:Piece, _b:Board)->Dictionary:
	return {}

func to_global(_s:Dictionary, position):
	return position

func _to_string():
	return "PieceType<" + name + ">"
