extends Bound
class_name Bound2i

@export var _a:Vector2i
@export var _b:Vector2i

func _ready():
	a = _a
	b = _b
	
	if a.x < b.x or a.y < b.y:
		print(self, ": corner a must be greater than corner b")
	else:
		valid = true
