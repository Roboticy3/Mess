class_name Instruction

#Instruction class by Pablo Ibarz
#created November 2021

#An Instruction takes in a single line string (no \n characters) and converts it into an array of numbers
#Instantiated usually by the Reader class to belong to a Board or Piece
#It also holds table and pieces Dictionaries of variables and pieces

#the string contents read literally from a source text file by Reader
var contents = ""
#the formatted string array formed from contents
var wrds:Array = []
#the starting index of the last vectorize() call, allows other objects to read wrds from this index
#can also be set to override the default starting index of 0
var last_start:int = 0

#table of piece/board properties and pieces on the board, referenced from a Board and/or a Piece object
#table is used to read and write variables to the user Object
var table:Dictionary = {}
#board is used to transform vectors
var board

#set to true if this Instruction is working with squares on the board
#automatically set to true if board is not null in init()
var reads_board:bool = false

#the set of valid comparison characters, contains <=, >=, <, >, and ==
const SYMBL : String = ">=<=!="

#fill variables of the object fully
func _init(var _contents:String="", var _table:Dictionary={}, var _board = null):
	
	contents = _contents.strip_edges()
	table = _table
	
	#if the board is being sent into the instruction for reference, then it is probably reading the board
	if _board != null: reads_board = true
	board = _board
	
	#format contents into wrds
	format()
	
#format a string into the wrds Array, optionally pull a table from another piece on the board
func format(var start:int = 0, var length:int = -1, var square = null) -> void:
	
	#if wrds is empty, construct it from contents
	wrds = to_string_array()
	
	#if length is -1, set it to the length of the array - start
	if length == -1: length = wrds.size() - start
	#otherwise, fit length to wrds
	else: length = min(wrds.size() - start, length)
	
	#take table from another square if a square is specified
	if reads_board && board.has(square):
		table = board.get_piece(square).table
		
	#sort table by key size, helps string replacement prioritize larger words
	var keys:Array = table.keys()
	var sort:StringSort = StringSort.new()
	keys.sort_custom(sort, "sort")

	#replace terms in table key set with their value pairs
	for i in range(start, start + length):
		#don't try to work outside of the range of wrds
		if i > wrds.size(): break
		
		var w:String = wrds[i]
		#remove white space
		w = w.strip_edges()
		
		for v in keys:
			w = w.replace(v, String(table[v]))
			
		#send the formatted string back into wrds
		wrds[i] = w
		
#Object for sorting the table in format()
class StringSort:
	#sort elements by length
	func sort(var a:String, var b:String) -> bool:
		if a.length() < b.length():
			return true
		return false

#WIP evaluate conditional statements, made up of a wrds Array of length 3 or more that can solve inequalities
#returning [] is equivalent to returning false and anything else is equivalent to true
func vectorize(var start:int = 0) -> Array:
	
	#reformat content to catch table updates
	format()
	
	#slice from start
	var w:Array = wrds.slice(start, wrds.size() - 1)
	
	#final return statements sent start back to s
	#only try to work with non-empty arrays
	if w.empty():
		last_start = start
		return []
	#if input is not a conditional, return parsed array
	if !w[0].begins_with("?"):
		last_start = start
		return array_parse(start)
	#the minimum conditional size is 2, and then something after that to actually return if the conditional evaluates to true
	if w.size() < 3:
		last_start = start
		return []
		
	#remove question mark from wrds[0] once it is confirmed of valid size and format
	w[0] = w[0].substr(1)
	
	#check for a shebang to invert the conditional
	var negate:bool = false
	if w[0].begins_with("!"):
		negate = true
		w[0] = w[0].substr(1)
	
	#if next word is a conditional, the conditional consists of a simple comparison
	if w.size() > 3 && SYMBL.find(w[1]) != -1:
		#print(w,table)
		var e:bool = evaluate(w)
		if negate: e = !e
		if e:
			return vectorize(start + 3)
		#if the conditional fails, return nothing
		return []
	
	#if the table does not indicate this instruction is for an object with position on the board, return nothing now
	#otherwise, continue on to check if the conditional is asking for a square relative to this object's position
	if !table.has("px") || !table.has("py"): return []
	
	#otherwise, see if the 4th word is a comparator
	#no comparator means a square is being checked for presence
	#4th meams another piece's table is being 
	var length:int = 2
	if SYMBL.find(w[3]) != -1: 
		length = 5
	
	#if the statement is too short for the position, return an empty array
	if w.size() <= length: return []
	
	#read the square being looked at by this instruction
	var u = parse(w[0])
	var v = parse(w[1])
	
	#form square to check from this Instruction's Piece's position, direction, and vector from u and v
	var x:Vector2 = Vector2(table["px"], table["py"])
	var y:Vector2 = board.transform(Vector2(u, v), board.get_piece(x))
	
	#check if the square is empty, if so treat as false when asking for a square or its pieces property
	#this can still be negated
	if !board.has(y):
		if negate: return vectorize(start + length)
		return []
	
	#if a square was being checked for presence, vectorize from the end of that square
	#or.. yknow.. negate it
	if length == 2:
		if negate: return []
		return vectorize(start + 2)
		
	#if a square was being checked for its piece's property, 
	#evaluate it against the other end of the comparator
	if length == 5:
		#format the one term on the left of the comparator to use the table of the piece being checked against
		format(start + 2, 1, y)#reinitialize w to use the reformatted wrds Array
		w = wrds.slice(start, wrds.size() - 1)
		#evaluate the comparison
		var e:bool = evaluate(w, 2)
		if negate: e = !e
		if e:
			return vectorize(start + 5)
	
	#if all else fails, return an empty Array
	return []
			
