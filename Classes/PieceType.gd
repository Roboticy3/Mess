extends Resource
class_name PieceType

var name:String = "?"

var state_form:Dictionary = {"team":Team.new(),"moves":0,"position":null}

func generate_options(_p:Piece, _b:Board)->Dictionary:
	return {}

func to_global(_s:Dictionary, position):
	return position
