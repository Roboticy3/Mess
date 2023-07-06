extends Node
class_name Bound

#a shape defined by two corners
#the closed set of all points bounded by [a, b]

var a
var b

var valid := false

func get_size():
	return a - b

#decide which corener is greater, and check if the given position is between them
func has_position(pos) -> bool:
	return a >= pos and pos >= b

func _to_string():
	return "Bound" + str(a) + str(b)
