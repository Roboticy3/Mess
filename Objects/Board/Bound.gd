#a Bound is a rectangle which is used to define shapes on a board

class_name Bound

#is the top right corner of the bound, b the bottome left
var a:Vector2
var b:Vector2

#automatically sort inputs into a and b correctly
func _init(var _a:Vector2 = Vector2.ZERO, var _b:Vector2 = Vector2.ZERO):
	if (_a > _b):
		a = _a
		b = _b
	else:
		a = _b
		b = _a
		
#check where or not a Vector2 is within the bound
func is_surrounding(var v:Vector2, var inclusive:bool = true):
	if inclusive: return a.x >= v.x && a.y >= v.y && v.x >= b.x && v.y >= b.y
	else: return a.x > v.x && a.y > v.y && v.x > b.x && v.y > b.y
	
#parse boundary from text content c with a midpoint mp and stopping point sp
func from_text(var c:String, var mp:int, var sp:int):
	if (mp == 0): mp = c.length()
	if (sp == 0): sp = c.length()
	#create the Vectors with Instruction's vectorize() method
	#its kind of like using a claymore to cut a pizza
	var v = Instruction.new(c.substr(0, mp)).vectorize()
	var v2 = Instruction.new(c.substr(mp, sp)).vectorize()
	
	_init(v, v2)
	return self

func is_zero():
	return a == Vector2.ZERO && b == Vector2.ZERO

func get_corners():
	return [Vector2(b.x, a.y), a, Vector2(a.x, b.y), b]

func get_edges():
	var c = Vector2(b.x, a.y)
	var d = Vector2(a.x, b.y)
	return [[a, c], [c, b], [b, d], [d, a]]

#check if bound intersects with an object, runs differently depending on type of input
#returns negative 1 for false, an array of indices which intersect array
func intersection(var X = null, var args:Array = []):
	if X == null:
		return -1
		
	if X is Array || X is PoolVector2Array:
		var c:bool = false
		if args.size() > 0 and args[0] is bool: c = args[0]
		return edge_set_intersection(X, c)

#return intersecting edges with bound edges from a set
#if cyclic is checked, the pair (n, 0) will be checked for intersection as well
func edge_set_intersection(var edges:PoolVector2Array, var cyclic:bool = false):
	if edges.size() == 0:
		return false
	elif edges.size() == 1: 
		return is_surrounding(edges[0])
		
	#create line segments from bound
	var bsegs = get_edges()
	
	#convert edges into point/slope form
	var blines:Array = [[0,0,0],[0,0,0],[0,0,0],[0,0,0]]
	for i in range(0, 4):
		var a:Vector2 = bsegs[i][0]
		var b:Vector2 = bsegs[i][1]
		if a.x - b.x == 0:
			blines[i][0] = INF
		else:
			blines[i][0] = (a.y - b.y) / (a.x - b.x)
		blines[i][1] = a
		blines[i][2] = b
		
	var intersections:PoolIntArray = []
	
	var s:int = -1
	if cyclic: s = 0
	
	for i in range(0, edges.size() + s):
		#translate line segment to point-slope form from element of edges
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
			
			#check if range and domain intersect, pass computations if not
			var may1:float = max(y1, d.y)
			var miy0:float = min(y0, b.y)
			var max1:float = max(x1, d.x)
			var mix0:float = min(x0, b.x)
			var max0:float = max(x0, b.x)
			var mix1:float = min(x1, d.x)
			var may0:float = max(y0, b.y)
			var miy1:float = min(y1, d.y)
			if !(may1 >= miy0 && may0 >= miy1 && max1 >= mix0 && max0 >= mix1):
				
				continue
			
			#if lines a parallel, plug 0 into both line equations to see if they are the same
			if b1 == b0:
				#check lines are vertical
				if b1 == INF:
					intersections.append(i)
				#check lines have same height
				elif -x0 * b0 + y0 == -x1 * b1 + y1:
					intersections.append(i)
				
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
			if min(mix0, mix1) <= x && x <= max(max0, max1):
				if min(miy0, miy1) <= y && y <= max(may0, may1):
					intersections.append(i)
			
	return intersections

#convert bound to string in least to greatest order
func _to_string():
	return "[" + String(b) + ", " + String(a) + "]"
