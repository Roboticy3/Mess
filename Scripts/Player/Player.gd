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
	if success: Accessor.a_print(str(self) + " played option " + str(o) + " found in piece " + str(selection))
	else: Accessor.a_print(str(self) + " no option " + str(o) + " found in piece " + str(selection))
	
	selection = null
	
	Accessor.a_print(str(board))
	
	return success
		


