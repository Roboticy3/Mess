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

#set to false if this Instruction is only being fed "clean" lines with no comments or surrounding white space
var cut_comments := true

#the set of valid comparison characters, contains <=, >=, <, >, and ==
const SYMBL : String = ">=<=!="

#initialize this Instruction object with proper formatting regardless of inputs
func _init(var _contents:String="", var _table:Dictionary={}, var _board = null,
	var _cut_comments:bool = true):
	
	contents = _contents
	table = _table
	
	cut_comments = _cut_comments
	
	#if the board is being sent into the instruction for reference, then it is probably reading the board
	if _board != null: reads_board = true
	board = _board
	
	#format contents into wrds
	format()
	
#format a string into the wrds Array, optionally pull a table from another piece on the board
#	it is not recommended to use first and then set start and length as well, as this will unformat parts of wrds without reformatting them
#start and length can specify a slice of wrds to format, length of -1 will format until the end of wrds
#t is the table variables will be formatted with, set to this Instruction's table by default, but can also take other tables and even Team objects
func format(var start:int = 0, var length:int = -1, var t = table) -> void:
	
	#if wrds is empty reconstruct wrds from contents
	var s = to_string_array()
	if wrds.empty(): wrds = s
	
	#if length is -1, set it to the length of the array - start
	if length == -1: length = wrds.size() - start
	#otherwise, fit length to wrds
	else: length = min(wrds.size() - start, length)
	
	#sort table by key size, helps string replacement prioritize larger words
	var keys:Array = t.keys()
	var sort:StringSort = StringSort.new()
	keys.sort_custom(sort, "sort")

	#replace terms in table key set with their value pairs
	for i in range(start, start + length):
		#unformat the current word
		wrds[i] = s[i]
		
		#don't try to work outside of the range of wrds
		if i > wrds.size(): break
		
		var w:String = wrds[i]
		#remove white space
		w = w.strip_edges()
		
		for v in keys:
			var new_w := w.replace(v, String(t.get(v)))
			w = new_w
			
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
func vectorize(var start:int = 0, 
	var allow_conditionals:bool = true, var nullable:bool = false) -> Array:
	
	#reformat content to catch table updates
	format()
	
	#slice wrds from start
	var w:Array = wrds.slice(start, wrds.size() - 1)
	
	#final return statements sent start back to s
	#only try to work with non-empty arrays
	if w.empty():
		last_start = start
		return []
	#if input is not a conditional, return parsed array
	if !w[0].begins_with("?"):
		last_start = start
		return array_parse(start, allow_conditionals, nullable)
	#if conditionals are not allowed at this point, return an empty array
	if !allow_conditionals:
		return []
	#the minimum conditional size is 2, and then something after that to actually return if the conditional evaluates to true
	if w.size() < 3:
		last_start = start
		return []
	
	#remove question mark from wrds[0] once it is confirmed of valid size and format for a conditional
	w[0] = w[0].substr(1)
	
	#check for a shebang to invert the conditional
	var negate:bool = false
	if w[0].begins_with("!"):
		negate = true
		w[0] = w[0].substr(1)
	
	#if there are enough words for a simple conditional, and the next word is a conditional, 
	#the conditional consists of a simple comparison
	if w.size() > 3 && SYMBL.find(w[1]) != -1:
		#print(w,table)
		var e:bool = evaluate(w)
		if negate: e = !e
		if e:
			return vectorize(start + 3)
		#if the conditional fails, return nothing
		return []
		
	#if the board is not being read, do not try to evaluate any special conditional types
	if !reads_board:
		return []
		
	#read the first word into a number
	var u = parse(w[0])
		
	#if there are enough words for a team conditional, and the third word is a conditional,
	#the conditional consists of a comparison on a team's value
	if w.size() > 4 && SYMBL.find(w[2]) != -1:

		#get the team from the first word as an offset from the current team
		var team = board.teams[board.get_team(int(u))]

		#try and format it using the team... *as* a table? sure
		format(1, 1, team)
		w = wrds.slice(start, -1)
		
		#evaluate that shit
		var e:bool = evaluate(w, 1)
		if negate: e = !e
		
		if e:
			return vectorize(start + 4)
		else:
			return []
	
	#read the second word to pair with u and make a square to do conditionals with
	var v:float = parse(w[1])
	
	#form square to check from this Instruction's Piece's position, direction, and vector from u and v
	var y:Vector2 = Vector2(u, v)
	
	#transform y into the right square through a transformation about the piece at this table's position
	#only do so if this table has positional data, otherwise y will remain as read
	if table.has("px") && table.has("py"):
		var x:Vector2 = Vector2(table["px"], table["py"])
		y = board.transform(y, board.get_piece(x))
	
	#check if the board has a piece at y
	var has:bool = board.has(y)
	
	#if there are enough words for a relative conditional, and the 4th word is a conditional,
	#the conditional consists of a conditional based on another square's property
	if w.size() > 5 && SYMBL.find(w[3]) != -1:
		
		#check if the square is empty, if so treat conditional as false when asking for a square or its pieces property
		#this can still be negated
		if !has:
			if negate: return vectorize(start + 5)
			return []
		
		#reinitialize w to use the new table
		format(start + 2, 1, board.get_piece(y).table)
		w = wrds.slice(start, wrds.size() - 1)
		
		#evaluate the comparison
		var e:bool = evaluate(w, 2)
		if negate: e = !e
		
		if e:
			return vectorize(start + 5)
		else:
			return []
	
	#if the conditional is long enough to check for a square's presence, there does not need to be a comparator
	if wrds.size() > 2:
		if (has && !negate) || (!has && negate):
			return vectorize(start + 2)
		else:
			return []
		
	
	#if all else fails, return an empty Array
	return []
			
