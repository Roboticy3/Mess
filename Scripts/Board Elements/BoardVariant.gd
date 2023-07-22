class_name BoardVariant

var last

var data

func _init(x):
	data = x

func _to_string():
	return "BoardElement<" + str(data) + ">"
