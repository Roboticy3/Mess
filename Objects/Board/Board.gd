class_name Board
extends Node

#Board object made by Pablo Ibarz
#created in November 2021

#Board is the internal state of a game board. Should be an orphan Node interfaced by other Nodes through BoardMesh

### SOLID DATA
#These variables should not change after initialization

#instruction path to the board
var path:String = ""

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

### LIQUID DATA
#These variables will change all the time

#store pieces at their initial locations
#the states making up each turn of the board
var states:Array 

#store a set of variables declared in metadata phase
var table:Dictionary = {"scale":1, "opacity":0.6, "collision":1, 
	"piece_scale":0.2, "piece_opacity":1, "piece_collision":1,
	"name":"*name*","mesh":"Instructions/default/meshes/default.obj",
	"turn":0, "pi":PI}

#a Vector2 Dictionary of Arrays describing the selectable marks on the board.
var marks:Dictionary = {}

#Vector2 Dictionary of the pieces in the current turn
var current:Dictionary = {}
var current_turn := 0

#overrides get_team()'s return value if set to a positive integer, locking the effective team
var lock:int = -1

#set to false to not update the pieces dictionaries of each team
var synchronize := true

### GENERATORS
#create a board from a b_*.txt file
#x_phase() functions are called by the Reader object in ready to initialize the board
#all x_phase functions take in the same arguments I, vec, and file

#set the path and create the board
func _init(var _path:String):
	path = _path
	_ready()

#ready will rarely be called automatically since Boards are usually orphan Nodes
func _ready():
	#create a BoardState for the opening state of the board
	states = [BoardState.new(self)]
	
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
	
	#fill initial possibilities for piece objects
	project_states()

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
		
		var t := Team.new(self, i, j, teams.size())
		teams.append(t)
		
	
	else:
		#allow for updates to the team's table after their declaration
		var t:Dictionary = teams.back().table
		I.update_table_line(t)

#the g phase handles implicit team creation and places pieces on the board
#uses persitant to create a "sub-stage" where pieces are placed on the board with symmetry
func g_phase(var I, var vec:Array, var persist:Array) -> void:
	#if there are no teams from the t phase, implicitly create black and white teams
	if teams.empty():
		teams.append(Team.new(self))
		teams[0].set_name("white")
		teams.append(Team.new(self, Color.black, Vector2.UP))
		teams[1].set_name("black")
	
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
		var pos = make_piece(vec, persist[0], true)
			
		#symmetrize piece if symmetry is enabled
		if persist[1] != 0 && persist[1] != null:
			pos = -pos + 2*(center)
			vec[1] = pos.x
			vec[2] = pos.y
			make_piece(vec, persist[0] + 1, true)
			
#the w phase handles generating winning and losing conditions for different teams
#these instructions only need to be stored, to be later evaluated when necessary
#warning-ignore:unused_argument
#warning-ignore:unused_argument
func w_phase(var I:Instruction, var vec:Array, var persist:Array) -> void:
	win_conditions.append(I)

#create a boundary object from a vector of length 4
func set_bound(var i:Array):
	if i.size() < 4: return null
	var p = Vector2(i[0], i[1])
	var q = Vector2(i[2], i[3])
	return Bound.new(p, q)

### TILE QUERIES
#Produce data about the board as it pertains to a square in tile space

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

func can_take_piece(var from:Piece, var to:Piece) -> bool:
	
	if from == null: return false
	if to == null || to.updates: return true
	
	if from.get_team() == -1: return false
	
	if from.get_team() != to.get_team() || from.get_ff(): return true
	return false

#transform a square using mark step in the jump mode, returning a singular transformed square
func transform(var v:Vector2, var piece:Piece) -> Vector2:
	
	#squares on top of their piece do not need to be transformed
	if v == Vector2.ZERO: return piece.get_pos()
	
	var pos:Dictionary = mark_step(piece, v, 1, 2)
	
	if pos.empty(): return Vector2.INF
	return pos.keys()[0]

### MARKS
#Get squares that the player should know about

