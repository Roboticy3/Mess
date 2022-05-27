class_name Triangle


#store verts in an array of PoolRealArray vertex arrays
var verts:Array

#verts stored as arrays of Vector3 and Vector2 a, b, and c for simpler syntax
var a:Array = [null, null, null]
var b:Array = [null, null, null]
var c:Array = [null, null, null]

#either input an Array of PoolRealArray for verts or a MeshDataTool and an ind face index
func _init(var data, var index:int = 0) -> void:
	if data is Array: from_array(data)
	elif data is DuplicateMap: from_dups(data, index)
	
	
func from_array(var _verts:Array) -> void:
	if _verts.size() < 3:
		return
	
	verts = _verts
	update_abc()

func from_dups(var dups:DuplicateMap, var face:int) -> void:
	var _verts:Array = [null, null, null]
	for i in range(0, 3):
		var v:int = dups.mdt.get_face_vertex(face, i)
		_verts[i] = dups.vert_to_array(v)
		_verts[i] = dups.vert_to_array(v)
	
	from_array(_verts)

func update_abc() -> void:
	for i in range(0, 3): 
		a[i] = get_vertex(0, i)
		b[i] = get_vertex(1, i)
		c[i] = get_vertex(2, i)

#get vertex data from verts, optional override PoolRealArray to not take from verts
func get_vertex(var i:int, var mode:int = 0, var override:PoolRealArray = []):
	if override.size() < 8: 
		override = verts[i]
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
func barycentric_of(var vector, var mode:int = 0,
	var unformatted:bool = true) -> Vector3:
	
	if unformatted: vector = DuplicateMap.format_vector(vector, mode)
	
	var area:float = area(mode)
	if area == 0: return Vector3.INF
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
#unformatted flag allows for Vector3, Vector2, or PoolRealArray to be passed in
func is_surrounding(var vector, var mode:int = 0,
	var unformatted:bool = true, var margin:float = 0.00001) -> bool:
		
	if unformatted: vector = DuplicateMap.format_vector(vector, mode)

	var area:float = area(mode)
	if area == 0: return false
	
	var subs:Vector3 = get_sub_areas(vector, mode)
	var total:float = subs.x + subs.y + subs.z
	if abs(total - area) < margin: 
		return true
	
	return false

#return a position of the appropriate mode from input barycentric coords
func pos_from_barycentric(var bary:Vector3, var mode:int = 0):
	return a[mode] * bary.x + b[mode] * bary.y + c[mode] * bary.z
	
func center(var mode:int = 0):
	return (a[mode] + b[mode] + c[mode]) / 3

#tranforms the triangle through a given matrix transform 
func xform_with(var transform:Transform, var inv:bool = false) -> void:
	#send positions and normals into a PoolVector3Array to be transformed
	var before:PoolVector3Array = [a[0], b[0], c[0], a[1], b[1], c[1]]
	
	var after:PoolVector3Array
	if inv: after = transform.xform_inv(before)
	else: after = transform.xform(before)
	
	#update verts and abc
	for i in range(0, 3):
		verts[i] = DuplicateMap.updated_vert_array(verts[i], after[i])
		verts[i] = DuplicateMap.updated_vert_array(verts[i], after[i + 3], 1)
		
	update_abc()
	
func _to_string(var mode:int = 0) -> String:
	var av = a[mode]
	var bv = a[mode]
	var cv = c[mode]
	if av == null: av = "null"
	if bv == null: bv = "null"
	if cv == null: cv = "null"
	return String(av) + String(bv) + String(cv)
