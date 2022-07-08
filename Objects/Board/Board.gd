class_name Board
extends Node

#Board object made by Pablo Ibarz
#created in November 2021

#store pairs of pieces and their location
var pieces:Dictionary = {}
#store the types of pieces on the board to avoid having to load pieces from scratch every time
var piece_types:Array = []

#store a list of the teams on the board
var teams:Array = []
#turn increases by 1 each turn and selects the active team via teams[turn % teams.size()]
var turn:int = 0

#the instruction and mesh path of the board
var path:String = ""

#the rectangular boundries and portals which define the shape of the board
var bounds:Array = Array()
var portals:Array = Array()

#the center, min, and max of the board in square space
var center:Vector2
var maximum = Vector2(-1000000, -1000000)
var minimum = Vector2.INF
var size = Vector2.ONE

#the path to this piece, excluding its name
var div:String = ""

#store a set of variables declared in metadata phase
var table:Dictionary = {"scale":1, "opacity":0.6, "collision":1, 
	"piece_scale":0.2, "piece_opacity":1, "piece_collision":1,
	"name":"*name*","mesh":"Instructions/default/meshes/default.obj"}

#a Vector2 Dictionary of Arrays describing the selectable marks on the board.
var marks:Dictionary = {}
#Vector2 of the piece in pieces marks belongs to
var select:Vector2

func _ready():
	#add .txt to the end of the file path if its not already present
	if !path.ends_with(".txt"):
		path += ".txt"
		
	
	#tell Reader object which functions to call
	var funcs:Dictionary = {"b":"b_phase", "t":"t_phase", "g":"g_phase"}
	
	#read the Instruction file
	var r:Reader = Reader.new(self, funcs, path)
	#if Reader sees a bad file, do not continue any further
	if r.badfile: return
	r.read()
	
	print(piece_types)
	
	#set div to only include the file path up to the location of the piece
	div = path.substr(0, path.find_last("/") + 1)
	
	

#x_phase() functions are called by the Reader object in ready to initialize the board
#all x_phase functions take in the same arguments I, vec, and file

#_phase is the default phase and defines metadata for the board like mesh and name
#warning-ignore:unused_argument
func _phase(var I:Instruction, var vec:Array, var persist:Array):
	var key:String = ""
	if !vec.empty(): key = I.update_table(table)

	if key.empty(): return

	if key.match("mesh"):
		if table[key].begins_with("@"):
			table[key] = table[key].substr(1, -1)
		else: table[key] = div + table[key]

#b_phase implicitly defines the mesh and defines the boundaries of the board from sets of 4 numbers
#warning-ignore:unused_argument
#warning-ignore:unused_argument
func b_phase(var I:Instruction, var vec:Array, var persist:Array):
	
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
#warning-ignore:unused_argument
#warning-ignore:unused_argument
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
	
	var c = "Instructions/pieces/" + I.contents
	
	#default team assigns to the zeroth team
	if persist[0] == null: persist[0] = 0
	
	#only try to use files that exist
	#the Piece object should have this handled but its more direct to check here
	var b = File.new()
	if b.file_exists(c):
	
		#initialize pieces from the paths in which they appear
		#Piece.new() runs a file path check on a path input, so this works just fine
		var p = Piece.new(c)
		
		#only use named pieces to avoid ambiguous pieces on the board
		if !p.get_name().match(""):
			piece_types.append(c)
			#when a piece is assigned, skip the rest of the g phase loop
			return
	
	#if this line has not declared a path, check if it can create a piece
	if vec.size() >= 3 && piece_types.size() > 0:
		make_piece_macro(vec, persist)
		

#use and update the persistent data array in g_phase to call make_piece with the appropriate conditions from a vector
func make_piece_macro(var vec:Array, var persist:Array) -> void:
	#check for persistent settings of team and symmetry
	if vec.size() >= 4:
		persist[0] = vec[3]
		if vec.size() >= 5:
			persist[1] = vec[4]
			
	#make a piece with the updated persist settings
	var pos = make_piece(vec, persist[0])
		
	#symmetrize piece if symmetry is enabled
	if persist[1] != 0 && persist[1] != null:
		pos = -pos + 2*(center)
		vec[1] = pos.x
		vec[2] = pos.y
		make_piece(vec, persist[0] + 1)

