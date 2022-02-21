#a Piece contains all the data needed for a single chess piece
#they are derived from a text path containing all of the necessary information
#this data includes values like its team, display name, forward direction and so on
#each Piece also has a table of its own custom variables derived from its path

class_name Piece
extends Object

# name of piece and file path from which it reads instructions
var name = ""
var path = ""
#the path to the mesh .obj the piece will appear as and the team
var mesh = "Meshes/pawn.obj"
var team = 0

#the piece's position on the board
var pos = Vector2.ZERO

#F != null gets replaced
#oF is perpendicular to F
var oF = null

#instructions for marking squares when selected
var mark = Array()
#instructions for kills and creations, an upgrading pawm would technically suicide before creating a queen at 0, 0 (deep lore)
var take = Array()
var create:Dictionary = {}
#relocation only takes the vector result of one in instruction, because one piece has one position
var relocate = null

#table works like global instruction table, except data is tied to piece
#table are updated when a phase containing a string followed by a number is called
#default values are a boolean 0/1 for whether the piece can be checkmated and an integet for the number of moves
var table = {"key": 0, "moves":0, "fx":0, "fy":0, "ff":0,
#these parameters determine whether or not a piece moves in certain ways
#"x_mode":0 will change dynamically but uniformly (all basis vectors will change the same way to keep proportions
#1 will change dynamically and not uniformly (pieces will not retain proportions)
#0 and 1 are the same for rotate and translate
#2 will lock this part of the piece's transforms, making for some truly unholy concoctions
			 "scale_mode": 0, "rotate_mode":0, "translate_mode":0,
#this property will define the piece's scale relative to its square if scale_mode is 1
			 "scale": 1.0/3.0}

#piece types considered by the creation phase, indicated by their string path
var piece_types = []

var moves = 0

#fill the Instructions for the different phases of moving pieces from a text path
#gain a reference to the team the piece is on from the index that team has on the board
#initiate position
func _init(var _p, var _t = 0, var v = Vector2.ZERO):
	path = _p
	team = _t
	pos = v
	
	#open file
	var f = File.new()
	#if file does not exist, exit the init function to create "blank" piece
	if !f.file_exists(_p): pass
	#read file into string array representing the separate lines of text
	f.open(_p, File.READ)
	var content = f.get_as_text().rsplit("\n")
	
	#assign instructions based on the last stage character in the piece's instruciton file
	var stage = -1
	#loop through lines to form piece
	for c in content:
		
		#clear spaces and create an instruction object with the current string
		c = c.strip_edges()
		#make sure to send in table to add this piece's table to the board's
		var I = Instruction.new(c, table)
		
		#set instructions to the correct stage
		if stage == -1:
			#break up string by spaces
			var s = I.to_string_array()
			#assign name if not done already
			if s.size() > 0:
				if name == "":
					name = s[0].strip_edges()
				#try and set the piece's model path
				if f.file_exists(s[0]):
					mesh = s[0]
			
			#once name is assigned, add metadata to the piece
			#0 0 0 will signify F = 0 0, ff = false
			#check the 4, 3, and 2 lengths to see if any come up
			var l = 4
			s = I.vectorize(0, l)
			while l > 2 && s == null:
				l -= 1
				s = I.vectorize(0, l)
			#if s is null, ignore this step
			if s != null:
				#only assign the vector if thats all that shows
				if s[0] is Vector2:
					set_forward(s[0])
			
			#try to update table from metadata line, essentially initializing the table
			update_table(I)
			
		#add instructions into the appropriate collections
		elif stage == 0: 
			mark.append(I) 
		elif stage == 1: 
			take.append(I)
		#the creation stage takes a path keyed by an instruction
		#when the creation stage is called by a board, a piece is created from the path at I.vectorize()
		elif stage == 2: 
			#mechanism from board
			#initialize pieces from the paths in which they appear
			f = File.new()
			#only consider them if they are named
			if f.file_exists(c): piece_types.append(c)
			
			#parse 3rd element of line if possible
			var p = I.to_string_array()
			if p != null && p.size() > 2:
				create[I] = p[2]
		#the relocation step can only refer to one location
		elif stage == 3: 
			relocate = I
		
		#update the stage
		#m for mark, t for take, c for create, r for relocate
		if c.match("m"): stage = 0
		elif c.match("t"): stage = 1
		elif c.match("c"): stage = 2
		elif c.match("r"): stage = 3

#allow for table declarations and value updates to be made anywhere in a piece's instructions
#call this function whenever a piece is acted upon
func update_table(var I:Instruction):
	#populate piece table by trying taking numbers from the second word
	var s = I.to_string_array()
	#only update table if there are at least two elements in the line
	if s.size() > 1:
		#only update the table if the value being sent is not null
		var n = I.parse(s[1])
		if n != null:
			table[s[0]] = n
			
#sets the forward and orthogonal forward vector along with the table values correctly
func set_forward(var _F:Vector2 = Vector2(0, 1)):
	oF = Vector2(_F.y, -_F.x)
	table["fx"] = _F.x
	table["fy"] = _F.y

func get_forward():
	return Vector2(table["fx"], table["fy"])
	
func _to_string():
	return name + " " + String(team)
	
# Called when the node enters the scene tree for the first time.
func _ready(): 
	pass # Replace with function body.
