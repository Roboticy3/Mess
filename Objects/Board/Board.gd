class_name Board
extends Node

#Board object made by Pablo Ibarz
#created in November 2021

#Board is the internal state of a game board. Should be an orphan Node interfaced by other Nodes through BoardMesh

#instruction path to the board
var path:String = ""

#store pairs of pieces and their location
var pieces:Dictionary = {}
#the current state of the board
var state:BoardState 

#properties piece_paths through div are constant from the start of the game to the end 
#store the set of pieces on the board by their file paths
var piece_types:Array = []
#store a list of the teams on the board
var teams:Array = []

#array of Instructions to vectorize to evaluate win conditions
var win_conditions:Array = []

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
	"name":"*name*","mesh":"Instructions/default/meshes/default.obj",
	"turn":0, "pi":PI}

#a Vector2 Dictionary of Arrays describing the selectable marks on the board.
var marks:Dictionary = {}

#array of winning and losing teams to populate when the game ends
var winners:Array = []
var losers:Array = []

#signal to emit when the game ends, winning team indicated by get_team()
signal end

func _init(var _path:String):
	path = _path
	_ready()

func _ready():
	#add .txt to the end of the file path if its not already present
	if !path.ends_with(".txt"):
		path += ".txt"
		
	
	#tell Reader object which functions to call, ignore w phase for now
	var funcs:Dictionary = {"b":"b_phase", "t":"t_phase", 
		"g":"g_phase", "w":""}
	
	#read the Instruction file
	var r:Reader = Reader.new(self, funcs, path, 8, self)
	#if Reader sees a bad file, do not continue any further
	if r.badfile: 
		print("Board::_ready() says \"board at " + path + " not found\"")
		return
	r.read()
	
	#read the w_phase only, not bothering to vectorize them until they need to be evaluated
	r.funcs = {"w":"w_phase"}
	r.wait = true
	r.vectorize = false
	r.allow_empty = false
	r.read()
	
	#set div to only include the file path up to the location of the piece
	div = path.substr(0, path.find_last("/") + 1)
	
	#create a BoardState for the opening state of the board
	state = BoardState.new(self)
	print(state)

#x_phase() functions are called by the Reader object in ready to initialize the board
#all x_phase functions take in the same arguments I, vec, and file

#_phase is the default phase and defines metadata for the board like mesh and name
#warning-ignore:unused_argument
#warning-ignore:unused_argument
func _phase(var I, var vec:Array, var persist:Array) -> void:
	var key:String = ""
	key = I.update_table(table)

	if key.empty(): return

	if key.match("mesh"):
		if table[key].begins_with("@"):
			table[key] = table[key].substr(1, -1)
		else: table[key] = div + table[key]

#b_phase implicitly defines the mesh and defines the boundaries of the board from sets of 4 numbers
#warning-ignore:unused_argument
#warning-ignore:unused_argument
func b_phase(var I, var vec:Array, var persist:Array) -> void:
	
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
func t_phase(var I, var vec:Array, var persist:Array) -> void:
	#team creation takes in a vector of length 6
	if (vec.size() >= 5):
		#the first three indicate color
		var i = Color(vec[0], vec[1], vec[2])
		#the next two are the forward direction of the team
		var j = Vector2(vec[3], vec[4])
		
		teams.append(Team.new(i, j, teams.size()))
		
	#allow for updates to the team's table after their declaration
	var t:Dictionary = teams.back().table
	I.update_table_line(t)

#the g phase handles implicit team creation and places pieces on the board
#uses persitant to create a "sub-stage" where pieces are placed on the board with symmetry
func g_phase(var I, var vec:Array, var persist:Array) -> void:
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
	
		#cache the paths of valid pieces
		piece_types.append(PieceType.new(self, c))
		#when a piece is assigned, skip the rest of the g phase loop
		return
	
	#if this line has not declared a path, check if it can create a piece
	if vec.size() >= 3 && piece_types.size() > 0:
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
			
#the w phase handles generating winning and losing conditions for different teams
#these instructions only need to be stored, to be later evaluated when necessary
#warning-ignore:unused_argument
#warning-ignore:unused_argument
func w_phase(var I:Instruction, var vec:Array, var persist:Array) -> void:
	win_conditions.append(I)
	
