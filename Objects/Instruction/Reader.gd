class_name Reader

#Reader class by Pablo Ibarz
#created February 2022

#reads an instruction file line by line and intereperets the lines with functions given to it by a Node

#the File being read from
var file:File

#the Node functions are taken from
var node:Node

#the board vectors are transformed through
var board

#the functions being taken from node paired with their character stage definitions (e.g. 'm':"func", 'g':"func.001" etc)
var funcs:Dictionary
var size:int = 8

#if set to true, read() will not call any functions until it reaches a defined key
var wait:bool = false

#set to true when this Reader is assigned a bad file
var badfile:bool = false

#set to true to nullify all elements of the persist array between blocks during read()
var clear_persist:bool = false

#set to false to not vectorize instructions being read
var vectorize:bool = false

#initialize the Reader object
#size represents the number of properties Reader can store across multiple lines, default 8
func _init(var _node:Node, var _funcs:Dictionary, var _path:String = "", var _size:int = 8,
	var _board = null, var _clear_persist:bool = false, var _vectorize:bool = true):
	
	board = _board
	node = _node
	funcs = _funcs
	size = _size
	
	clear_persist = _clear_persist
	vectorize = _vectorize
	
	badfile = !set_file(_path)
			
func set_file(var f:String) -> bool:
	
	file = File.new()
		
	#check if file d + f exists, if not, read from default
	var file_error:int = file.open(f, File.READ)
	if file_error > 0: return false
		
	#check if funcs contains default phase ""
	#if not, attach a blank function to "phase", the default name for a phase function
	if !funcs.has("~"):
		funcs["~"] = "_phase"
	return true
	
#read the instruction file starting from a certain stage
func read():
	#convert file to string array by line
	var content = file.get_as_text().rsplit("\n")

	#store vectors across lines
	var vec:Array = []
	
	#store properties across lines
	var persist:Array = []
	persist.resize(size)
	
	var stages:Array = funcs.keys()
	var stg = "~"
	
	#value indicating whether the first defined stage has been found
	var begun:bool = false
	
	#loop through instruction lines
	for c in content:
		#strip edges off line
		c = c.strip_edges()
		
		#create an instruction from the current line
		var I = Instruction.new(c, node.table, board)
		
		#append the current vector if this Reader is vectorizing
		if vectorize: vec = I.vectorize()
		
		#find if any of the stages match the current one
		#if so, call the method paired with the current stage
		#skip empty function matches
		if !funcs[stg].empty(): for s in stages:
			#dont call any method if wait has been set to true and the first defined method is yet to be found
			if s.match(stg) && (!wait || begun):
				node.call(funcs[stg], I, vec, persist)
		
		#check if line matches a stage key
		for s in stages:
			if c.match(s):
				
				#if clear_persist is enabled, nullify all elements of persist
				for i in size:
					persist[i] = null
				
				begun = true
				stg = c
				break
