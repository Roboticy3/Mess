class_name ScaleToWindow
extends Control

#ScaleToWindow class by Pablo Ibarz
#created July 2022

#Attach to the a Control to scale it to the resolution of the window

#viewport to get window size from
var viewport:Viewport

var starting_res:Vector2

func _ready():
	starting_res = rect_size
	viewport = get_viewport()
	viewport.connect("size_changed", self, "resize")
	resize()
	
func resize():
	rect_scale = viewport.size / starting_res
