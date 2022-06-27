class_name Bound

#Bound class by Pablo Ibarz
#created December 2021

#a Bound is a rectangle which is used to define shapes on a board

#a is the top right corner of the bound, b the bottom left
var a:Vector2
var b:Vector2

#automatically sort inputs into a and b so a is the top right corner and b the bottom left
func _init(var _a:Vector2 = Vector2.ZERO, var _b:Vector2 = Vector2.ZERO):
	var v = ab_to_rect(_a, _b)
	a = v[1]
	b = v[0]
		
func ab_to_rect(var _a:Vector2 = Vector2.ZERO, var _b:Vector2 = Vector2.ZERO):
	var v:PoolVector2Array = [Vector2.ZERO, Vector2.ZERO]
	if (_a.x > _b.x):
		if _a.y > _b.y:
			v[1] = _a
			v[0] = _b
		else:
			v[1] = Vector2(_a.x, _b.y)
			v[0] = Vector2(_b.x, _a.y)
	elif _a.y > _b.y:
		v[1] = Vector2(_b.x, _a.y)
		v[0] = Vector2(_a.x, _b.y)
	else:
		v[1] = _b
		v[0] = _a
	
	return v
		
#check where or not a Vector2 is within the bound
func is_surrounding(var v:Vector2, var inclusive:bool = true):
	if inclusive: return a.x >= v.x && a.y >= v.y && v.x >= b.x && v.y >= b.y
	else: return a.x > v.x && a.y > v.y && v.x > b.x && v.y > b.y
	
#parse boundary from text content c with a midpoint mp and stopping point sp
func from_text(var c:String, var mp:int, var sp:int):
	if (mp == 0): mp = c.length()
	if (sp == 0): sp = c.length()
	#create the Vectors with Instruction's vectorize() method
	#its kind of like using a claymore to cut a pizza, yummy!
	var v = Instruction.new(c.substr(0, mp)).vectorize()
	var v2 = Instruction.new(c.substr(mp, sp)).vectorize()
	
	#ok so im going back through my comments to push more readable code and..
	#this is insane and i love it
	_init(v, v2)
	return self

#check if boundary is zeroed
func is_zero():
	return a == Vector2.ZERO && b == Vector2.ZERO

#get Vector2 array of corners
func get_corners():
	var v:PoolVector2Array = [Vector2(b.x, a.y), a, Vector2(a.x, b.y), b]
	return v

#get 2D Vector2 array of edges
func get_edges():
	var c = Vector2(b.x, a.y)
	var d = Vector2(a.x, b.y)
	return [[a, c], [c, b], [b, d], [d, a]]

#WIP check if bound intersects with an object, runs differently depending on type of input
#currently the only object type which works is Array
#returns an array of intersections
#negate will return the non-intersections
#mode = 0 will interperet X as PoolVector2Array as an edge set
#mode = 1 will interperet X as an edge set cyclically, so the last and first index form an edge
#mode = 2 will interperet X as a set of points, and record the points self is surrounding
func intersection(var X = null, 
	var mode:int = 0):
		
	if X == null:
		return []
		
	if X is Array || X is PoolVector2Array:
		if mode == 2: return point_set_intersection(X)
		var c:bool = mode == 1
		return edge_set_intersection(X, c)

#return intersecting edges with bound edges from a set
#if cyclic is checked, the pair (n, 0) will be checked for intersection as well
func edge_set_intersection(var edges:PoolVector2Array, var cyclic:bool = false):
	#don't run function for empty sets
	if edges.size() == 0:
		return false
	#run is_surrounding instead for single point inputs
	elif edges.size() == 1: 
		return is_surrounding(edges[0])
		
	#create line segments from bound to intersect against edges
	var bsegs = get_edges()
	
	#convert edges into point/slope form
	var blines:Array = [[0,0,0],[0,0,0],[0,0,0],[0,0,0]]
	for i in range(0, 4):
		var _a:Vector2 = bsegs[i][0]
		var _b:Vector2 = bsegs[i][1]
		if _a.x - _b.x == 0:
			blines[i][0] = INF
		else:
			blines[i][0] = (_a.y - _b.y) / (_a.x - _b.x)
		blines[i][1] = _a
		blines[i][2] = _b
	
	#create intersection array
	var intersections:PoolVector2Array = []
	
	#if cyclic is not checked, only loop upto the second-to-last element
	var s:int = -1
	if cyclic: s = 0
	
	for i in range(0, edges.size() + s):
		#translate line segment to ax + by = c form from element of edges
		var a:Vector2 = edges[i]
		var b:Vector2 = edges[(i + 1) % edges.size()]
		var b0:float
		if a.x - b.x == 0:
			b0 = INF
		else:
			b0 = (a.y - b.y) / (a.x - b.x)
		var x0:float = a.x
		var y0:float = a.y
		
		#run line intersection between p and each segment of self
		for q in blines:
			#create line segment to point-slope form from edge of 
			var c:Vector2 = q[1]
			var d:Vector2 = q[2]
			var b1:float = q[0]
			var x1:float = c.x
			var y1:float = c.y
			
			#check if range and domain intersect, skip computations if not
			var v0 = ab_to_rect(a, b)
			var v1 = ab_to_rect(c, d)
			if !(is_gtoet(v1[1], v0[0]) && is_gtoet(v0[1], v1[0])):
				continue
			
			#if lines a parallel, plug 0 into both line equations to see if they are the same
			if b1 == b0:
				
				#average of points with equal slopes will always intersect
				var x:Vector2 = (a + b + c + d) / 4
				
				#check lines are vertical
				if b1 == INF:
					intersections.append(x)
				#check lines have same height
				elif -x0 * b0 + y0 == -x1 * b1 + y1:
					intersections.append(x)
				
				#if neither of these are true, the lines cannot be intersecting
				continue
			
			var x:float = NAN
			var y:float = NAN
			#if one of the slope values is infinite, the intersection (x1, slope0(x1)) or (x0, slope1(x0))
			if b1 == INF:
				x = x1
				y = b0 * (x1 - x0) + y0
			elif b0 == INF:
				x = x0
				y = b1 * (x0 - x1) + y1
			#otherwise, solve system of line equations by matrix system
			else:
				var discriminant = 1 / (-b0 + b1)
				x = (-b0 * x0 + y0 + b1 * x1 - y1) * discriminant
				y = (-b1 * (b0 * x0 - y0) + b0 * (b1 * x1 - y1)) * discriminant
			
			#if solution is in range of both lines, return true
			var xy = Vector2(x, y)
			if is_surrounding(xy):
				intersections.append(xy)
			
	return intersections
	
func point_set_intersection(var points:PoolVector2Array):
	
	var intersections:PoolIntArray = []
	
	for i in points.size():
		if is_surrounding(points[i]):
			intersections.append(i)

#compare two Vector2 objects and return true if and only if both elements of a are greater than or equal to both elements of b
func is_gtoet(var _a:Vector2, var _b:Vector2):
	if _a.x >= _b.x && _a.y >= _b.y:
		return true
	return false

#convert bound to string in least to greatest order
func _to_string():
	return "[" + String(b) + ", " + String(a) + "]"