#set piece and return set position from array of length 4
#returns the position interpereted from the input vector
func make_piece(var i:Array, var team:int) -> Vector2:
	#extract the position from the input vector
	var v = Vector2(i[1], i[2])
	#i[0] indicates the Piece's team and i[1] indicates the type
	#check if they are in range
	if team < teams.size() && i[0] < piece_types.size():
		var p = Piece.new(piece_types[i[0]], teams[team], team, v)
		#bounce the position back from the piece to accound for px or py overriding the Piece's original position
		v = p.get_pos()
			
		#add the piece to the dictionary
		teams[team].pieces[v] = p
		pieces[v] = p
	
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
	#values of dictionary contain extra propterties of the move in an array
	var pos:Dictionary = {}
	
	#whether the line of the move is diagonal (0), jumping (1), or infinite diagonal (2)
	var l:int = 0
	#whether the piece can (0), cannot (1), or can, overriding team rules (2) take other pieces
	var t:int = 0
	
	#loop through instructions in a p's marks
	for i in m.size():
		
		#give instruction reference to pieces and p.table so variables can be processed
		m[i].pieces = pieces
		m[i].table = p.table
		#pull a vector of numbers from the instruction
		var a:Array = m[i].vectorize()
		
		#get line type from the 3rd number and move type from 4th
		#only do this if index 2 has not been formatted during vectorize(),
		#otherwise line and move type may overlap from variable updates
		if m[i].is_unformatted(2) && a.size() > 2:
			l = a[2]
			if m[i].is_unformatted(3) && a.size() > 3:
				t = a[3]
			
		#vectors for marks must be of at least size 2
		elif a.size() < 2:
			continue
		
		#append s to pos and add entry in debug dictionary
		mark_step(p, Vector2(a[0], a[1]), l, t, pos, i)
	
	return pos

#create a path of marks between Piece position and a target position
#the behaviors of this path are determined by the line and type arguments
#	line 0 will move through from towards to until it reaches to or is interrupted
#	line 1 will try to jump to to and cannot be interrupted unless the final square is blocked
#	line 2 will act similarly to 0 but will move in the same direction until interrupted instead of stopping at to
#	type 0 will end the path at the first take
#	type 1 will end the path right before the first take
#	type 2 will override the friendly fire property of from, but otherwise works like type 0
#s is the Dictionary that will be updated with a key for each new mark
#if a mark was already present in s, it will not be reassigned to
#index is what is assigned as the value of each mark in s
#each key in the returned dictionary represents a possible move created by the current instruction, represented by mark
func mark_step(var from:Piece, var to:Vector2,
	var line:int = 0, var type:int = 0, var s:Dictionary = {}, var i:int = 0) -> Dictionary:
	
	#create a Vector2 object from the first two entries in a
	to = from.transform(to)
	
	#print(to)

	#position of piece
	var pos:Vector2 = from.get_pos()
	#"to-pos" which the mark function is aiming for
	var tp:Vector2 = to - pos
	
	#percentage of tp that has been moved along, between 0 and 1
	#when both hit 1, to has been reached
	var x:float = 0
	var y:float = 0
	#if either move is 0, x and/or y to 1 automatically
	if tp.x == 0: x = 1
	if tp.y == 0: y = 1
	
	#square to check each loop
	var square:Vector2 = pos
	#print(from,tp)
	
	#directions to move square in
	var u:Vector2 = Vector2(1, 0) * sign(tp.x)
	var v:Vector2 = Vector2(0, 1) * sign(tp.y)
	
	#whether or not the current square is the last
	var last:bool = false
	
	#move square until the move is done, or move until another break condition if line is infinite
	while !last || line == 2:
		
		#check if x or y has less progress, move square accordingly
		#if the y cannot progress, x is the only available option to move and vice-versa
		#if they are the same, check which needs a larger total of squares
		if x < y && tp.x != 0 || (y == x && abs(tp.x) > abs(tp.y)): 
			square += u
		elif y < x && tp.y != 0 ||  (y == x && abs(tp.x) > abs(tp.y)): 
			square += v
		#if x and y are the same, tp is perfectly diagonal and neither x or y are 0, move diagonally
		else:
			square += u + v
				
		#relative square to pos
		var ts:Vector2 = square - pos

		#then update x and y, this will give the last move one iteration before the loop breaks
		if tp.x != 0: x = ts.x / tp.x
		if tp.y != 0: y = ts.y / tp.y
		#update check for whether this is the last move or not
		last = x >= 1 && y >= 1
		#print(ts,Vector2(x, y))
		
		#if line type is 1, and the final square is not yet being checked, skip to next square
		var final:bool = line == 1 && !last
		if final: 
			continue
		
		#break the loop if search leaves the board
		if !is_surrounding(square): break
		
		#if the square being checked is occupied, check if the piece can be taken
		var occ:bool = pieces.has(square)
		var take:bool = true
		if occ: 
			#check if the from piece can take the to square, overrided if type = 2
			take = can_take_from(from.get_pos(), square) || type == 2
			#move type 1 cannot take
			take = take && type != 1
			
			#if piece cannot be taken, break the loop before adding the next mark
			if !take:
				break
		
		#add instruction index to a new position in s
		if !s.has(square): s[square] = i
		
		#if square is occupied by a takeable piece, break after adding the square
		if occ && take: 
			break
		
	return s