func array_parse(var start:int = 0):
	var w:Array = wrds.slice(start, wrds.size() - 1)
	
	#create return object
	var nums = Array()
	
	#check each word in the line and parse it into a float
	for i in w.size():
		#if there is a conditional in a later index of wrds, 
		#call vectorize starting at that point and append the result to nums, then break the loop
		if w[i].begins_with("?"):
			nums.append_array(vectorize(start + i))
			break
		var n = parse(w[i])
		nums.append(n)
		
	#return the array
	return nums

#evaluate conditional of a slice of an array of strings of length 3
func evaluate(var w:Array = [], var start:int = 0):
	#remove unnecesary component of the array
	w = w.slice(start, start + 2)
	
	#create an array of values to store integers or calls to table
	var a = Array()
	for s in w:
		a.append(parse(s))
	
	var sgn:String = w[1]
	
	#if conditional is in the right format and has valid variable calls, evaluate it
	if (SYMBL.find(sgn) != -1):
		#check for the conditional symbol
		if sgn.ends_with("="):
			if (sgn.begins_with("<") && a[0] <= a[2]):
				return true
			elif (sgn.begins_with("<") && a[0] >= a[2]):
				return true
			elif (sgn.begins_with("!") && a[0] != a[2]):
				return true
			elif a[0] == a[2]:
				return true
		elif (sgn == ">" && a[0] > a[2]):
			return true
		elif (sgn == "<" && a[0] < a[2]):
			return true
		
	return false

#convert a single word string (no " " or "\n" characters) into a float using the Expression class
#nullable bool allows for failed parses to return null instead of 0.0
func parse(var string=contents, var nullable:bool = false):

	#create Expression to parse off of
	var expression = Expression.new()
	
	#use parse method and then execute method
	var err:int = expression.parse(string)
	#if the parse fails, default to 0
	if err > 0:
		if nullable: return null
		return 0.0
	
	#I assume parse breaks up the string into numbers and operators, and execute takes those and does the computation
	#Fill in the first two arguments with their default values to reach "p_show_error" and set it to false to clean up the debugger
	#errors in this method will simply make has_execute_failed() return true, which is an intended possibility
	var n = expression.execute(Array(), null, false)
	#if the execute failed, n will be null
	if expression.has_execute_failed():
		#never return null unless user asks for it so other code doesn't have to type-check the result
		if nullable: return null
		return 0.0
	
	return n

#convert instruction text to string array of words for easier parsing
func to_string_array(var c:String = contents, var start:int = 0) -> Array:

	#cut spaces so that spaces between final whitespace is not counted
	c = c.substr(0, c.find("#")).strip_edges()
	
	#keep array of invalid words and array of words to return
	var r:PoolIntArray = []
	var a:Array = c.split(" ")
	#"clean" elements by removing spaces left over from split() and catching empty entries
	for i in a.size():
		a[i] = a[i].strip_edges()
		if a[i].length() == 0:
			r.append(i)
	#remove empty entries
	for i in r.size():
		a.remove(r[i] - i)
		
	#use start to slice array and return it
	return a.slice(start, a.size() - 1)
	
#returns true if the formatted wrds array is the same as the contents array at index i
func is_unformatted(var i:int = 0, var start:int = last_start) -> bool:
	i += start
	
	if i >= wrds.size(): return false
	
	var c:Array = to_string_array()
	#if i fits in wrds, it should fit in c, 
	#but contents can be changed between format calls, desyncronizing them
	if i >= c.size(): return false

	#check if wrds[i] does not match the i'th word of contents because of formatting
	if wrds[i].match(c[i]):
		return true
	return false

#take in a table to update with self, returns true on success
func update_table(var t:Dictionary=table, var start:int = 0,
	var s:Array = []) -> String:
	
	#make sure there is a set of unformatted words to work with
	if s.empty(): s = to_string_array(contents, start)
	#duplicate the input array to not mutate the original
	else: s = s.duplicate().slice(start, -1)
	
	#check if last two terms in array make up a key pair
	if s.size() > 1:
		var i:int = s.size() - 2
		var j:int = s.size() - 1
		#try to parse values
		var n = [parse(s[i], true), parse(s[j], true)]
		#keys must be strings, but values can be floats or strings
		if n[0] == null:
			if n[1] == null: t[s[i]] = s[j]
			else: t[s[i]] = n[1]
			return s[i]
	return ""

#do all the table updates in a given line
func update_table_line(var t:Dictionary = table) -> void:
	
	var s = to_string_array()
	var i = s.size() - 2
	
	while i > 0:
		var try:String = update_table(t, i, s)
		if try.empty(): 
			break
		i -= 2

#copy of Piece.transform that does not require a reference to a Piece object
func piece_transform(var v:Vector2, var forward:Vector2, var angle:float) -> Vector2:
	var d:Vector2 = v.rotated(angle) * forward.length()
	return d.round()

func _to_string():
	return contents
