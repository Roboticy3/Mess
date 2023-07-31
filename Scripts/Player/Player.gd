extends Node
class_name Player

#the player interacts with the board by selecting a piece and then selecting one of its options
#it can be limited to select pieces from specific teams, and can only select one piece at a time

#the Player doesn't "do" anything:
#the only real functions of the player are select_piece and play, requiring a position and option respectively
#it is up to other scripts, controlling ui or a 3d scene, to provide this information and call the functions from the client

#the player must have a board to interact with to be able to do anything
@export_node_path var board_path:NodePath
var board:Board

var selection:Piece

func _ready():
	
	var b = get_node_or_null(board_path)
	if b is Board:
		board = b
	else:
		board = Accessor.current_board

func select_piece(pos) -> Piece:
	var p = board.get_piece(pos)
	if p:
		selection = p
		Accessor.a_print("selected " + str(p))
		Accessor.a_print("options: " + str(p.options.keys()))
		return p
	return null

func play(o) -> bool:
	var success := board.call_option(selection, o)
	if success: Accessor.a_print(str(self) + " played option " + str(o))
	else: Accessor.a_print(str(self) + " no option " + str(o))
	
	selection = null
	
	Accessor.a_print(str(board))
	
	return success
		


