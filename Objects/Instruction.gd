class_name Instruction

#Instruction class by Pablo Ibarz
#created November 2021

#An Instruction takes in a single line string (no \n characters) and converts it into an array of numbers
#It also holds table and pieces Dictionaries of variables and pieces
#TODO merge table with pieces because their keys will never intersect

var contents = ""
var wrds:Array = []

#the set of valid comparison characters, contains <=, >=, <, >, and ==
const SYMBL : String = ">=<=="

var table:Dictionary = {}
var pieces:Dictionary = {}

#fill variables of the object fully
func _init(var _contents:String="", var _table:Dictionary={}, var _pieces:Dictionary={}):
	contents = _contents
	table = _table
	pieces = _pieces
	
	#format contents into wrds
	format()
	
#format a string into the wrds Array
func format(var start = 0, var square = null, var string = contents):
	
	#take table from another square if a square is specified
	if square in pieces:
		table = pieces[square].table
		print(table)
	
	#convert string to sequence of numbers
	wrds = to_string_array(string, start)
	
	#return empty for empty contents
	if wrds.size() == 0: return []

	#replace terms in table key set with their value pairs
	for i in wrds.size():
		var w:String = wrds[i]
		#help parser later by stripping edges in each word
		w = w.strip_edges()
		#take conditional indicator into secondary String so w can be added back onto it later
		var q:String = ""
		if w.begins_with("?"):
			w = w.substr(1)
			q = "?"
		if w in table:
			#String replacement is a little awkward, 
			#but it must be done before wrds is parsed for full functionality
			w = String(table[w])
		#reform the string
		w = q + w
		wrds[i] =w

#convert contents into an Array of floats, starting from a word index start
#TODO: separate formatting part of function into separate format() function for faster recursive calls
func vectorize(var start = 0):
	
	#try to evaluate contents as a conditional (starting with "?")
	var cond:Array = conditional(start)
	#if conditional evaluates to true, it will recursively call vectorize() can return a vector
	#this will generate a non-empty result, which can be returned as-is
	if !cond.empty():
		return cond
		
	var w:Array = wrds.slice(start, wrds.size() - 1)
	
	#create return object
	var nums = Array()
	
	#check each word in the line and parse it into a float
	for i in w.size():
		
		var n = parse(w[i])
		nums.append(n)

	return nums

#WIP evaluate conditional statements, made up of a wrds Array of length 2 or more that can solve inequalities or check pieces on the Board
func conditional(var start:int = 0):
	
	#slice from start
	var w:Array = wrds.slice(start, wrds.size() - 1)
	
	#the minimum conditional size is 2, and then something after that to actually return if the conditional evaluates to true
	if w.size() < 3:
		return []
	
	#if input is not a conditional, return blank Array
	if !w[0].begins_with("?"):
		return []
		
	#remove question mark from wrds[0] once it is confirmed of valid size and format
	w[0] = w[0].substr(1)
	
	#take parsed versions of first and second wrds to determine the type of conditional
	var u = parse(w[0])
	var v = parse(w[1])
	
	#TODO: use piece table to add checks of other piece variables with the format "x y var op val"
	#if second word is a number and table has px and py vars, a vector is being checked from pieces
	var x:Vector2
	if "px" in table && "py" in table:
		x = Vector2(table["px"], table["py"])
		#if the relative position of the position from the piece is filled,
		#a square is being checked on the board, and a relative position is formed
		var y:Vector2 = Vector2(u, v)
		#make sure to rotate y by forward direction, which is held in the "angle" entry in a piece table
		y = y.rotated(table["angle"])
		
		#if square is empty, return nothing
		if !(x + y in pieces):
			return []
		
		#if square is populated, check if 4th element is a conditional,
		#if so, an element of the table from a piece at the square is being checked
		if w.size() > 5 && SYMBL.find(w[3]) != -1:
			#FIXME reformat and restart the conditional, starting from the reformatted value
			format(0, x + y)
			conditional(2)
			
		return vectorize(2)

	#if next word is a conditional, the value with "?" is being compared to another on the other side of the conditional
	if SYMBL.find(wrds[1]) != -1:
		var s = wrds.slice(0, 2)
		if (evaluate(s)):
			#vectorize after the conditional if the statement passes
			return vectorize(3)

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

#convert a single word string (no " " or "\n" characters) into a float using the Expression class
func parse(var string=contents):
	#create Expression to parse off of
	var expression = Expression.new()
	
	#use parse method and then execute method
	expression.parse(string)
	#old comments from when this function was nullable, I love when im right!
		#if the parse was "successful", add the result
		#this could be the cause of some bullshit later
	#I assume parse breaks up the string into numbers and operators, and execute takes those and does the computation
	var n = expression.execute()
	if (n != null):
		return n
	
	#never return null so other code doesn't have to type-check the result
	var default:float = 0
	return default

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