#given a from and to square, returns true if a piece in from can take the to square, and false otherwise
func can_take_from(var from:Vector2, var to:Vector2) -> bool:
	var teamf:int = -1
	if pieces.has(from): teamf = pieces[from].get_team()
	var teamt:int = -1
	if pieces.has(to): teamt = pieces[to].get_team()
	
	if teamf == -1: return false
	#from BoardConverter.gd
	if teamf != teamt || pieces[from].get_ff(): return true
	return false

#execute a turn by moving a piece, updating both the piece's table and the board's pieces
#the only argument taken is a mark to select from marks
#assumes both v is in pieces and v is in bounds
#returns a dictionary of changes to the board
func execute_turn(var v:Vector2) -> Dictionary:
	
	#gain a dictionary of changes to execute
	var changes:Dictionary = compute_turn(v)

	#gain reference to the target piece and marks
	var p:Piece = pieces[select]
	var m:Array = p.mark
	var move:int = marks[v]
	
	print(changes)
	
	#execute the changes
	for c in changes:
		var a:Array = changes[c]
		for i in a.size():
			if a[i] is Vector2:
				move_piece(a[i], c)
			elif a[i] is int:
				make_piece([a[i], c.x, c.y], p.get_team())
			else:
				destroy_piece(c)
		
	#update table using the movement instruction
	m[move].update_table_line()
	
	#clear the marks dictionary and the piece's temporary behaviors so they don't effect future turns
	marks.clear()
	p.behaviors.clear()
	
	#increment turn
	turn += 1
	#return Board updates
	return changes
	
#compute a turn into a Dictionary of changes without updating the board
#changes is a set of Vector2 and Array pairs, where the array is a set of changes with its Vector2 key as the target
func compute_turn(var v:Vector2) -> Dictionary:
	
	#reference the piece being moved
	var p:Piece = pieces[select]
	#pair the m phase with nothing since marks are not being generated
	var funcs:Dictionary = {"m":"", "t":"t_phase","c":"c_phase","r":"r_phase"}
	var reader:Reader = Reader.new(p, funcs, p.path)
	reader.wait = true
	reader.read()
	
	#the piece's behaviours
	var m:Array = p.mark
	#the index of m that was used to move
	var move:int = marks[v]
	
	#convert the piece's behaviors into a set of changes
	#keys are target squares and values and squares to relocate from, a piece to create, or null to destroy
	var changes:Dictionary = {}
	#add changes from the piece
	changes_from_piece(changes, p, v)
	changes_from_piece(changes, p, v, move)
	
	return changes