#set piece and return set position from array of length 4
#returns the position interpereted from the input vector
func make_piece(var i:Array, var team:int) -> Vector2:
	
	#ignore arrays that are too small
	if i.size() < 3: 
		print("Board::make_piece() says \"cannot make piece from Array of size ", i.size(), "\"")
		return Vector2.INF
	
	#extract the position from the input vector
	var v = Vector2(i[1], i[2])
	
	#i[0] indicates the Piece's team and i[1] indicates the type
	#also check if they are in range
	if !(team < teams.size() && i[0] < piece_types.size()): return v
	
	#if they are in range, grab the piece from piece_types and update its data accordingly
	var p:Piece = Piece.new(self, piece_types[i[0]], teams, team, v)
	
	#bounce the position back from the piece to accound for px or py overriding the Piece's original position
	v = p.get_pos()
		
	#add the piece to the dictionary
	pieces[v] = p
	teams[team].add(p, v)
	
	return v

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
#if set is false, the resulting marks will not be sent to the marks Dictionary 
#marks are set to a duplicate of the return Dictionary, so the return value can be motified without changing board.marks
func mark(var v:Vector2, var set:bool = true) -> Dictionary:
	
	#do not consider empty positions
	if !(v in pieces):
		return {}
	
	#gain a reference to the piece at v
	var p:Piece = pieces[v]
	
	#gain a reference to that piece's marks
	var m:Array = p.get_mark()
	
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
	
	if set: marks = pos.duplicate()
	
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
		var ignore:bool = line == 1 && !last
		if ignore: 
			continue
		
		#break the loop if search leaves the board and the piece cannot be jumping across it
		if !is_surrounding(square): break
		
		#if the square being checked is occupied, check if the piece can be taken
		var occ:bool = pieces.has(square)
		var take:bool = true
		if occ: 
			#check if the from piece can take the to square
			take = can_take_from(from.get_pos(), square)
			#move type 1 cannot take, type 2 always can
			take = (take || type == 2) && type != 1
			
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
#returns an Array of changes to the board
func execute_turn(var v:Vector2) -> Array:
	
	#reference the piece being moved
	var p:Piece = pieces[get_selected()]
	
	#the piece's mark instructions
	var m:Array = p.get_mark()
	#the index of m that was used to move
	var move:int = marks[v]
	#temporarily update the piece's table with its mark's updates
	var old_tables:Dictionary = {get_selected():p.table.duplicate()}
	
	#increment moves and update the piece's table from the selected mark
	m[move].update_table_line()
	p.table["moves"] += 1
	
	#print(p.table)
	
	#pair the m phase with nothing since marks are not being generated
	var funcs:Dictionary = {"m":"", "t":"t_phase","c":"c_phase","r":"r_phase"}
	var reader:Reader = Reader.new(p, funcs, p.get_p_path(), 3, self)
	reader.wait = true
	reader.read()
	
	#print(p.behaviors)
	
	#convert the piece's behaviors into a set of changes
	#changes contain the piece's behaviors this turn
	var changes:Array = [PoolVector2Array([get_selected(), v])]
	#add changes from the piece
	changes_from_piece(changes, p, v, old_tables)
	changes_from_piece(changes, p, v, old_tables, move)
	
	#print(p.table)
	#print(old_tables)
	
	#move this piece as its primary assumed behavior
	move_piece(get_selected(), v)
	
	#execute the changes
	for i in changes.size():
		var c = changes[i]
		if c is PoolVector2Array:
			move_piece(c[0], c[1])
		elif c is Array:
			make_piece(c, p.get_team())
		elif c is Vector2:
			erase(c)
	
	#clear the marks dictionary and the piece's temporary behaviors so they don't effect future turns
	marks.clear()
	p.behaviors.clear()
	
	#compute win conditions for this turn
	var results := evaluate_win_conditions()
		
	#if any results came back, the game is ending this turn
	#check the results to see who wins and looses and emit the signal to end the game
	if !results.empty():
		for r in results:
			var t = teams[r[0]]
			if r[1] && !winners.has(t): 
				winners.append(t)
			elif !losers.has(t): 
				losers.append(t)
	#otherwise, just increment the turn on the board an move on
	else:
		turn()
	
	#return Board updates
	return changes

