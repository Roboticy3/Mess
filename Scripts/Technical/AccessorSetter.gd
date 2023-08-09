extends Node

@export_node_path("Node") var object_path = NodePath(".")

@export var accessor_path = "current_console"

func _init():
	Accessor.set(accessor_path, object_path)