#generate marks for a piece as a PoolVector2Array from its position on the board
#if set is false, the resulting marks will not be sent to the marks Dictionary 
#marks are set to a duplicate of the return Dictionary, so the return value can be motified without changing board.marks
func mark(var v:Vector2, var set:bool = true) -> Dictionary:
	
	#gain a reference to the piece at v
	var p = get_piece(v)
	
	#do not consider missing pieces
	if p == null:
		return {}
	
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
	
	#keep track of the time this function takes to execute
	var t := OS.get_ticks_usec()
	
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
		var p = get_piece(square)
		var occ:bool = p != null
		var take:bool = true
		if occ: 
			#check if the from piece can take the to square
			take = can_take_piece(from, p)
			#move type 1 cannot take, type 2 always can
			take = (take || type == 2) && type != 1
			
			#if piece cannot be taken, break the loop before adding the next mark
			if !take:
				break
		
		#add instruction index to a new position in s, first in overrides newer marks
		if !s.has(square): s[square] = i
		
		#if square is occupied by a takeable piece, break after adding the square
		if occ && take: 
			break
			
	#send the execution time to debugger
	if Accessor.debug[1] != null:
		Accessor.debug[1].append(OS.get_ticks_usec() - t)
		
	return s

#generate marks from a piece's possible BoardStates
func super_mark(var v:Vector2, var set:bool = true) -> Dictionary:
	
	var p = get_piece(v)
	
	if p == null:
		return {}
	
	if set: marks = p.possible
	return p.possible

### APPLY TURNS
#Mutate the states array and possible state tree

#execute a turn by creating a new BoardState and adding it to the states Array
#returns an Array of changes to the board
#mode is a bitmask
# bit 0 - append, set to 1 to append the state generated in this method to states
# bit 1 - turn, set to 1 to pass to the next turn
# bit 2 - clear, set to 1 to clear the marks dictionary after the end of the method
# bit 3 - reread, set to 1 to reread the moved piece's instruction file
func execute_turn(var v:Vector2, var _marks := {},
	var mode := 7) -> BoardState:
	
	#if marks have not been inputted, use board.marks
	if _marks.empty(): _marks = marks
	
	var state = BoardState.new(self)
	
	#the index of m that was used to move, assert that it exists before continuing
	if !_marks.has(v):
		print("Board::execute_turn() says: \"no mark at square " + String(v) + "\"")
		return state
	var move:int = _marks[v]
	
	#reference the piece being moved
	var f = get_piece(get_selected())
	
	#if p is null, no piece can have behaviors or marks extracted
	#this should never happen, but just to be safe, this case will return no changes and not add any board states or pass any turns
	if f == null:
		print("Board::execute_turn() says: \"no piece at square " + String(v) + "\"")
		return state
		
	#add the new state to the states array
	states.append(state)
	
	#duplicate the target piece to avoid mofidying and older version of it
	var p:Piece = duplicate_piece(f)
	#the piece's mark instructions
	var m:Array = p.get_mark()
	
	#reference the last BoardState
	#var last:BoardState = states[get_turn()]
	
	#increment moves and update the piece's table from the selected mark
	m[move].table = p.table
	m[move].update_table_line()
	p.table["moves"] += 1
	
	#print(p.table)
	
	#add the base move to the front of p's behaviors
	p.behaviors = [[-1, 2, get_selected(), v]]
	#if reread is set to true, read out the piece instruction file to reload it's PieceType
	if bool((mode >> 3) % 2): 
		var funcs:Dictionary = {"m":"m_phase","t":"t_phase","c":"c_phase","r":"r_phase"}
		var r := Reader.new(p.type, funcs, p.type.path, 3, self, true)
		r.read()
	#fill the piece's behaviors from its stored instructions
	p.fill_behaviors()
	
	#print(p.behaviors)
	
	#convert the piece's behaviors into a set of changes
	#changes contain the piece's behaviors this turn
	#add changes from the piece and make changes to the board
	execute_behaviors(p, move, [0])
	
	#print(p.table)
	
	#piece's temporary behaviors so they don't effect future turns
	p.behaviors.clear()
	
	#compute win conditions for this turn
	var results := evaluate_win_conditions(state)
	
	#unpack the mode bitmask into booleans
	
	#if this turn is not being applied, do not increment turn or check the results
	if !bool(mode % 2):
		#also remove this state from the states array
		states.remove(get_turn() + 1)
		
	#if any results came back, the game is ending this turn
	#check the results to see who wins and looses and emit the signal to end the game
	#only do this if state is being appended as the current state
	elif !results.empty() && synchronize:
		lock = get_team()
	
	#print(state)
	#print(self)
	#print(teams[get_team()])
	
	#extract the clear and turn bits from mode and check them before clearing marks and incrementing turn
	if bool((mode >> 2) % 2): marks.clear()
	if bool((mode >> 1) % 2): table["turn"] += 1
	
	#if synchronize is enabled, update current_turn
	if synchronize:
		current_turn = get_turn()
	
	#return Board updates
	return state