#update an Array of changes to the board from an index of a behaviors dictionary
func changes_from_piece(var changes:Array, var piece:Piece, 
	#square containing this move's mark, stored state of pieces being temporarily updated
	#and the index of the move being made in piece's instructions
	var v:Vector2, var old_tables:Dictionary, var idx:int = -1) -> void:
		
	#gain reference to the piece's behaviors
	var behaviors:Dictionary = piece.behaviors
	
	#temporarily change the piece's position
	piece.set_pos(v)
	
	#do not try to execute this method if the index of behaviors is missing or empty
	if !behaviors.has(idx) || behaviors[idx].empty(): 
		return
	
	#iterate through each section of behaviors and convert their data into the changes dictionary
	var bm:Dictionary = behaviors[idx]
	
	#check if one type of behavior is present
	if bm.has("r"): for r in bm["r"].size():
		var from:Vector2 = bm["r"][r][0]
		var to:Vector2 = bm["r"][r][1]
		
		#relocations are pairs of Vector2s, both of which need to be transformed through the piece taking its turn
		to = transform(to, piece)
		from = transform(from, piece)
		var c = PoolVector2Array([from, to])
		
		#copy of from that can change to where the piece is located in pieces
		var shadow_from:Vector2 = from
		
		#if the relocation beginning is empty, do not add any change
		if !has(from): 
			
			#check if from is missing from pieces because of an unsynced update to the pieces tables
			var found := false
			for i in old_tables:
				if pieces[i].get_pos() == from:
					found = true
					shadow_from = i
					break
			
			#if nothing is found, do not add any change because the from square is empty
			if !found: continue
		
		#same if its invalid
		if from == Vector2.INF:
			continue
		
		#if the relocation target is invalid, set the change as a deletion
		if to == Vector2.INF: c = from
		
		#print(c)
		
		#store the current table of the piece being relocated, and update a duplicate of it
		#make sure there is actually a piece here, if not, old_tables will already contain an entry for it because it must have been moved
		if !old_tables.has(shadow_from): 
			old_tables[shadow_from] = pieces[shadow_from].table.duplicate()
		
		#temporarily update the table of the piece being moved
		pieces[shadow_from].set_pos(to)
		
		#add change to Array
		changes.append(c)
	
	if bm.has("c"): for c in bm["c"]:
		#creations are Vector2 and int pairs
		var p_type:int = c[0]
		var pos:Vector2 = Vector2(c[1],c[2])
		pos = transform(pos, piece)
		
		#if the creation fails, do not add any change
		if pos == Vector2.INF: continue
		
		#if the piece type being created is outside of the board's paths, do not add any change
		if p_type > piece_types.size(): continue
		
		changes.append([p_type, pos.x, pos.y])
	
	if bm.has("t"): for d in bm["t"]:
		#destructions are Vector2 and null pairs
		d = transform(d, piece)
		
		#if the destruction fails, do not add any change
		if d == Vector2.INF: continue
		
		changes.append(d)

#vectorize each element in win_conditions and return data on them in the form of an n by 3 Array
#each element of the array contains at its end an index for its source Instruction in win conditions, and contains the following:
# the team it affects, and whether it is a win or loss
func evaluate_win_conditions() -> Array:
	
	#final array to return
	var results:Array = []
	
	#vectorize all of the board's win conditions into data
	for i in win_conditions.size():
		var I:Instruction = win_conditions[i]
		
		#if vectorize() returns an empty array, skip this iteration
		var vec:Array = I.vectorize()
		if vec.empty(): continue
		
		#add this win condition in a default state, marked as non-applicable
		var result:Array = [0, true, i]
		
		#the first element is the team relative to the current team's index that is being affected by this condition
		result[0] = get_team(int(vec[0]))
		
		#the second element (optional) is whether this condition represents a win (0) or a loss (other)
		var win:bool = true
		if vec.size() > 1: win = int(vec[1]) == 0
		result[1] = win
		
		#all subsequent elements are indices of teams whose turns on which these conditions can be executed
		#if there are no extra elements, this condition can be used on any turn
		var apply:bool = true
		if vec.size() > 2: apply = false
		#if any of the extra elements match the current team, this win condition is applicable, and can be added to the final results
		for j in range(2, vec.size()):
			if int(vec[j]) == get_team(): 
				apply = true
				break
				
		#add the result into the final Array
		if apply: results.append(result)
		
	return results

