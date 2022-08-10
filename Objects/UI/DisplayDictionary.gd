extends Node

#DisplayDictionary class by Pablo Ibarz
#created August 2022

#Displays a Dictionary with String values across a set of properties belonging to corresponding Nodes when the display() method is called
#when the hide() method is called, the changes to these fields are undone

#the path to the target node containing a Dictionary, and the name of the Dictionary property, that are needed to find the Dictionary to display
#the target Dictionary must have all String values in the set of keys that it will display to work properly 
export (NodePath) var dictionary_path := NodePath("..")
export (String) var dictionary_name := "results"
#the target node
var target:Node
#the target Dictionary
var dictionary:Dictionary = {}

#the paths set of nodes that the target Dictionary's data will display into
export (Array, NodePath) var node_paths := []
#the set of nodes
var nodes := []

#the keys the nodes at each index will reference in the target Dictionary for their display text
#must be at least the size of node_paths
export (Array, String) var display_keys:Array

#the position in the text at each node from which values were last displayed
#also must be at least the size of node_paths
export (Array, int) var display_char_indices:Array

#true if display was called more recently than hide() and false if otherwise
var displaying:bool = false

func _ready():
	
	#try to gain reference to the target Node
	var t = get_node_or_null(dictionary_path)
	if t == null:
		print("DisplayDictionary::_ready() says \failed to retrieve a node from NodePath " + dictionary_path + "\"" )
	target = t
	
	#try to gain reference to the target Dictionary
	var d = target.get(dictionary_name)
	if !(d is Dictionary): 
		print("DisplayDictionary::_ready() says \"property " + dictionary_name + " in node " + target.to_string() + "is not a Dictionary\"" )
		return
	dictionary = d
	
	#fill the nodes array
	nodes.resize(node_paths.size())
	for i in node_paths.size():
		nodes[i] = get_node(node_paths[i])
		
	if display_char_indices.size() < node_paths.size():
		print("DisplayDictionary::_ready() says \"display char indices not large enough, must be at least as large as node paths\"" )
	if display_keys.size() < node_paths.size():
		print("DisplayDictionary::_ready() says \"display keys not large enough, must be at least as large as node paths\"")

#display the the target Dictionary among the set of nodes
func display():
	
	#if text is already displaying, hide the last displayed text first
	if displaying: hide()
	
	#for each node referenced
	for i in nodes.size():
		var n:Node = nodes[i]
		var k:String = display_keys[i]
		
		#do not try and display to nodes that do not have a text setter
		if !n.has_method("set_text") || !n.has_method("get_text"): continue
		
		#do not try and display text from a non-existent key
		if !dictionary.has(k): continue
		
		#add the display text into its index in the node's text
		var t:String = n.get_text()
		var c:int = display_char_indices[i]
		#if the index is larger than the text length, add display text onto the end and change the index to the text length
		if c >= t.length():
			display_char_indices[i] = t.length()
			t += dictionary[k]
		#otherwise, insert the text at the display index
		else:
			t = t.insert(c, dictionary[k])
		n.set_text(t)
		
	#flag that the text is being displayed
	displaying = true

#hide the target Dictionary's display texts
func hide():
	
	#only execute if text is already displaying
	if !displaying: return
	
	#same as display, except for the last line of the loop
	for i in nodes.size():
		var n:Node = nodes[i]
		var k:String = display_keys[i]
		
		if !n.has_method("set_text") || !n.has_method("get_text"): continue
		if !dictionary.has(k): continue
		
		#inset nothing into the display index
		var t:String = n.get_text()
		var c:int = display_char_indices[i]
		t.erase(c, dictionary[k].length())
		n.set_text(t)
		
	#reset displaying flag
	displaying = false
		
