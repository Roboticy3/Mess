class_name Board
extends Node

#Board object made by Pablo Ibarz
#created in November 2021

#store pairs of pieces and their location
var pieces:Dictionary = {}
#store the types of pieces on the board to avoid having to load pieces from scratch every time
var piece_types = []

#store a list of the teams on the board
var teams:Array = []
#turn increases by 1 each turn and selects the active team via teams[turn % teams.size()]
var turn:int = 0

#the instruction and mesh path of the board
var path:String = ""
var mesh:String = ""

#the rectangular boundries and portals which define the shape of the board
var bounds:Array = Array()
var portals:Array = Array()

#the center, min, and max of the board in square space
var center:Vector2
var maximum = Vector2(-1000000, -1000000)
var minimum = Vector2.INF
var size = Vector2.ONE

#store a set of variables declared in metadata phase
var table:Dictionary = {"scale":1, "piece_scale":0.2}

#an Vector2 Dictionary of Vector2 Dictionaries representing the marks each piece has on the board
var marks:Dictionary = {}

func _ready():
	
	#store the following values across multiple lines in Reade object
	var persist:PoolIntArray = [-1, 0]
	
	#tell Reader object which functions to call
	var funcs = {"b":"b_phase", "t":"t_phase", "g":"g_phase"}
	
	#read the Instruction file
	var r:Reader = Reader.new(self, funcs, path)
	r.read()

#x_phase() functions are called by the Reader object in ready to initialize the board
#all x_phase functions take in the same arguments I, vec, and file

#_phase is the default phase and defines metadata for the board like mesh and name
func _phase(var I:Instruction, var vec:Array, var persist:Array):
	#code from line 64 of Piece.gd
	#break up string by spaces
	var s = I.to_string_array()
	
	#allow operations to be done with the first word if s has size
	if s.size() > 0 && s[0].length() > 0:
		var p:String = path.substr(0, path.find_last("/") + 1) + s[0]
		var b = File.new()
		#assign name if not done already
		if (name == ""):
			name = s[0].strip_edges()
		#only assign mesh after name
		elif b.file_exists(p) && p.ends_with(".obj"):
			mesh = p
	
	#update string table with variables
	I.update_table(table)

#b_phase implicitly defines the mesh and defines the boundaries of the board from sets of 4 numbers
func b_phase(var I:Instruction, var vec:Array, var persist:Array):
	if mesh.empty(): mesh = "Instructions/default/meshes/default.obj"
	
	#board creation waits until there is a 4 number list in vec, then creates a bound
	if (vec.size() >= 4):
		bounds.append(set_bound(vec))
		vec = []
	
		#update key points in square space
		for bound in bounds:
			if bound.b.x < minimum.x: minimum.x = bound.b.x
			if bound.b.y < minimum.y: minimum.y = bound.b.y
			if bound.a.x > maximum.x: maximum.x = bound.a.x
			if bound.a.y > maximum.y: maximum.y = bound.a.y
		
		center = (minimum-maximum) / 2 + maximum
		#add size to default Vector2.ONE since max-min is exclusive of the leftmost row and column
		size = maximum - minimum + Vector2.ONE

#the t phase handles explicit team creation
func t_phase(var I:Instruction, var vec:Array, var persist:Array):
	#team creation takes in a vector of length 6
	if (vec.size() >= 6):
		#the first three indicate color
		var i = Color(vec[0], vec[1], vec[2])
		#the next two are the forward direction of the team
		var j = Vector2(vec[3], vec[4])
		#the last is a boolean indicating friendly fire
		var k = vec[5] == 1
		teams.append(Team.new(i, j, k))
		vec = []

#the g phase handles implicit team creation and places pieces on the board
#uses persitant to create a "sub-stage" where pieces are placed on the board with symmetry
func g_phase(var I:Instruction, var vec:Array, var persist:Array):
	#if there are no teams from the t phase, implicitly create black and white teams
	if teams.empty():
		teams.append(Team.new())
		teams.append(Team.new(Color.black, Vector2.UP))
	
	var c = I.contents
	
	#if pieces start with default, load them from Instructions/default/
	if c.find("default") == 0:
		c = c.substr(c.find("/"))
		c = "Instructions/default/pieces" + c
	else:
		c = path + c
	
	#only try to use files that exist
	#the Piece object should have this handled but its more direct to check here
	var b = File.new()
	if b.file_exists(c):
	
		#initialize pieces from the paths in which they appear
		#Piece.new() runs a file path check on a path input, so this works just fine
		var p = Piece.new(c)
		
		#only use named pieces to avoid ambiguous pieces on the board
		if !p.name.match(""):
			piece_types.append(c)
			#when a piece is assigned, skip the rest of the g phase loop
			return null
	
	#if this line has not declared a path
	if vec.size() >= 4 && piece_types.size() > 0:
		var pos = make_piece(vec)
		#check if symmetry should be enabled
		if vec.size() == 5:
			persist[1] = vec[4]
			
		#symmetrize piece
		if persist[1] == 1:
			pos = -pos + 2*(center)
			vec[0] += 1
			vec[2] = pos.x
			vec[3] = pos.y
			make_piece(vec)

#set piece and return set position from array of length 4
#return null if the set fails
func make_piece(var i:Array):
	var v = Vector2(i[2], i[3])
	#the first indicates the team and the second the type of piece
	if i[0] < teams.size() && i[1] < piece_types.size():
		var p = Piece.new(piece_types[i[1]], i[0], v)
		
		#if piece has not overrided team's direction, set it
		if p.get_forward() == Vector2.ZERO:
			p.set_forward(teams[i[0]].forward)
			
		#add the piece to the dictionary
		teams[i[0]].pieces[v] = p
		pieces[v] = p
	
	else: return null
	
	return v
	
