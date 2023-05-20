extends Bound
class_name Bound2i

@export var _a:Vector2i
@export var _b:Vector2i

func _ready():
	a = _a
	b = _b
	
	if a.x < b.x or a.y < b.y:
		Accessor.a_print(str(self) + ": corner a must be greater than corner b")
	else:
		valid = true

func has_position(pos:Vector2i) -> bool:
	return (a.x >= pos.x and pos.x >= b.x) and \
			(a.y >= pos.y and pos.y >= b.y)
