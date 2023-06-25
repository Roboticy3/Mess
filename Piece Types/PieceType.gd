extends Resource
class_name PieceType

var name:StringName = "?"

var state_form:Dictionary = {"team":Team,"moves":0,"position":null}

func generate_options(_p:Piece, _b:=Accessor.current_board)->Dictionary:
	return {}

#options typically take a piece, board, and the option's "key" or id specifying a position or holding more information
func option_move(p:Piece, b:Board, o) -> void:
	b.move_piece(p, o)

func can_take(p:Piece, b:Board, position) -> bool:
	return position && b.get_team(position) != p.get_team()

func to_global(s:Dictionary, b:Board, position):
	return b.traverse(s["position"], s["position"] + position)

###Builtin forms for generating options in bulk

#from a list of local positions
func add_options_from_positions(options:Dictionary, positions:Array, p:Piece, b:Board, option=option_move, validator=can_take) -> void:
	var p_state = p.get_state()
	for pos in positions:
		pos = to_global(p.get_state(), b, pos)
		
		if validator.call(p, b, pos):
			options[pos] = option.bind(p, b, pos)

#spaces from a list of (sorta) global directions
#directions will not be transformed by the piece's direction since the piece may not have the direction property
#the positions they make are still traversed to and so this function will handle traversing the shape of the board
#the direction describes a line to iterate through until and invalid square is found
#returns a 2d array of all spaces traversed in order
const max_iter := 100
func spaces_from_line_directions(directions:Array, p:Piece, b:Board, validator:=can_take, iterations:=max_iter) -> Array[Array]:
	var p_state = p.get_state()
	
	var positions:Array[Array] = []
	positions.resize(directions.size())
	
	#try to create options in lines in each direction
	for i in directions.size():
		var j = 1
		#starting from the first square in a direction, travel in that direction until a square that cannot be taken is reached
		var pos = b.traverse(p_state["position"], p_state["position"] + directions[i])
		while validator.call(p, b, pos):
			
			positions[i].append(pos)
			
			#to travel in the direction, traverse the board from the current position to the next multiple of the direction
			j += 1
			pos = b.traverse(pos, pos + directions[i])
			
			#nasa memory safety
			if j > iterations:
				break
	
	return positions

func add_options_from_line_directions(options:Dictionary, directions:Array, p:Piece, b:Board, option:=option_move, validator:=can_take, iterations:=max_iter) -> void:
	var positions = spaces_from_line_directions(directions, p, b, validator, iterations)
	
	for y in positions:
		for x in y:
			options[x] = option.bind(p, b, x)

func _to_string():
	return "PieceType<" + name + ">"