#update an Array of changes to the board from a piece using its behaviors Array
func execute_behaviors(var piece:Piece, 
	#and the index of the move being made in piece's instructions
	#transformed is an array of indices in piece.behaviors that have already been transformed
	var idx:int = -1, var transformed:Array = []) -> void:
	
	var behaviors:Array = piece.behaviors
	
	
	#loop through each behavior
	for i in behaviors.size():
		var b:Array = behaviors[i]
		var m:int = b[0]
		
		#if the behavior doesn't apply to the input mark index or default mark index, skip it
		if m != -1 && m != idx:
			continue
		
		var t:int = b[1]
		#if this behavior has been marked as transformed, flag this iteration
		var transform = !transformed.has(i)
		
		match t:
			0:
				var d:Vector2 = b[2]
				if transform: d = transform(d, piece)
				erase(d)
			
			1:
				#creations are Vector2 and int pairs
				var a:Array = b[2]
				var p_type:int = a[0]
				var pos := Vector2(a[1],a[2])
				if transform: pos = transform(pos, piece)
				
				#if the creation fails, do not add any change
				if pos == Vector2.INF: continue
				
				a[1] = pos.x
				a[2] = pos.y
				
				#if the piece type being created is outside of the board's paths, do not add any change
				if p_type > piece_types.size(): continue
				
				make_piece(a, get_team())
			
			2:
				var from:Vector2 = b[2]
				var to:Vector2 = b[3]
				
				#relocations are pairs of Vector2s, both of which need to be transformed through the piece taking its turn
				if transform:
					to = transform(to, piece)
					from = transform(from, piece)
				
				#check if the piece being relocated needs to be refetched
				var p:Piece = piece
				var f:Piece = get_piece(from)
				if from != piece.get_pos():
					p = duplicate_piece(f)
				
				if from == Vector2.INF || to == Vector2.INF: continue
			
				#add change to Array
				move_piece(from,to,p,f,false)

#vectorize each element in win_conditions and return data on them in the form of an n by 3 Array
#each element of the array contains at its end an index for its source Instruction in win conditions, and contains the following:
# the team it affects, and whether it is a win or loss
#also updates the winners and losers of an input BoardState
func evaluate_win_conditions(var state:BoardState) -> Array:
	
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
	
	#apply the win conditions to the winners and losers of the input state
	for r in results:
		#print(r)
		var t = teams[r[0]]
		if r[1] && !state.winners.has(t): 
			state.winners.append(t)
		elif !state.losers.has(t): 
			state.losers.append(t)
	
	return results

#build all possible BoardStates for this turn
#send these states to the array of possible states in the current turn
#depth param can be set for any amount of turns to check, creating a tree of possible states
#locked param for whether turns are locked during this period
func project_states(var depth := 1, var locked := false):
	
	if depth <= 0: return []
	
	if locked: lock = true
	
	#get all the pieces from the last turn in the current team
	var pieces:Dictionary = get_pieces()
	
	#loop through all pieces, filtering out those on other teams
	for v in pieces:
		if pieces[v].get_team() != get_team(): continue
		
		#clear the old possibilities in place of new ones
		pieces[v].possible.clear()
		#then project in the new possible states
		project_states_from_piece(v, pieces[v].possible, depth)
	
	if locked: lock = false
	
	marks.clear()
	set_selected()

