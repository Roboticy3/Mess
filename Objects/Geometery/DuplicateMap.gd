class_name DuplicateMap

var mdt:MeshDataTool
var duplicates:Dictionary
#booleans for whether positions, normals, and uvs are stored respectively
var modes:Array = [true, true, true]

func _init(var _mdt:MeshDataTool, 
	var positions:bool = true, var normals:bool = true, var uvs:bool = true):

	modes[0] = positions
	modes[1] = normals
	modes[2] = uvs
	
	mdt = _mdt
	duplicates = find_duplicates()

#return a Dictionary of PoolRealArray and PoolIntArrays keying sets of vertices to positions
func find_duplicates():
	
	var verts:Dictionary= {}
	
	#loop through each face
	for i in mdt.get_face_count():
		#see if each vertex of each face already exists
		for j in range(0, 3):
			var k:int = mdt.get_face_vertex(i, j)
			#key vertex by its properties, preserving split edges
			var v:PoolRealArray = vert_to_array(k)
		
			#if vertex already exists, add a match
			if verts.has(v):
				verts[v].append(k)
			#if not, add vertex position with index as first match
			else:
				#add vertex position to dictionary
				verts[v] = [k]
	
	return verts

#copy a set of duplicate vertices (i in duplicates) into an indexmap,
#then increment the number of unique vertices in the indexmap, returns new count
func map_duplicates(var indexmap:Dictionary,
	var i:PoolRealArray, var count:int = 0):
	
	var a:PoolIntArray = duplicates[i]
	for j in a.size():
		indexmap[a[j]] = count
	return count + 1
	
func get_expected_key_size() -> int:
	var s:int = 0
	if modes[0]: s += 3
	if modes[1]: s += 3
	if modes[2]: s += 2
	return s
	
func getk(var a:PoolRealArray) -> PoolIntArray:
	if a.size() < get_expected_key_size(): return PoolIntArray()
	return duplicates[a]
			
#convert a vertex on an mdt to a PoolRealArray of properties
func vert_to_array(var i:int = 0) -> PoolRealArray:
	
	var p:Vector3 = mdt.get_vertex(i)
	var n:Vector3 = mdt.get_vertex_normal(i)
	var u:Vector2 = mdt.get_vertex_uv(i)
	return format_vectors(p, n, u)
		
#convert a return from the mdata method to a vertex array
func mdata_to_array(var mdata:Array):
	#convert coverts to vert arrays
	var p:Vector3 = mdata[1]
	var u:Vector2 = mdata[3]
	var n:Vector3 = mdata[2]
	return format_vectors(p, n, u)

#decode an array from vert_to_array() back into a position (0), normal (1), or uv (2) based on mode
#start is the starting index in a from which to decode
func array_to_vert(var a:PoolRealArray, var mode:int = 0, var start:int = 0):
	#if array is too small, return null
	if a.size() < start + get_expected_key_size(): return null
	#return parts of the array relevant to mode
	if mode == 2:
		return Vector2(a[start + 6], a[start + 7])
	elif mode == 1:
		return Vector3(a[start + 3], a[start + 4], a[start + 5])
	else:
		return Vector3(a[start], a[start + 1], a[start + 2])

#array_to_vert without the size check so it can exist statically
static func array_to_vert_static(var a:PoolRealArray, var mode:int = 0, var start:int = 0):
	#return parts of the array relevant to mode
	if mode == 2:
		return Vector2(a[start + 6], a[start + 7])
	elif mode == 1:
		return Vector3(a[start + 3], a[start + 4], a[start + 5])
	else:
		return Vector3(a[start], a[start + 1], a[start + 2])

#update a vertex array with new data
static func updated_vert_array(var a:PoolRealArray = [], var data = null, var mode:int = 0):
	
	#reset vertex if it hasn't been completed yet
	if a.size() < 8:
		a = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	if mode == 2 && data is Vector2:
		a[6] = data.x
		a[7] = data.y
	elif mode == 1 && data is Vector3:
		a[3] = data.x
		a[4] = data.y
		a[5] = data.z
	elif data is Vector3:
		a[0] = data.x
		a[1] = data.y
		a[2] = data.z
		
	return a

#change vector into a PoolRealArray
static func format_vector(var vector, var mode:int = 0) -> PoolRealArray:
	var is_uv:bool = vector is Vector2 && mode == 2
	var is_vec:bool = is_uv || (vector is Vector3 && mode != 2)
	#if the vector is not a PoolRealArray, but is a Vector2 or 3,
	#make a new PoolRealArray with vector's data in place according to mode
	if !(vector is PoolRealArray):
		if is_vec:
			vector = updated_vert_array(PoolRealArray(), vector, mode)
		#if there was no vector to begin with, just make a PoolRealArray of zeroes
		else: vector = PoolRealArray([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	return vector

func format_vectors(var p:Vector3, var n:Vector3, var u:Vector2) -> PoolRealArray:
	var v:PoolRealArray = []
	if modes[0]: v.append_array([p.x, p.y, p.z])
	if modes[1]: v.append_array([n.x, n.y, n.z])
	if modes[2]: v.append_array([u.x, u.y])
	return v
		
#add a vertex array from vert_to_array() into a SurfaceTool
func add_array_to_surface(var st:SurfaceTool, var a:PoolRealArray) -> void:
	if modes[1]: st.add_normal(array_to_vert(a, 1))
	if modes[2]: st.add_uv(array_to_vert(a, 2))
	if modes[0]: st.add_vertex(array_to_vert(a, 0))

func _to_string() -> String:
	return String(duplicates)

