class_name SwitchMenu
extends Control

#SwitchMenu class by Pablo Ibarz
#Created July 2022

#Given a NodePath to a container, hide everything but its node and its children when this button is pressed

export (NodePath) var menu_path
#child element of node from menu_path to auto-focus
export (NodePath) var focus_path

#set of nodes to not hide
const EXCLUDE:Array = ["Background"]

#get the node from the given path and its siblings
var node:Node
var siblings:Array
func _ready():
	if !set_node_path(menu_path): return
	siblings = node.get_parent().get_children()

#iterate through siblings and hide all the ones that do not match the target node
func _pressed():
	for s in siblings:
		if s == node:
			s.set("visible", true)
			get_node(focus_path).grab_focus()
			continue
		if !(s is AlwaysVisible): s.set("visible", false)

#set node from a path, return false if this fails to create a non-null value
func set_node_path(var path:NodePath) -> bool:
	node = get_node(path)
	if node == null: return false
	return true
	
	