#transform a square using mark step in the jump mode, returning a singular transformed square
func transform(var v:Vector2, var piece:Piece) -> Vector2:
	
	#squares on top of their piece do not need to be transformed
	if v == Vector2.ZERO: return piece.get_pos()
	
	var pos:Dictionary = mark_step(piece, v, 1, 2)
	
	if pos.empty(): return Vector2.INF
	return pos.keys()[0]
	
#move the piece on from onto to
func move_piece(var from:Vector2, var to:Vector2) -> bool:
	#if no piece is in the from square, do not attempt to move from it
	if !pieces.has(from): return false
	
	#if the to square has a piece, destroy it
	var _to_full := erase(to)
	
	#move the piece in both the board's pieces and the correct team's pieces
	pieces[to] = pieces[from]
	var p:Piece = pieces[to]
	teams[p.get_team()].pieces[to] = pieces[to]
	
	#erase handles this synchronization on its own
	erase(from, false)
	
	#update the piece's local position and increment its move count, return a success
	pieces[to].set_pos(to)
	pieces[to].set_last_pos(from)
	return true

#copy a piece into a new piece
func duplicate_piece(var p:Piece) -> Piece:
	var dup := Piece.new(self, p.type)
	dup.table = p.table.duplicate()
	
	return dup

#duplicate the pieces Dictionary and the Pieces inside
func duplicate_all() -> Dictionary:
	var dup := {}
	for v in pieces:
		dup[v] = duplicate_piece(pieces[v])
	
	return dup

#Various getters and setters

#get the team of the current turn by taking turn % teams.size()
func get_team(var offset:int = 0) -> int:
	return (get_turn() + offset) % teams.size()
	
func get_name() -> String:
	return table["name"]
	
func get_mesh() -> String:
	return div + String(table["mesh"])
	
func get_selected(var team:int = get_team()) -> Vector2:
	if team > teams.size(): return Vector2.INF
	return teams[team].get_selected()
	
func set_selected(var select:Vector2 = Vector2.INF, var team:int = get_team()) -> void:
	if team > teams.size(): return
	teams[team].set_selected(select)
	
func get_piece(var v):
	if !pieces.has(v):
		print("Piece not found at key " + v)
		return null
	return pieces[v]
	
func get_turn() -> int:
	return table["turn"]

#increment turn for both the board and the current team
#can also take a number of turns to increment
func turn(var n:int = 1) -> void:
	teams[get_team()].table["turn"] += n
	table["turn"] += n

#pieces Dictionary interfaces and mutators has, erase, and clear
func has(var v:Vector2) -> bool:
	return pieces.has(v)

#erase also serves the same purpose as an old destroy_piece method
#free can be set to false to keep the piece at v in memory after the erasure
#free needs to be called manually because pieces are not nodes in the node tree, and so will leak if not freed
func erase(var v:Vector2, var free:bool = true) -> bool:
	#if the piece is present, gain reference to it to reference its team
	if !pieces.has(v): return false
	
	var p:Piece = pieces[v]
	
	#then erase the piece in every correct dictionary
	pieces.erase(v)
	var b:bool = teams[p.get_team()].erase(v)
	
	#free the piece from memory
	if free: p.free()
	
	#this can still fail if the piece is not present in the team's dictionary
	#so return the result of the last erasure
	return b

func clear(var free:bool = true) -> void:
	if free: for v in pieces: pieces[v].free()
	pieces.clear()

#print the board as a 2D matrix of squares, denoting pieces by the first character in their name
func _to_string():
	
	var s:String = get_name()
	s += "\n["
	#convert team array to string
	for i in teams.size(): 
		s += String(i) + ": (" + String(teams[i].get_color()) + ")"
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
				#"#" signifies an out-of-bounds spot
				else:
					s += "#"
			s += " "
		s += "\n"
		i -= 1
		
	s += String(table)
	return s