#build all possible BoardStates for the next turn from a single piece given from a position
#use depth argument to call recursively with project_states()
func project_states_from_piece(var v:Vector2, var s := {},
	var depth := 1) -> void:
	
	#mark their moves without setting the marks to board.marks
	#var t := OS.get_ticks_usec()
	var m := mark(v, false)
	if m.empty(): return
	
	#set the selected piece for these projected state
	set_selected(v)
	#print("mark ", String(v), ": ", OS.get_ticks_usec() - t)
	
	#remember the current turn to revert back to
	var t:int = get_turn()
	
	synchronize = false
	
	for i in m:
		#var _t := OS.get_ticks_usec()
		
		#progress a turn to be reverted later
		var state := execute_turn(i, m)
		#if depth is high enough, call project states recursively from this point
		project_states(depth - 1)
		
		#revert the turn
		revert(t)
		
		s[i] = state
		#print("exec ", String(i), ": ", OS.get_ticks_usec() - _t)
	
	synchronize = true

#revert the board to a turn, reverse of execute_turn()
func revert(var turn:int = get_turn() - 1) -> void:
	
	#don't do anything if no info is had on the turn
	if turn > get_turn() || turn < 0:
		return
	
	#set the turn of the board and team
	table["turn"] = turn
	#trim states to the right size
	states = states.slice(0, turn)
	
	#reinitialize current if Board is reverting from a synchronized turn
	if synchronize: 
		current = get_pieces()
		current_turn = turn

#add a new state onto the board
func append(var state:BoardState) -> void:
	
	if synchronize: teams[get_team()].table["turn"] += 1
	table["turn"] += 1
	
	states.append(state)
	
	if synchronize:
		current = get_pieces()
		current_turn += 1

### BOARD GETTERS
#Budget private interaction with table

#get the team of the current turn by taking turn % teams.size()
func get_team(var offset:int = 0) -> int:
	if lock > -1: return (lock + offset) % teams.size()
	return (get_turn() + offset) % teams.size()
	
func get_name() -> String:
	return table["name"]
	
func get_mesh() -> String:
	return div + String(table["mesh"])
	
func get_selected(var team:int = get_team()) -> Vector2:
	if team > teams.size(): return Vector2.INF
	return teams[team].get_selected()
	
func set_selected(var select := Vector2.INF, var team := get_team(), 
	var force := true) -> bool:
	
	if team > teams.size(): return false
	return teams[team].set_selected(select, force)
	
func get_turn() -> int:
	return table["turn"]
	
func get_winners() -> Array:
	return states[get_turn()].winners

func get_losers() -> Array:
	return states[get_turn()].losers

func get_lock() -> int:
	return lock

###PIECE GETTERS
#Searches through the states array to produce data on pieces

#pieces Dictionary interfaces and mutators has, erase, and clear
#minimum complexity! :)
func get_piece(var v:Vector2):
	
	var i := states.size() - 1
	while i >= current_turn:
		var s:BoardState = states[i]
		var ps:Dictionary = s.pieces
		
		if ps.has(v):
			var p = ps[v]
			if p.updates: return null
			return p
		
		i -= 1
	
	if current.has(v):
		return current[v]
	
	return null

func has(var v:Vector2) -> bool:
	
	var i := find(v)
	if i == -1 || states[i].pieces[v].updates:
		return false
	return true

#find a piece and return its index in states
func find(var v:Vector2) -> int:
	var i:int = states.size() - 1
	while i > -1:
		
		var s:BoardState = states[i]
		var ps:Dictionary = s.pieces
		
		if ps.has(v):
			return i
		
		i -= 1
	
	return -1
	
#return every square that has a piece
#offset controls how many states away from the state at get_turn() will be considered
#team can be set higher than -1 to filter pieces from a specific team
func get_pieces() -> Dictionary:

	var pieces:Dictionary = current.duplicate()

	for i in range(current_turn, get_turn()):
		
		#for all the pieces in this state
		var ps:Dictionary = states[i].pieces
		for v in ps:
			
			pieces[v] = ps[v]
			
			#remove flagged pieces when they are found
			if ps[v].updates:
				pieces.erase(v)
			
	return pieces

