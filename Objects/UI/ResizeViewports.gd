extends Node

#ResizeViewports class by Pablo Ibarz
#created August 4th, 2022

#attached to a node, forces a set of viewports to match the root size

export (Array, NodePath) var viewport_paths

var viewports:Array = []

export (bool) var force_to_window := true

var root:Viewport

func _ready():
	viewports.resize(viewport_paths.size())
	for i in viewport_paths.size():
		viewports[i] = get_node(viewport_paths[i])
		
	root = get_tree().root.get_viewport()
		
func _process(_delta):
	if force_to_window && root.size != OS.window_size: root.size = OS.window_size
	for v in viewports:
		if v.size != root.size: v.size = root.size
