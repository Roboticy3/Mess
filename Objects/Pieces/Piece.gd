class_name Piece
extends Node

#Piece class by Pablo Ibarz
#created December 2021
#Reads a piece file to generate the behaviors of a piece and represents a piece on the board

#data on the file this piece is being loaded from
var type:PieceType

#arrays of taking, creating, and relocating behaviors keyed by indexes of mark
var behaviors:Dictionary = {}

#table works like global instruction table, except data is tied to piece
#table are updated when a phase containing a string followed by a number is called
#default values are a boolean 0/1 for whether the piece can be checkmated and an integet for the number of moves
#any property kept in table is accessible by the Instruction class in its vectorize() function
var table:Dictionary = {"name":"*pieceName*", "mesh":"Instructions/pieces/default/meshes/pawn.obj",
			 "moves":0, "fx":0, "fy":0, "ff":0,
			 "scale_mode": 0, "rotate_mode":0, "translate_mode":0,
			 "scale": 1.0/3.0, "px":0, "py":0, "angle":0, "opacity": 1,
			 "team":0, "collision":0, "lx":0, "ly":0}

#reference to this Piece's parent Board
#can't be statically typed because cyclic ref error ffs
var board

#the last turn on which this piece underwent changes on the board
var last_update := 0

#initiate a piece with a path to its instruction behaviours, its team and its position
func _init(var _b = null, var _type = null, 
	var _teams:Array = [], var _team_index:int = 0, var v = Vector2.ZERO):
	
	#if _b is null, skip the initiation
	if _b == null: return
	
	board = _b
	
	#get the piece's type and merge its starting table into table
	type = _type
	if type == null: return
	merge(type.table)
	
	#set team, forward direction, and position from args
	set_team(_team_index)
	#only set team properties if a team was provided
	if _team_index < _teams.size():
		var _team = _teams[_team_index]
		set_forward(_team.get_forward())
		table["ff"]  = _team.get_ff()
	set_pos(v)

#the take, create, and relocate phases reference indexes of the mark array throught the persist array
#they are meant to be called when a piece moves, so they take care of vectorizing their instructions

#add Vector2 behaviors for squares to be cleared
#warning-ignore:unused_argument
func t_phase(var I, var vec:Array = [], var persist:Array = []) -> void:
	
	var size = vec.size()
	if size > 2:
		persist[0] = int(vec[2])
		
	if size > 1:
		var v:Vector2 = Vector2(vec[0], vec[1])
		if persist[0] == null: update_behaviors(-1, "t", v)
		else: update_behaviors(persist[0], "t", v)

#add Arrays of length 4 for piece type, creation position, and mark index
#warning-ignore:unused_argument
func c_phase(var I, var vec:Array = [], var persist:Array = []) -> void:
	
	if vec.size() < 3: return
	if vec.size() > 3: persist[0] = vec[3]
	
	var v:Vector2 = Vector2(vec[1], vec[2])
	#update behaviors with the array [vec[0], v.x, v.y]
	#this array can be used as the first argument for board.make_piece()
	if persist[0] == null: update_behaviors(-1, "c", [vec[0], v.x, v.y])
	else: update_behaviors(persist[0], "c", [vec[0], v.x, v.y])

#add arrays of starting and ending positions in an orderded array so relocation can be executed in the order they were written
#warning-ignore:unused_argument
func r_phase(var I, var vec:Array = [], var persist:Array = []) -> void:
	if vec.size() < 4: return
	if vec.size() > 4: persist[0] = vec[4]

	var v:Vector2 = Vector2(vec[0], vec[1])
	var u:Vector2 = Vector2(vec[2], vec[3])

	#slight rewrite of update_behaviors to create Dictionaries
	var m:int = -1
	if persist[0] != null: m = persist[0]
	if behaviors.has(m):
		if behaviors[m].has("r"):
			behaviors[m]["r"].append(PoolVector2Array([v, u]))
		else:
			behaviors[m]["r"] = [PoolVector2Array([v, u])]
	else:
		behaviors[m] = {"r":[PoolVector2Array([v, u])]}
	pass
			
#update the behaviors Dictionary with new behaviors, automatically filling out missing elements
func update_behaviors(var m:int, var stage:String, var behavior) -> void:
	if behaviors.has(m): 
		if behaviors[m].has(stage):
			behaviors[m][stage].append(behavior)
		else:
			behaviors[m][stage] = [behavior]
	else:
		behaviors[m] = {stage: [behavior] }

#getters for this Piece's PieceType type
func get_mark() -> Array:
	return type.mark

func get_p_path() -> String:
	return type.path

func get_div() -> String:
	return type.div

#getters and setters for the table
func set_forward(var f:Vector2) -> void:
	table["fx"] = f.x
	table["fy"] = f.y
	table["angle"] = -f.angle_to(Vector2.DOWN)

func get_forward() -> Vector2:
	return Vector2(table["fx"], table["fy"])
	
func set_pos(var v:Vector2) -> void:
	table["px"] = v.x
	table["py"] = v.y

func get_pos() -> Vector2:
	return Vector2(table["px"], table["py"])
	
func set_last_pos(var v:Vector2) -> void:
	table["lx"] = v.x
	table["ly"] = v.y
	
func get_last_pos() -> Vector2:
	return Vector2(table["lx"], table["ly"])
	
func set_team(var team:int = 0) -> void:
	table["team"] = team

func get_team() -> int:
	return table["team"]

func get_ff() -> bool:
	if table["ff"] == 1: return true
	return false

func get_name() -> String:
	return table["name"]

func get_mesh() -> String:
	return String(table["mesh"])

#transform a position from a pieces local space to the board's global space
func transform(var v:Vector2) -> Vector2:
	var d:Vector2 = v.rotated(table["angle"]) * get_forward().length()
	return d.round() + get_pos()

#update table with an input new_table, updating existing keys and adding new ones
func merge(var new_table:Dictionary, var replace:bool = true) -> void:
	for k in new_table:
		if replace || !table.has(k):
			table[k] = new_table[k]
		
	
func _to_string():
	return get_name() + " " + String(get_team())
