extends Resource
class_name PieceType

var name:StringName = "?"

var state_form:Dictionary = {"team":Team.new(),"moves":0,"position":null,"changed":false}

func generate_options(_p:Piece, _b:Board)->Dictionary:
	return {}

func option_move(p:Piece, b:Board, o) -> void:
	b.move_piece(p, o)

func can_take(p:Piece, b:Board, position) -> bool:
	return position && b.get_team(position) != p.get_team()

func to_global(s:Dictionary, position):
	return Accessor.traverse_board(s["position"], s["position"] + position)

###Builtin forms for generating options in bulk

#from a list of local positions
func add_options_from_positions(options:Dictionary, positions:Array, p:Piece, b:Board, option=option_move, validator=can_take) -> void:
	var p_state = p.get_state()
	for pos in positions:
		pos = to_global(p.get_state(), pos)
		
		if validator.call(p, b, pos):
			options[pos] = option

#from a list of (sorta) global directions
#directions will not be transformed by the piece's direction since the piece may not have the direction property
#the positions they make are still traversed to and so this function will handle traversing the shape of the board
#the direction describes a line to iterate through until and invalid square is found
const max_iter := 100
func add_options_from_line_directions(options:Dictionary, directions:Array, p:Piece, b:Board, option=option_move, validator:=can_take, iterations:=max_iter) -> void:
	var p_state = p.get_state()
	#try to create options in lines in each direction
	for d in directions:
		var i = 1
		#starting from the first square in a direction, travel in that direction until a square that cannot be taken is reached
		var pos = Accessor.traverse_board(p_state["position"], p_state["position"] + d)
		while validator.call(p, b, pos):
			
			options[pos] = option
			
			#to travel in the direction, traverse the board from the current position to the next multiple of the direction
			i += 1
			pos = Accessor.traverse_board(pos, pos + d)
			
			#nasa memory safety
			if i > iterations:
				break

func _to_string():
	return "PieceType<" + name + ">"
