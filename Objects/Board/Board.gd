class_name Board
extends Node

#Board object made by Pablo Ibarz
#created in November 2021

#store pairs of pieces and their location
#FIX: this is data-redundant because pieces also store their location
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

func _ready():
	
	#initialize file object for collecting the board's info
	var b = File.new()
	b.open(path, File.READ)
	var content = b.get_as_text().rsplit("\n")
	
	#store vectors across iterations
	var vec = null
	
	#store the following values across iterations
	var persist:PoolIntArray = [-1, 0]
	
	#loop through instruction lines
	for c in content:
		
		#create an instruction from the current line
		var I = Instruction.new(c)
		
		#append the current vector if it's valid
		var v = I.vectorize(0, 1)
		if (v != null): 
			#for boards, only one vector set should be created at a time
			vec = v[0]
		
		#metadata phase is for determining things like the name and porperties of the board
		if (persist[0] == -1):
			#code from line 64 of Piece.gd
			#break up string by spaces
			var s = I.to_string_array()
			
			#allow operations to be done with the first word if s has size
			#assign name if not done already
			if s.size() > 0:
				if (name == ""):
					name = s[0].strip_edges()
				if b.file_exists(s[0]):
					mesh = s[0]
			
			#update string table with variables
			I.update_table(table)
			
		#next stage creates the boundaries of the board
		elif (persist[0] == 1):
			#board creation waits until there is a 4 number list in vec, then creates a bound
			if (vec.size() >= 4):
				bounds.append(set_bound(vec))
				vec = null
			
				#update key points in square space
				for bound in bounds:
					if bound.b.x < minimum.x: minimum.x = bound.b.x
					if bound.b.y < minimum.y: minimum.y = bound.b.y
					if bound.a.x > maximum.x: maximum.x = bound.a.x
					if bound.a.y > maximum.y: maximum.y = bound.a.y
				
				center = (minimum-maximum) / 2 + maximum
				#add size to default Vector2.ONE since max-min is exclusive of the leftmost row and column
				size = maximum - minimum + Vector2.ONE
			
		elif (persist[0] == 2):
			#portal creation waits until there are 10 nums in the vector, then initializes a portal
			if (vec.size() >= 10):
				#a portal consists of 2 bounds (indices 0 - 7) and a change in direction (indices 8 and 9)
				var i = set_bound(vec.slice(0, 3))
				var j = set_bound(vec.slice(4, 7))
				var k = vec.slice(8, vec.size())
				k = Vector2(k[0], k[1])
				portals.append(PortalBound.new(i, j, k))
				vec = null
				
		elif (persist[0] == 3):
			#team creation takes in a vector of length 6
			if (vec.size() >= 6):
				#the first three indicate color
				var i = Color(vec[0], vec[1], vec[2])
				#the next two are the forward direction of the team
				var j = Vector2(vec[3], vec[4])
				#the last is a boolean indicating friendly fire
				var k = vec[5] == 1
				teams.append(Team.new(i, j, k))
				vec = null
		
		elif (persist[0] == 4):
			#initialize pieces from the paths in which they appear
			#Piece.new() runs a file path check on a path input, so this works just fine
			var p = Piece.new(c)
			
			#only consider piece paths if they are named
			if p.name != "": 
				piece_types.append(c)
				continue
			
			#if this line has not declared a path
			if vec.size() >= 4 && piece_types.size() > 0:
				var pos = set_piece(vec)
				#check if symmetry should be enabled
				if vec.size() == 5:
					persist[1] = vec[4]
					
				#symmetrize piece
				if persist[1] == 1:
					pos = -pos + 2*(center)
					vec[0] += 1
					vec[2] = pos.x
					vec[3] = pos.y
					set_piece(vec)
		
		#set phase for next line
		if (c.match("b")):
			persist[0] = 1
		elif (c.match("p")):
			persist[0] = 2
		elif (c.match("t")):
			persist[0] = 3
		elif (c.match("g")):
			persist[0] = 4
			#if teams are empty by game phase, add black and white teams implicitly
			if teams.empty():
				teams.append(Team.new())
				teams.append(Team.new(Color.black, Vector2.UP))

#set piece and return set position from array of length 4
#return null if the set fails
func set_piece(var i:Array):
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

#create a boundary object from a vector of length 4
func set_bound(var i:Array):
	if i.size() < 4: return null
	var p = Vector2(i[0], i[1])
	var q = Vector2(i[2], i[3])
	return Bound.new(p, q)

#check if a square is inside of the board's bounds
func is_surrounding(var pos:Vector2):
	#loop through bounds
	for b in bounds:
		if b.is_surrounding(pos):
			return true
	#if no bounds enclosed pos, return false
	return false

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