func get_piece(var v:Vector2):
	if v in pieces:
		return pieces[v]
	else:
		return null

#create a boundary object from a vector of length 4
func set_bound(var i:Array):
	if i.size() < 4: return null
	var p = Vector2(i[0], i[1])
	var q = Vector2(i[2], i[3])
	return Bound.new(p, q)

#check if a square is inside of the board's bounds
func is_surrounding(var pos:Vector2, var inclusive:bool = true):
	#loop through bounds
	for b in bounds:
		if b.is_surrounding(pos, inclusive):
			return true
	#if no bounds enclosed pos, return false
	return false

#find bounds surrounding a position on the board
func find_surrounding(var pos:Vector2, var inclusive:bool = true):
	#array of surrounding boundaries
	var surrounding:PoolIntArray = []
	#loop through bounds
	for i in bounds.size():
		var b:Bound = bounds[i]
		if b.is_surrounding(pos, inclusive):
			surrounding.append(i)
	return surrounding

#generate marks for a piece as a PoolVector2Array from its position on the board
func mark(var v:Vector2):
	
	#do not consider empty positions
	if !(v in pieces):
		return {}
	
	#gain a reference to the piece at v
	var p:Piece = pieces[v]
	
	#gain a reference to that piece's marks
	var m:Array = p.mark
	
	#store a set of positions to return so BoardMesh can display a set of selectable squares
	var pos:Dictionary = {}
	
	#whether the line of the move is diagonal (0), jumping (1), or infinite diagonal (2)
	var l:int = 0
	
	#loop through instructions in a p's marks
	for i in m.size():
		
		#give instruction reference to pieces and p.table so variables can be processed
		m[i].pieces = pieces
		m[i].table = p.table
		#pull a vector of numbers from the instruction
		var a:Array = m[i].vectorize()
		var s:int = a.size()
		
		#get line type from the third number
		if s > 2:
			l = a[2]
		#vectors for marks must be of at least size 2
		elif s < 2:
			continue
		
		#create a Vector2 object from the first two entries in a
		var x:Vector2 = Vector2(a[0], a[1])
		x = p.relative_to_square(x)
		
		#append s to pos and add entry in debug dictionary
		mark_step(p, x, pos, l)
	
	print(pos)
	
	return pos

#WIP return a Vector2 Dictionary of positions with data about each mark attached
func mark_step(var from:Piece, var to:Vector2, var s:Dictionary, var line:int = 0):
	
	#if line mode is jump, just check if to is free or takeable and, if so, return it
	if line == 1 && is_surrounding(to):
		if !pieces.has(to) || Instruction.can_take_from(from.team, pieces[to].team, from.table):
			s[to] = 0
	
	#position of piece
	var pos:Vector2 = from.get_pos()
	#"to-pos" which the mark function is aiming for
	var tp:Vector2 = to - pos
	#"base unit" of the diagonal
	var d:Vector2 = tp.normalized()
	
	#movement array to eventually return
	#v is relative positions and s (from method args) is board positions
	var v:Array = []
	
	#the next vector (x) and position (y) to check, as well as a place to store the last vector
	var x:Vector2 = d.round()
	var y:Vector2 = (d + pos).round()
	var last:Vector2 = Vector2.ZERO
	
	#while the length of the total movement is contained in the to-pos, the move is still going
	#the move could also be marked as infinite, in which case it will go on as long as possible
	while line == 2 || last.length() < tp.length():
		
		#if the movement escapes the board, stop the loop
		if !is_surrounding(y):
			break
		
		#keep track of whether or not y is filled both before and after the next mark is added
		var occ:bool = false
		if pieces.has(y):
			occ = true
			#before making the next mark, break if occupied square cannot be taken
			#a square cannot be taken if it is the same team as this square's, and this square does not have friendly fire
			#if line mode is jump
			if !Instruction.can_take_from(from.team, pieces[y].team, from.table):
				break

		#add the mark and update last
		v.append(x)
		s[y] = 0
		last = x
		
		#after making the next mark, break on takeable pieces
		if occ && Instruction.can_take_from(from.team, pieces[y].team, from.table):
			break
		
		#next relative position in the direction of to-pos
		x = (last + d).round()
		#position of the current mark on the board
		y = (x + pos).round()
	

#print the board as a 2D matrix of squares, denoting pieces by the first character in their name
func _to_string():
	
	var s:String = name
	s += "\n["
	#convert team array to string
	for i in teams.size(): 
		s += String(i) + ": (" + String(teams[i].color) + ")"
		if i < teams.size() - 1: s += ", "
	s += "]\n"
	
	#sent the starting letter of each piece name into their appropriate square
	var i = maximum.y
	while i >= minimum.y:
		for j in range(minimum.x, maximum.x + 1):
			#check if square contains a piece
			var v = Vector2(j, i)
			if pieces.has(v):
				var c = pieces[v].name[0]
				#add the letter to the string and the used letters array
				s += c
			else:
				#"." signifies a blank spot inside the board
				if is_surrounding(v):
					s += "."
				#"#" signifies an oob spot
				else:
					s += "#"
			s += " "
		s += "\n"
		i -= 1
	return s

func _init(var _path:String):
	path = _path
	_ready()
