#Instructions can create moves from string math expressions and conditionals prefixed by "?"
#Variables can be referenced from a string table
#A conditional followed by a position returns a 0 if the position is empty, 1 if it is friendly, and 2 otherwise
#Direction is always relative to the piece's forward vector

class_name Instruction

var contents = ""

#set of comparison statements
const SYMBL : String = ">=<=="

#string table can be added by users of the instruction object, the tables are then stitched together in parse()
var table:Dictionary = {}
#piece table can be referenced in conditional phase when checking squares
var pieces:Dictionary ={}

#store whether the last vectorize() call demanded a line (1) or an infinite line (2)
var line:int = 0


func _init(var _contents:String="", var _table:Dictionary={}, var _pieces:Dictionary={}):
	contents = _contents
	table = _table
	pieces = _pieces

#Convert a line of instructions into a vector, starting from a certain index
func vectorize(var start = 0, var length = 2, var string = contents):
	#convert string to sequence of numbers
	var wrds = to_string_array(string, start)
	
	#return empty for empty contents
	if wrds.size() == 0: return []
	
	#reset line
	line = 0
	
	#replace variable terms with matching table terms
	for w in wrds:
		w = w.strip_edges()
		if w.begins_with("?"):
			w = w.substr(1)
		if w in table:
			w = String(table[w])
	
	#assume conditional and return it if it doesn't return null
	var cond:Array = conditional(wrds, length, string)
	#if return is not a boolean(?) it will be a vector, so return that
	if !cond.empty():
		return cond

	var nums = Array()
	
	#check each word in the line
	for i in wrds.size():
		var w = wrds[i].strip_edges()
		var n = parse(w)
		if (n != null): 
			nums.append(n)
			
	#if length is two, set up a Vector2 array, otherwize set up a matrix
	var v = nums
	#Instructions default to an L shape, line = 1 makes the shape diagonal,
	#line = 2 maks and infinite diagonal
	if nums.size() > length:
		if nums[nums.size() - 1] == 2:
			line = 2
		elif nums[nums.size() - 1] == 1:
			line = 1
	return v

func conditional(var wrds:Array=[""], var length:int=2, var string:String=contents):
	#enter conditional state if neccesary
	var w = wrds[0]
	if w.begins_with("?"):
		#remove question mark from wrds[0]
		wrds[0] = wrds[0].substr(1)
		#conditionals need 3 wrds to evaluate and at least another term after them to return anything
		if wrds.size() > 3:
			var u = parse(wrds[0].strip_edges())
			var v = parse(wrds[1].strip_edges())
			#if first word is not a number, then a conditional cannot be formed and false is assumed
			if u == null: return []
			
			#if second word is a number and table has px and py vars, 
			#a vector is being checked from pieces
			var x:Vector2
			if v != null && "px" in table && "py" in table:
				x = Vector2(table["px"], table["py"])
				#if the relative position of the position from the piece is filled
				#return true
				var y:Vector2 = Vector2(u, v)
				y = y.rotated(table["angle"])
				if x + y in pieces:
					return vectorize(2, length, string)
				#otherwise return false
				return []
				
			#if next word is a conditional, a value is being checked next to "?"
			if SYMBL.find(v) != -1:
				var s = wrds.slice(0, 2)
				if (evaluate(s)):
					#vectorize after the conditional if the statement passes
					return vectorize(3, length, string)
	return []

#evaluate conditional of an array of strings of length 3 or 4
func evaluate(var wrds:Array = [""]):
	#FIXME returns null when it isnt supposed to 
	#create an array of values to store integers or calls to table fucking hell i love polymorphism
	var a = Array()
	for w in wrds:
		w = parse(w)
		if (w != null): a.append(w)
	
	var sgn = wrds[1].strip_edges()
	
	#if conditional is in the right format and has valid variable calls, evaluate it
	if (SYMBL.find(sgn) != -1) && a.size() > 1:
		#check for the conditional symbol
		if sgn.ends_with("="):
			if (sgn.find("<") != -1 && a[0] <= a[1]):
				return true
			elif (a[0] >= a[1]):
				return true
			elif (a[0] == a[1]):
				return true
		elif (sgn == ">" && a[0] > a[1]):
			return true
		elif (sgn == "<" && a[0] < a[1]):
			return true
		
	return false

func parse(var string=contents):
	#parse text expressions as numerics
	var expression = Expression.new()
	
	expression.parse(string)
	#if the parse was "successful", add the result
	#this could be the cause of some bullshit later
	var n = expression.execute()
	if (n != null):
		return n
	return null

#convert instruction text to string array of words for easier parsing
func to_string_array(var c:String = contents, var s:int = 0, var delims:String = " ,"):
	c = c.substr(0, c.find("#")) + " "
	
	#initialize word array
	var a = Array()
	#initialize split position array
	var pos = [0]
	
	#add split positions
	for i in c.length():
		if (delims.find(c[i]) != -1):
			pos.append(i)
	
	#if there is more than one word
	if (pos.size() > 0):
		for i in pos.size():
			a.append(c.substr(pos[i - 1], pos[i] - pos[i - 1]))
	
	for i in s + 1:
		a.remove(0)
		
	return a

#take in a table to update with self
func update_table(var t:Dictionary=table):
	#populate piece table by trying taking numbers from the second word
	var s = to_string_array()
	#check if last two terms in array make up a key pair
	if s.size() > 1:
		var i:int = s.size() - 2
		var j:int = s.size() - 1
		var n = [parse(s[i]), parse(s[j])]
		if n[0] == null && n[1] != null:
			t[s[i]] = n[1]

func _to_string():
	return contents
