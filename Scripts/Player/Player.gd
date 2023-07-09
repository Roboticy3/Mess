extends Node
class_name Player

#the player interacts with the board by selecting a piece and then selecting one of its options
#it can be limited to select pieces from specific teams, and can only select one piece at a time

#the Player doesn't "do" anything:
#the only real functions of the player are select_piece and play, requiring a position and option respectively
#it is up to other scripts, controlling ui or a 3d scene, to provide this information and call the functions from the client

#all the teams which this player can play as, leave empty for no restriction
#a piece with no team will essentially have a team of null, and can be played by any player
#if the team_paths array is empty, the player can play any piece, as long as it has options
@export var team_paths:Array[NodePath] = []
var teams:Array[Team] = [null]

#the player must have a board to interact with to be able to do anything
@export_node_path var board_path:NodePath
var board:Board

var selection:Piece

func _ready():
	
	var b = get_node_or_null(board_path)
	if b is Board:
		board = b
	else:
		push_error("Player ", self, "'s board path does not point to a Board")
	
	for i in team_paths.size():
		var v = get_node(team_paths[i])
		if v is Team: teams.append(v)



func select_piece(pos) -> Piece:
	var p = board.get_piece(pos)
	if p && (teams.has(p.get_team()) || team_paths.is_empty()):
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
		


