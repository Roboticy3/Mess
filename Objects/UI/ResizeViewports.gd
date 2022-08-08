extends Node

#ResizeViewports class by Pablo Ibarz
#created August 4th, 2022

#attached to a node, forces a set of viewports to match the root size

#set of paths at which nodes need to be resized
export (Array, NodePath) var viewport_paths := []
#array to store the nodes at the above paths
var viewports := []

#the name of the size property
export (String) var size:String = "size"

#the starting size of the window
var base := Vector2(1920, 1080)

#if true, the size of the viewports will be set as a multiplier based on their starting size
export (bool) var multiplier := false

#if true, the root viewport will be forced into OS.window_size, and the other viewports will follow suit
export (bool) var force_to_window := true


#the root viewport of the scene
var root:Viewport

func _ready():
	#fill the viewports array
	viewports.resize(viewport_paths.size())
	for i in viewport_paths.size():
		viewports[i] = get_node(viewport_paths[i])
		
		#make sure all the viewports have a property size of type Vector2
		if !(viewports[i].get(size) is Vector2):
			print("ResizeViewports::_ready() says \"Property '" + size + "' in " + viewports[i] + " is not a Vector2\"")
			break
	
	#get the root viewport
	root = get_tree().root.get_viewport()

#check if the window size has changed each frame
func _process(_delta):
	#change the root size if force_to_window is enabled
	#only one ResizeViewport should ever need force_to_window enabled at a given time
	if force_to_window && root.size != OS.window_size: root.size = OS.window_size
	
	#check if any of the viewports have a difference in size from the root
	for v in viewports:
		#get the size property from this viewport
		var s:Vector2 = v.get(size)
		
		#changing the size of multipliers isn't so taxing as interacting with a viewport's size directly
		#so, this can be done every frame to avoid flicker
		if multiplier:
			v.set(size, root.size / base)
		
		#otherwise, the size could just be different from the root size, in which case it also needs to be changed
		elif s != root.size:
			v.set(size, root.size)
