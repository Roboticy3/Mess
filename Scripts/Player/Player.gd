extends Node
class_name Player

#the player interacts with the board by selecting a piece and then selecting one of its options
#it can be limited to select pieces from specific teams

@export var team_paths:Array[NodePath] = []
var teams:Array[Team]

@export_node_path("Board") var board_path:NodePath
@onready var board:Board = get_node(board_path)

var selection:Piece

func _ready():
	teams.resize(team_paths.size())
	
	for i in team_paths.size():
		var v = get_node(team_paths[i])
		if !(v is Team):
			teams[i] = null
			continue
		teams[i] = v
	
	select_piece(Vector2i(0, 1))
	play(Vector2i(0,2))
	select_piece(Vector2i(1, 1))
	play(Vector2i(1,2))

func select_piece(pos) -> Piece:
	var p = board.get_piece(pos)
	if p && teams.has(p.get_team()):
		selection = p
		Accessor.a_print(str(self) + ": selected " + str(p))
		return p
	return null

func play(o) -> bool:
	return board.call_option(selection, o)
		


