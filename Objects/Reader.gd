class_name Reader

#Reader class by Pablo Ibarz
#created February 2022

#reads an instruction file line by line and intereperets the lines with functions given to it by a Node

#the File being read from
var file:File

#the Node functions are taken from
var node:Node

#the functions being taken from node paired with their character stage definitions (e.g. 'm':"func", 'g':"func.001" etc)
var funcs:Dictionary
var size:int = 8

#initialize the Reader object
#size represents the number of properties Reader can store across multiple lines, default 8
func _init(var _node:Node, var _funcs:Dictionary, var _path:String = "", var _size:int = 8):
	node = _node
	funcs = _funcs
	size = _size
	
	file = File.new()
	var f:String = _path
	
	#make sure file ends with ".txt", then check if they are valid
	if !f.ends_with(".txt"):
		f += ".txt"
		
	#check if file d + f exists, if not, read from default
	if !file.file_exists(f):
		print("instruction file not found")
	else:
		file.open(f, File.READ)
		
		#check if funcs contains default phase ""
		#if not, attach a blank function to "phase", the default name for a phase function
		if !funcs.has("~"):
			funcs["~"] = "_phase"
	
#read the instruction file starting from a certain stage
func read(var stage:int = -1):
	#convert file to string array by line
	var content = file.get_as_text().rsplit("\n")

	#store vectors across lines
	var vec:Array = []
	
	#store properties across lines
	var persist:Array = []
	persist.resize(size)
	
	var stages:Array = funcs.keys()
	var stg = "~"
	
	#loop through instruction lines
	for c in content:
		#strip edges off line
		c = c.strip_edges()
		
		#create an instruction from the current line
		var I = Instruction.new(c, node.table)
		
		#append the current vector if it's valid
		vec = I.vectorize()
		
		for s in stages:
			if s.match(stg):
				node.call(funcs[stg], I, vec, persist)
		
		#check if line matches a stage key
		for s in stages:
			if c.match(s):
				stg = c
