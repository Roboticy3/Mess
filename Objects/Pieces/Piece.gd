class_name Piece
extends Node

#Piece class by Pablo Ibarz
#created December 2021

#store the behaviour of a piece

# name of piece and file path from which it reads instructions
var path:String = ""
#the path to the mesh .obj the piece will appear as and the team
var mesh:String = "Instructions/pieces/default/meshes/pawn.obj"
var team:int = 0

#instructions for marking squares when selected
var mark:Array = []
#arrays of taking, creating, and relocating behaviors keyed by indexes of mark
var behaviors:Dictionary = {}

#table works like global instruction table, except data is tied to piece
#table are updated when a phase containing a string followed by a number is called
#default values are a boolean 0/1 for whether the piece can be checkmated and an integet for the number of moves
#any property kept in table is accessible by the Instruction class in its vectorize() function
var table:Dictionary = {"moves":0, "fx":0, "fy":0, "ff":0,
			 "scale_mode": 0, "rotate_mode":0, "translate_mode":0,
			 "scale": 1.0/3.0, "px":0, "py":0, "angle":0, "opacity": 1}

#piece types considered by the creation phase, indicated by their string path
var piece_types:Array = []

var moves:int = 0

#initiate a piece with a path to its instruction behaviours, its team and its position
func _init(var _p:String, var _team:Team = Team.new(), var _team_index:int = 0, var v = Vector2.ZERO):
	path = _p
	team = _team_index
	set_forward(_team.forward)
	table["ff"]  = _team.ff
	set_pos(v)
	
	_ready()
	
func _ready():
	#open file
	var f = File.new()
	#if file does not exist, exit the function to create piece with no behaviour
	if !f.file_exists(path): 
		return null
	
	#create list of interperetation functions to send to a Reader
	#Piece only needs to add the mark instructions at ready
	var funcs:Dictionary = {"m":"m_phase","t":"","c":"","r":""}
	#use Reader to interperet the instruction file into usable behavior 
	var r:Reader = Reader.new(self, funcs, path)
	r.read()

func _phase(var I:Instruction, var vec:Array = [], var persist:Array = []):
	#break up string by spaces
	var s:Array = I.to_string_array()
	#create file object for checking paths
	var f:File = File.new()
	
	#assign name if not done already
	if s.size() > 0 && s[0].length() > 0:
		if name == "":
			name = s[0].strip_edges()
		#try and set the piece's model path
		var p:String = path.substr(0, path.find_last("/") + 1)
		if f.file_exists(p + s[0]):
			mesh = p + s[0]
	
	#try to update table from metadata line, essentially initializing the table
	#only do table updates if I vectorizes to a non-empty array, this will allow for primitive conditionals before piece vars
	var a:Array = I.vectorize()
	if !a.empty(): I.update_table(table)

#Piece behaviour phases are interpereted on the fly by a Board object,
#and therefore only the instruction needs to be stored
func m_phase(var I:Instruction, var vec:Array = [], var persist:Array = []) -> void:
	var c:String = I.contents
	#primitive comment parser and empty checking to avoid adding empty marks
	c.substr(0, c.find("#"))
	if !c.empty(): mark.append(I)

#the take, create, and relocate phases reference indexes of the mark array throught the persist array
#they are meant to be called when a piece moves, so they take care of vectorizing their instructions

#add Vector2 behaviors for squares to be cleared
func t_phase(var I:Instruction, var vec:Array = [], var persist:Array = []) -> void:
	
	var size = vec.size()
	if size > 2:
		persist[0] = int(vec[2])
		
	if size > 1:
		var v:Vector2 = Vector2(vec[0], vec[1])
		#transform square to board space instead of local space
		v = relative_to_square(v)
		if persist[0] == null: update_behaviors(-1, "t", v)
		else: update_behaviors(persist[0], "t", v)

#add Arrays of length 4 for piece type, creation position, and mark index
func c_phase(var I:Instruction, var vec:Array = [], var persist:Array = []) -> void:
	
	if vec.size() < 3: return
	if vec.size() > 3: persist[1] = vec[3]
	
	var v:Vector2 = Vector2(vec[1], vec[2])
	v = relative_to_square(v)
	#update behaviors with the array [vec[0], v.x, v.y]
	#this array can be used as the first argument for board.make_piece()
	if persist[1] == null: update_behaviors(-1, "c", [vec[0], v.x, v.y])
	else: update_behaviors(persist[1], "c", [vec[0], v.x, v.y])

#add Dictionaries of paired from and to coordinates under the right mark index
func r_phase(var I:Instruction, var vec:Array = [], var persist:Array = []) -> void:
	if vec.size() < 4: return
	if vec.size() > 4: persist[2] = vec[4]

	var v:Vector2 = relative_to_square(Vector2(vec[1], vec[2]))
	var u:Vector2 = relative_to_square(Vector2(vec[2], vec[3]))

	#slight rewrite of update_behaviors to create Dictionaries
	var mark:int = -1
	if persist[2] != null: mark = persist[2]
	if behaviors.has(mark):
		if behaviors[mark].has("r"):
			behaviors[mark]["r"][v] = u
		else:
			behaviors[mark]["r"] = {v : u}
	else:
		behaviors[mark] = {"r":{v:u}}
	pass
			
#update the behaviors Dictionary with new behaviors, automatically filling out missing elements
func update_behaviors(var mark:int, var stage:String, var behavior) -> void:
	if behaviors.has(mark): 
		if behaviors[mark].has(stage):
			behaviors[mark][stage].append(behavior)
		else:
			behaviors[mark][stage] = [behavior]
	else:
		behaviors[mark] = {stage: [behavior] }

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
	
func relative_to_square(var pos:Vector2):
	#form square to check from this Instruction's Piece's position, direction, and vector from u and v
	var x:Vector2 = get_pos()
	#make sure to rotate y by forward direction, which is held in the "angle" entry in a piece table
	pos = rotate_to_forward(pos)
	return (x + pos)

#rotate a direction to match the forward direction of this
func rotate_to_forward(var direction:Vector2):
	return direction.rotated(table["angle"]).round()
	
func _to_string():
	return name + " " + String(team)
