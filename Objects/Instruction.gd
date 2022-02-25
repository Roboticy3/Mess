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

#store whether the last vectorize() call demanded a large line (>32)
var line:bool = false

func _init(var _contents:String="", var _table:Dictionary={}, var _pieces:Dictionary={}):
	contents = _contents
	table = _table
	pieces = _pieces

#Convert a line of instructions into a vector, starting from a certain index
func vectorize(var start = 0, var length = 2, var string = contents):
	#convert string to sequence of numbers
	var wrds = to_string_array(string, start)
	
	#return null for empty contents
	if wrds.size() == 0: return null
	
	#reset line flag to false
	line = false
	
	var cond = conditional(wrds, length, string)
	if typeof(cond) != 1:
		return cond

	var nums = Array()
	
	#check each word in the line
	for i in wrds.size():
		var w = wrds[i].strip_edges()
		var n = parse(w)
		if (n != null): 
			nums.append(n)
			
	#if length is two, set up a Vector2 array, otherwize set up a matrix
	var v = null
	var is_vec = false
	if nums.size() == 2 && length == 2:
		is_vec = true
		v = [Vector2(nums[0], nums[1])]
	else:
		v = Array()
		v.append(nums)
	#if nums has an extra element, add array elements to v of v[0] multiplied by 2, 3, 4... up to nums[-1]
	if nums.size() > length && nums[nums.size() - 1] > 1:
		#if loop will be very large, set line to true as a flag that this vector tiles indefinitely
		if nums[nums.size() - 1] > 31:
			line = true
			return v
		#Vector2 objects have to be handled differently here
		if is_vec:
			for i in range(2, nums[nums.size() - 1] + 1):
				v.append(v[0] * i) 
		else:
			var n = Array()
			for i in range(2, nums[nums.size() - 1] + 1):
				for j in nums.size():
					n.append(nums[j] * i)
				v.append(n)
	return v

func conditional(var wrds:Array=[""], var length:int=2, var string:String=contents):
	#enter conditional state if neccesary
	var w = wrds[0]
	if w.begins_with("?"):
		#check next word
		wrds[0] = wrds[0].substr(1)
		if wrds.size() > 3:
			var v = wrds[1].strip_edges()
			#if next word is a number, a vector is being checked
			if parse(v) != null:
				#check if a piece is in that vector, return true if its an enemy piece, false if otherwise
				pass
			#if next word is a conditional, a value is being checked next to "?"
			if SYMBL.find(v) != -1:
				var s = wrds.slice(0, 2)
				if (evaluate(s)):
					#vectorize after the conditional if the statement passes
					return vectorize(3, length, string)
				else:
					return null
	return false

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
	if (SYMBL.find(sgn) != -1):
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
	
	#look in string table
	for s in table.keys():
		var i = string.find(s)
		#if string is in contents replace string in contents with TABLE[string]
		if i != -1:
			var a = string.substr(0, i)
			var b = string.substr(i + s.length())
			string = a + String(table[s]) + b
	
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
	if s.size() > 1:
		var n = [parse(s[0]), parse(s[1])]
		if n[0] == null && n[1] != null:
			t[s[0]] = n[1]

func _to_string():
	return contents
