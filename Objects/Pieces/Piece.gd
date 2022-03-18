class_name Piece
extends Node

#Piece class by Pablo Ibarz
#created December 2021

#store the behaviour of a piece

# name of piece and file path from which it reads instructions
var path = ""
#the path to the mesh .obj the piece will appear as and the team
var mesh = "Instructions/default/meshes/pawn.obj"
var team = 0

#instructions for marking squares when selected
var mark:Array = []
#instructions for kills and creations, an upgrading pawm would technically suicide before creating a queen at 0, 0 (deep lore)
var take:Array = []
var create:Array = []
#relocation only takes the vector result of one in instruction, because one piece has one position
var relocate:Instruction

#table works like global instruction table, except data is tied to piece
#table are updated when a phase containing a string followed by a number is called
#default values are a boolean 0/1 for whether the piece can be checkmated and an integet for the number of moves
#any property kept in table is accessible by the Instruction class in its vectorize() function
var table = {"key": 0, "moves":0, "fx":0, "fy":0, "ff":0,
			 "scale_mode": 0, "rotate_mode":0, "translate_mode":0,
			 "scale": 1.0/3.0, "px":0, "py":0, "angle":0, "read_allies":0}

#piece types considered by the creation phase, indicated by their string path
var piece_types = []

var moves = 0

#initiate a piece with a path to its instruction behaviours, its team and its position
func _init(var _p, var _t = 0, var v = Vector2.ZERO):
	path = _p
	team = _t
	set_pos(v)
	
	_ready()
	
func _ready():
	#open file
	var f = File.new()
	#if file does not exist, exit the function to create piece with no behaviour
	if !f.file_exists(path): 
		return null
	
	#create list of interperetation functions to send to a Reader
	var funcs:Dictionary = {"m":"m_phase", "t":"t_phase", "c":"c_phase", "r":"r_phase"}
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
		if f.file_exists(path + s[0]):
			mesh = path + s[0]
	
	#try to update table from metadata line, essentially initializing the table
	#the table also handles data like forward direction in the "fx" and "fy" registers
	I.update_table(table)

#m, t, and c are added as their instruction and are interpereted in real time by the board
func m_phase(var I:Instruction, var vec:Array = [], var persist:Array = []):
	mark.append(I)
func t_phase(var I:Instruction, var vec:Array = [], var persist:Array = []):
	take.append(I)
#creation phase uses the same syntax as the placement instruction from the g phase of board
#therefore, I in create is interpereted with Board.make_piece
func c_phase(var I:Instruction, var vec:Array = [], var persist:Array = []):
	create.append(I)
#relocate can only hold one movement at once
func r_phase(var I:Instruction, var vec:Array = [], var persist:Array = []):
	relocate = I

func set_forward(var f:Vector2):
	table["fx"] = f.x
	table["fy"] = f.y
	table["angle"] = -f.angle_to(Vector2.DOWN)

func get_forward():
	return Vector2(table["fx"], table["fy"])
	
func set_pos(var p:Vector2):
	table["px"] = p.x
	table["py"] = p.y

func get_pos():
	return Vector2(table["px"], table["py"])
	
func relative_to_square(var pos:Vector2):
	#form square to check from this Instruction's Piece's position, direction, and vector from u and v
	var x:Vector2 = get_pos()
	#make sure to rotate y by forward direction, which is held in the "angle" entry in a piece table
	pos = pos.rotated(table["angle"])
	return (x + pos).floor()
	
func _to_string():
	return name + " " + String(team)
