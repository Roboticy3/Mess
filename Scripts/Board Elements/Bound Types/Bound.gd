extends Node
class_name Bound

var a
var b

var valid := false

func get_size():
	return a - b

func _to_string():
	return "Bound" + str(a) + str(b)
