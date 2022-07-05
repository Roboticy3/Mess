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
var focus:Control
var siblings:Array
func _ready():
	node = get_node(menu_path)
	focus = get_node(focus_path) as Control
	focus.set_focus_mode(Control.FOCUS_ALL)
	siblings = node.get_parent().get_children()

#iterate through siblings and hide all the ones that do not match the target node
func _pressed():
	for s in siblings:
		if s == node:
			s.set("visible", true)
			focus.grab_focus()
			continue
		if !(s is AlwaysVisible): s.set("visible", false)
	
	



