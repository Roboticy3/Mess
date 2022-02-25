class_name PortalBound

#PortalBound class by Pablo Ibarz
#created January 2022

#a Portal Bound gives information on how to transfer a piece from one Bound to another

#the boundries where pieces enter (i) and exit (o)
var i:Bound = null
var o:Bound = null
#the piece's forward direction once traveled, 
#since Vec2.UP is the default forward it represents a 0 degree rotation to a pieces direction
#(1,1) is 45 clockwise, (-1,1) is 45 counterclockwise
var forward:Vector2 = Vector2.UP

func _init(var _i:Bound, var _o:Bound, var _f:Vector2):
	i = _i
	o = _o
	_f = _f.normalized().round()
	forward = _f

#TODO translate a piece's position in the in boundary to a position in the out boundary
func _travel(var pos:Vector2, var dir:Vector2):
	pass
	

func _to_string():
	var _i:String = i.to_string()
	var _o:String = o.to_string()
	var _f:String = String(forward.x) + ", " + String(forward.y)
	
	return "in : " + _i + ", out : " + _o + ", forward : " + _f
