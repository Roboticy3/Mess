class_name SwitchMenu
extends Node

#SwitchMenu class by Pablo Ibarz
#Created July 2022

#Given a NodePath to a container, hide everything but its node and its children when this button is pressed

export (NodePath) var menu_path:NodePath
#child element of node from menu_path to auto-focus
export (NodePath) var focus_path:NodePath

#signal path and name 
export (NodePath) var signal_path:NodePath
export (String) var signal_name := "button_down"

#if true, signal_name will be interpereted as a string argument for Input methods instead of a signal
export (bool) var is_signal_input := false

#if true, switch() will not hide siblings of the node in menu_path, 
#making an overlay effect as long as that menu does not opaquely cover the screen
export (bool) var is_overlay := false

#set of nodes to not hide
const EXCLUDE:PoolStringArray = PoolStringArray(
	["Background"]
	)

#get the node from the given path and its siblings
var node:Node
var focus:Control
var signal_node:Node
var siblings:Array
func _ready():
	#get the nodes from the paths above
	node = get_node(menu_path)
	focus = get_node(focus_path) as Control
	#allow the focus node to gain the focus of the viewport
	if focus != null: focus.set_focus_mode(Control.FOCUS_ALL)
	
	#get the siblings of this node to iterate through in switch
	siblings = node.get_parent().get_children()
	
	#if signal is from a node in the scene, try to get a node from signal_path and connect its signal to switch()
	if !is_signal_input:
		#if signal path is invalid, make signal node this node
		signal_node = get_node_or_null(signal_path)
		if signal_node == null: connect(signal_name, self, "switch")
		else: 
			signal_node.connect(signal_name, self, "switch")
		#also make this kind of SwitchMenu unable to process, since this is only necessary for Input-based signals
		set_process(false)

func _process(_delta):
	if Input.is_action_just_pressed(signal_name):
		switch()

#switch from this menu to another, or from another menu back
func switch():
	#if node is already visible, invert the process
	var vis := true
	if node.get("visible"): vis = false
	
	#iterate through siblings and hide all the ones that do not match the target node
	for s in siblings:
		#if this is the target node unhide it and focus it, then skip to the next node
		if s == node:
			s.set("visible", vis)
			if focus != null: focus.grab_focus()
			continue
		
		#check if the node is in the list of excluded names, or if is_overlay is checked
		var hide := !is_overlay
		if hide: for e in EXCLUDE:
			if e.match(s.name):
				hide = false
				break
		
		#based on the above loop, hide or do not hide this node
		if hide: s.set("visible", !vis)
		
	
	



