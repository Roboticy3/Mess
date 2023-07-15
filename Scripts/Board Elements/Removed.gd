extends BoardElement
class_name Removed

#general name for objects that are explicitly NOT here, helps with generated states on the board and can be used for others as well

func _to_string():
	return "Removed " + str(last)
