class_name Triangle

var uvs = PoolVector2Array()
var points = PoolVector3Array()

func _init(var _p:Array=[], var _uv:Array=[]):
	#whether or not the default triangle is being created
	var default = false
	
	#only set categories if they are not empty
	if !_p.empty():
		points = _p
	#default set of triangle points
	else:
		points = [Vector3.ZERO, Vector3.FORWARD, Vector3.RIGHT]
	
	if !_uv.empty():
		uvs = _uv
	#complete default triangle if uvs are missin
	else:
		uvs = [Vector2.ZERO, Vector2.UP, Vector2.RIGHT]

#get area of array of points of length 3
func area(var p:PoolVector3Array = points):
	#angle from side "a" to side "b"
	var angle = (p[0]-p[1]).angle_to(p[2]-p[1])
	#the sine of this angle times the length of the hypotenuese is the height of the triangle
	var h = sin(angle) * p[1].distance_to(p[2])
	#area of the triangle is base times height over 2
	return h * p[1].distance_to(p[0]) / 2

#get barycentric coord of coplanar position
func barycentric(var pos:Vector3):
	#the barycentric coordinate is equal to the area of the opposite subtriangle
	#since the position is coplanar, the areas will always sum to 1 and make the position valid
	var bar = [0, 0, 0]
	var s = get_subareas(pos)
	for i in range(0, 3):
		var j = (i + 2) % 3
		bar[j] = s[i]
	
	return bar

#get center of triangle
func center(var p:PoolVector3Array = points):
	return (p[0] + p[1] + p[2]) / 3
	
#get subarea of a triangle around a point
func get_subareas(var pos:Vector3):
	#initialize areas to zeroes, then return as is if the main tri's area is zero
	var a = [0, 0, 0]
	var x = area()
	if x == 0: return a
	
	for i in range(0, 3):
		var j = (i + 1) % 3
		var w = [points[i], points[j], pos]
		a[i] = area(w) / x
	return a

#get if coplanar position is inside triangle
func is_surrounding(var pos:Vector3, var margin:float=0):
	
	#a point cannot be inside an infinitely small triangle
	if area() == 0:
		return false

	#try replacing with normal aglos
	#https://gdbooks.gitbooks.io/3dcollisions/content/Chapter4/point_in_triangle.html
	var r = get_subareas(pos)

	#conditions check that ratios are not large or negative, and that all sum to one
	#thanks math
	for i in range(0, 3):
		if r[i] > 1.001 + margin:
			return false

	if abs(r[0] + r[1] + r[2] - 1) > 0.001 + margin:
		return false

	return true
	
#convert the triangle into a plane
func plane(var n:Vector3):
	return Plane(points[0], points[1], points[2])

#get uv coord of a coplanar position
#only works if triangle has uvs
func uv(var pos:Vector3):
	
	#use barycentric coords to weigh uvs of triangle corners
	var b = barycentric(pos)
	
	#check if triangle has uvs
	if (uvs.empty()): return null
	
	var w = PoolVector2Array()
	#weigh uvs by barycentric coords
	#if barycentric coords are zeroed out, triangle has no area and uv cannot be determined
	#check each in the loop that tries to compute uvs
	var good = false
	for i in range(0, 3):
		if b[i] != 0: good = true
		w.append(uvs[i] * b[i])
	
	if good: return w[0] + w[1] + w[2]
	else: return null
	
func _to_string():
	return "a:" + String(points[0]) + ", b:"  + String(points[1]) + ", c:" + String(points[2])
