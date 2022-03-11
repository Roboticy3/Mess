class_name Instruction

#Instruction class by Pablo Ibarz
#created November 2021

#An Instruction takes in a single line string (no \n characters) and converts it into an array of numbers
#It also holds table and pieces Dictionaries of variables and pieces
#TODO merge table with pieces because their keys will never intersect

var contents = ""

#the set of valid comparison characters, contains <=, >=, <, >, and ==
const SYMBL : String = ">=<=="

var table:Dictionary = {}
var pieces:Dictionary = {}

#store whether the last vectorize() call demanded an L-line as opposed to the default diagonal (1) or an infinite line (2)
#line doesn't mean anything to the Instruction class directly, but is used by a Board object to generate a line of positions
var line:int = 0


#fill variables of the object fully
func _init(var _contents:String="", var _table:Dictionary={}, var _pieces:Dictionary={}):
	contents = _contents
	table = _table
	pieces = _pieces

#convert contents into an Array of floats, starting from a word index start
#TODO: separate formatting part of function into separate format() function for faster recursive calls
func vectorize(var start = 0, var length = 2, var string = contents):

	#convert string to sequence of numbers
	var wrds = to_string_array(string, start)
	
	#return empty for empty contents
	if wrds.size() == 0: return []
	
	#reset line
	line = 0
	
	#replace terms in table key set with their value pairs
	for w in wrds:
		#help parser later by stripping edges in each word
		w = w.strip_edges()
		#take conditional indicator into secondary String so w can be added back onto it later
		var q:String = ""
		if w.begins_with("?"):
			w = w.substr(1)
		if w in table:
			#String replacement is a little awkward, 
			#but it must be done before wrds is parsed for full functionality
			w = String(table[w])
		#reform the string
		w = q + w
	
	#try to evaluate contents as a conditional (starting with "?")
	var cond:Array = conditional(wrds, length, string)
	#if conditional evaluates to true, it will recursively call vectorize() can return a vector
	#this will generate a non-empty result, which can be returned as-is
	if !cond.empty():
		return cond
	
	#create return object
	var nums = Array()
	
	#check each word in the line and parse it into a float
	for i in wrds.size():
		
		var n = parse(wrds[i])
		nums.append(n)
			
	#last element determines line type, this should probably be moved to handling entirely on the end of the Board object
	if nums.size() > length:
		if nums[nums.size() - 1] == 2:
			line = 2
		elif nums[nums.size() - 1] == 1:
			line = 1
	return nums

#WIP evaluate conditional statements, made up of a wrds Array of length 2 or more that can solve inequalities or check pieces on the Board
func conditional(var wrds:Array=[""], var length:int=2, var string:String=contents):
	
	#the minimum conditional size is 2, and then something after that to actually return if the conditional evaluates to true
	if wrds.size() < 3:
		return []
	
	#if input is not a conditional, return blank Array
	if !wrds[0].begins_with("?"):
		return []
		
	#remove question mark from wrds[0] once it is confirmed of valid size and format
	wrds[0] = wrds[0].substr(1)
	
	#take parsed versions of first and second wrds to determine the type of conditional
	var u = parse(wrds[0])
	var v = parse(wrds[1])
	
	#TODO: use piece table to add checks of other piece variables with the format "x y var op val"
	#if second word is a number and table has px and py vars, 
	#a vector is being checked from pieces
	var x:Vector2
	if "px" in table && "py" in table:
		x = Vector2(table["px"], table["py"])
		#if the relative position of the position from the piece is filled
		#return true
		var y:Vector2 = Vector2(u, v)
		y = y.rotated(table["angle"])
		if x + y in pieces:
			return vectorize(2, length, string)
		#otherwise return false
		return []

	#if next word is a conditional, the value with "?" is being compared to another on the other side of the conditional
	if SYMBL.find(wrds[1]) != -1:
		var s = wrds.slice(0, 2)
		if (evaluate(s)):
			#vectorize after the conditional if the statement passes
			return vectorize(3, length, string)

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