#update a Dictionary of changes to the board from an index of a behaviors dictionary
func changes_from_piece(var changes:Dictionary, var piece:Piece, 
	var v:Vector2, var idx:int = -1) -> void:
		
	#gain reference to the piece's behaviors
	var behaviors:Dictionary = piece.behaviors
	
	#add the main move being done to changes
	changes[v] = [select]
	
	#do not try to execute this method if the index of behaviors is missing or empty
	if !behaviors.has(idx) || behaviors[idx].empty(): return
	
	#iterate through each section of behaviors and convert their data into the changes dictionary
	var bm:Dictionary = behaviors[idx]
	
	#print(bm)
	
	#temporarily change the piece's position
	piece.set_pos(v)
	
	#check if one type of behavior is present
	if bm.has("r"): for r in bm["r"]:
		#pos is the position being relocated to
		#r is the position being relocated from
		var pos:Vector2 = bm["r"][r]
		
		#if the relocation is from 0, 0, this piece is being moved
		var move := false
		if pos == Vector2.ZERO:
			move = true
		
		#relocations are pairs of Vector2s, both of which need to be transformed
		pos = transform(pos, piece)
		r = transform(r, piece)
		var c = r
		
		#print(pos,r)
		
		#if the relocation target is invalid, set the change as a deletion
		if pos == Vector2.INF: c = null
		#if the relocation beginning is invalid, do not add any change
		if r == Vector2.INF: continue
		
		#if the piece is being moved, update its position temporarily for transform() calls in later changes
		if move: piece.set_pos(r)
		
		#add the change into an array of changes at a destination square
		#the square being moved to in case of relocation
		if !changes.has(pos): changes[pos] = [c]
		else: changes[pos].append(c)
	
	if bm.has("c"): for c in bm["c"]:
		#creations are Vector2 and int pairs
		var p_type:int = c[0]
		var pos:Vector2 = Vector2(c[1],c[2])
		pos = transform(pos, piece)
		
		#if the creation fails, do not add any change
		if pos == Vector2.INF: continue
		
		if !changes.has(pos): changes[pos] = [p_type]
		else: changes[pos].append(p_type)
	
	if bm.has("t"): for d in bm["t"]:
		#destructions are Vector2 and null pairs
		d = transform(d, piece)
		
		#if the destruction fails, do not add any change
		if d == Vector2.INF: continue
		
		if !changes.has(d): changes[d] = [null]
		else: changes[d].append(null)
		
	#reset the piece's position
	piece.set_pos(select)

#transform a square using mark step in the jump mode, returning a singular transformed square
func transform(var v:Vector2, var piece:Piece) -> Vector2:
	
	#squares on top of their piece do not need to be transformed
	if v == Vector2.ZERO: return piece.get_pos()
	
	var pos:Dictionary = mark_step(piece, v, 1, 2)
	
	if pos.empty(): return Vector2.INF
	return pos.keys()[0]

#move the piece on from onto to
func move_piece(var from:Vector2, var to:Vector2) -> bool:
	if !pieces.has(from): return false
	pieces[to] = pieces[from]
	pieces.erase(from)
	#update the piece's local position and increment its move count
	pieces[to].set_pos(to)
	pieces[to].table["moves"] += 1
	return true

#erase a piece from the board, return true if the method succeeds
func destroy_piece(var at:Vector2) -> bool:
	if !pieces.has(at): return false
	pieces.erase(at)
	return true

#get the team of the current turn by taking turn % teams.size()
func get_team() -> int:
	return turn % teams.size()
	
func get_name() -> String:
	return table["name"]
	
func get_mesh() -> String:
	return div + String(table["mesh"])

func _init(var _path:String):
	path = _path
	_ready()

#print the board as a 2D matrix of squares, denoting pieces by the first character in their name
func _to_string():
	
	var s:String = get_name()
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
				var c = pieces[v].get_name()[0]
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