func array_parse(var start:int = 0, 
	var allow_conditionals:bool = true, var nullable:bool = false):
	
	var w:Array = wrds.slice(start, wrds.size() - 1)
	
	#create return object
	var nums = Array()
	
	#check each word in the line and parse it into a float
	for i in w.size():
		#if there is a conditional in a later index of wrds, 
		#call vectorize starting at that point and append the result to nums, then break the loop
		if w[i].begins_with("?") && allow_conditionals:
			nums.append_array(vectorize(start + i))
			break
		var n = parse(w[i], nullable)
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
		elif (sgn.match(">") && a[0] > a[2]):
			return true
		elif (sgn.match("<") && a[0] < a[2]):
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
	if cut_comments: c = c.substr(0, c.find("#")).strip_edges()
	
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
func update_table(var t:Dictionary=table, var start:int = 0) -> String:
	
	#make sure there is a set of unformatted words to work with
	var s := to_string_array(contents, start)
	
	#if start is less than the difference in size of these two vectors, it is part of a conditional and should be used to update t
	var dif:int = s.size()
	if dif < 2:
		return ""
	
	#check if last two terms in array make up a key pair
	if s.size() > 1:
		var n := [parse(s[0], true), parse(s[1], true)]
		#keys must be strings, but values can be floats or strings
		if n[0] == null:
			if n[1] == null: t[s[0]] = s[1]
			else: t[s[0]] = n[1]
			return s[0]
	return ""

#do all the table updates in a given line
func update_table_line(var t:Dictionary = table, var start:int = 0, vectorize:bool = false) -> void:
	
	#if vectorize is enabled, ensure this line is not interrupted and failed by a conditional
	if vectorize:
		#get the vector of contents
		var a := vectorize(start)
		
		#if a is empty, this line failed a conditional, and should not make any updates
		if a.empty():
			return
	
	#the string array of contents
	var s = to_string_array(contents, start)
	
	#iterate through each pair in s from back to front
	var i = s.size() - 2
	while i > start:
		var try:String = update_table(t, i)
		if try.empty(): 
			break
		i -= 2

func _to_string():
	return contents