#copy a piece into a new piece
func duplicate_piece(var p:Piece) -> Piece:
	var dup := Piece.new(self, p.type)
	dup.table = p.table.duplicate()
	#duplicate pieces refer to the original copy as their last piece
	dup.last = p
	
	return dup

###PIECE SETTERS
#these functions change the pieces Dictionary of the current latest state

#move the piece on from onto to
#optionally provide duplicate piece p in advance
#set safe to false to skip checks
func move_piece(var from:Vector2, var to:Vector2, var p:Piece = null,
	var f:Piece = null, var safe:bool = true) -> bool:
	
	#if no piece is in the from square, do not attempt to move from it
	if f == null:
		f = get_piece(from)
	if f == null:
		return false
	
	#check if to is out of bounds, if so, just destroy from
	if safe && !is_surrounding(to):
		erase_piece(f)
		return true
		
	#duplicate the piece to avoid changing earlier states
	if p == null: p = duplicate_piece(f)
	#second duplicate for erased piece
	var f2 := duplicate_piece(f)
	
	#update the piece and board state with this movement
	states[get_turn() + 1].pieces[to] = p
	#remove the old version of the piece by flagging the duplicate in the new turn
	f2.updates = true
	states[get_turn() + 1].pieces[from] = f2
	
	#update the piece's local position and increment its move count, return a success
	p.set_pos(to)
	p.set_last_pos(from)
	
	#if synchronize is on, erase_piece() will have erased the old piece
	#the new piece must then also be added to current
	if synchronize: 
		current.erase(from)
		current[to] = p
	
	return true

#set piece and return set position from array of length 4
#returns the position interpereted from the input vector
#the part which updates states can refer to nonexistent state and crash, so it can be disabled with the update_state bool
func make_piece(var i:Array, var team:int, var init:bool = false) -> Vector2:
	
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
		
	#add the piece to the correct team's dictionary
	if synchronize: 
		current[v] = p
		var sk = teams[p.get_team()].start_keys
		for k in p.table:
			if !sk.has(k): sk.append(k)
	
	if init:
		states[0].pieces[v] = p
	else:
		states[get_turn() + 1].pieces[v] = p
	
	return v

#erase also serves the same purpose as an old destroy_piece method
#free can be set to false to keep the piece at v in memory after the erasure
#free needs to be called manually because pieces are not nodes in the node tree, and so will leak if not freed
func erase(var v:Vector2) -> bool:
	#if the piece is present, gain reference to it to reference its team
	var p = get_piece(v)
	if p == null:
		return false
	
	return erase_piece(p)

#erase doesn't need to search for a piece if the calling method already has it
func erase_piece(var p:Piece, var duplicate:Piece = null) -> bool:
	#then erase the piece in every correct dictionary
	var b:bool = false
	if synchronize: b = current.erase(p.get_pos())
	
	if duplicate == null:
		duplicate = duplicate_piece(p)
	
	#flag this piece as updated to make it appear deleted
	duplicate.updates = true
	#add the flagged piece to the new state
	states[get_turn() + 1].pieces[duplicate.get_pos()] = duplicate
	
	#this can still fail if the piece is not present in the team's dictionary
	#so return the result of the last erasure
	return b

func clear(var free:bool = true) -> void:
	for s in states:
		s.clear(free)

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
	for i in range(minimum.y, maximum.y + 1):
		for j in range(minimum.x, maximum.x + 1):
			
			var v = Vector2(j, i)
			#"#" signifies an out-of-bounds spot
			if !is_surrounding(v):
				s += "#"
				continue
				
			#check if square contains a piece
			var p = get_piece(v)
			if p != null:
				#add the letter to the string and the used letters array
				s += p.get_name()[0]
			else:
				#"." signifies a blank spot inside the board
				s += "."
			s += " "
		s += "\n"
		
	s += String(table)
	return s
