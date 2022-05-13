class_name Triangle


#store verts in an array of PoolRealArray vertex arrays
var verts:Array

#verts stored as arrays of Vector3 and Vector2 a, b, and c for simpler syntax
var a:Array = [null, null, null]
var b:Array = [null, null, null]
var c:Array = [null, null, null]

#either input an Array of PoolRealArray for verts or a MeshDataTool and an ind face index
func _init(var data, var index:int = 0):
	if data is Array: from_array(data)
	elif data is MeshDataTool: from_mdt(data, index)
	
	
func from_array(var _verts:Array):
	if _verts.size() < 3:
		return
	
	verts = _verts
	#assign verts to a b and c
	for i in range(0, 3): a[i] = get_vertex(0, i)
	for i in range(0, 3): b[i] = get_vertex(1, i)
	for i in range(0, 3): c[i] = get_vertex(2, i)

func from_mdt(var mdt:MeshDataTool, var face:int):
	var verts:Array = [null, null, null]
	for i in range(0, 3):
		var v:int = mdt.get_face_vertex(face, i)
		verts[i] = DuplicateMap.vert_to_array(mdt, v)
	from_array(verts)

#get vertex data from verts, optional override PoolRealArray to not take from verts
func get_vertex(var i:int, var mode:int = 0, var override:PoolRealArray = []):
	if override.size() < 8: override = verts[i]
	return DuplicateMap.array_to_vert(override, mode)

#get area of different dimensions of the triangle based on mode
func area(var mode:int = 0) -> float:
	#default mode to 0 if it is out of range, using the same system as array_to_vert()
	if mode < 1 || mode > 2: mode = 0
	
	var av = a[mode]
	var bv = b[mode]
	var cv = c[mode]
	
	var ab = av.distance_to(bv)
	var sinbac = abs(sin((bv - av).angle_to(cv - av)))
	var ac = av.distance_to(cv)
	
	return float(ac * ab * sinbac / 2)

#get barycentric coordinates of input vector in the space of the given mode
func barycentric_of(var vector, var mode:int = 0) -> Vector3:
	return get_sub_areas(vector, mode) / area(mode)

#get the area of a sub-triangle with one vertex vert replaced with vector
#vert 0, 1, and 2 correspond to a, b, and c respectively
func get_sub_area(var vector:PoolRealArray, var vert:int = 0, mode:int = 0) -> float:
	
	#select array to modify based on vert
	var v = a
	if vert == 1: v = b
	elif vert == 2: v = c

	#save current state of part mode of v, then update v
	var _v = v[mode]
	v[mode] = get_vertex(vert, mode, vector)
	#get area of updated triangle
	var sub_v:float = area(mode)
	#then undo changes to v
	v[mode] = _v
	
	return sub_v

func get_sub_areas(var vector:PoolRealArray, var mode:int = 0) -> Vector3:
	var sub_a:float = get_sub_area(vector, 0, mode)
	var sub_b:float = get_sub_area(vector, 1, mode)
	var sub_c:float = get_sub_area(vector, 2, mode)
	return Vector3(sub_a, sub_b, sub_c) 

#check if this is surrounding a vector
func is_surrounding(var vector:PoolRealArray, var mode:int = 0,
	var margin:float = 0.001) -> bool:
	
	var subs:Vector3 = get_sub_areas(vector, mode)
	var total:float = subs.x + subs.y + subs.z
	var area:float = area(mode)
	if abs(total - area) < margin: 
		return true
	
	return false
	
	
func _to_string():
	return String(verts)
