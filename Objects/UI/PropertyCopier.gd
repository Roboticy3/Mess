class_name PropertyCopier
extends Node

#PropertyCopier class by Pablo Ibarz
#created July 2022

#Given a path to another Node, the String name of one of its properties, 
#the String name of a signal to connect to, and the String name of a property to import to,
#copy the Node's property to this property when the signal is recieved

#Path to the node to copy from
export (NodePath) var target_path:NodePath
var target:Node
#name of property in the target node to copy from
export (String) var target_property_name:String

#name of the signal to update on
export (String) var target_signal_name

#Path to the node to copy into
export (NodePath) var destination_path:NodePath
var destination:Node
#name of property in this node to copy into
export (String) var destination_property_name:String

#signal to emit on a successful copy
signal copy

func _ready():
	target = get_node(target_path)
	destination = get_node(destination_path)
	target.connect(target_signal_name, self, "copy_property")

#try to copy a property from target, return true if the property being copied exists, and false otherwise
func copy_property(var property_name:String = target_property_name) -> bool:
	#check if property_name exists on target
	var p = target.get(property_name)
	if p == null: return false
	
	#if property_name exists, set destination_property_name to its value
	destination.set(destination_property_name, p)
	emit_signal("copy")
	return true
	
	
