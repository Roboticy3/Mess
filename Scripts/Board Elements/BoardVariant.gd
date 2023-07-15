extends BoardElement

var data:Variant

func _init(x):
	data = x

func _to_string():
	return "BoardElement<" + str(data) + ">"
