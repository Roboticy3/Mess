class_name MeshGraph

#Store a mesh as graphs of connected faces and vertices
#Attain sets of faces and vertexes connected to an input index for any face or vertex
#created May 2022

var mdt:MeshDataTool
var duplicates:DuplicateMap

#Arrays of PoolInt/RealArrays, each index is a face or vertex and their contents are indices of connected faces or vertices
#e.g. ftf = face to face so [[faces connected to face 0 of mdt], [connected to 1], [connected to 2]...]
var ftf:Array
var ftv:Array
var vtf:Dictionary
var vtv:Dictionary

func _init(var _mdt:MeshDataTool, var _duplicates:DuplicateMap):
	mdt = _mdt
	duplicates = _duplicates
	
	generate_graphs()
	
func generate_graphs():
	var dups:Dictionary = duplicates.duplicates
	
	var N:int = mdt.get_face_count()
	ftf.resize(N)
	ftv.resize(N)
	
	for i in N:
		var faces:PoolIntArray = []
		var verts:Array = []
		
		#iterate through vertexes of this face
		for j in range(0, 3):
			var v:int = mdt.get_face_vertex(i,j)
			var a:PoolRealArray = DuplicateMap.vert_to_array(mdt, v)
			verts.append(a)

			var f:PoolIntArray = []
			if vtf.has(a): f = vtf[a]
			else: f = generate_vertex_faces(a, dups)
			
			#add previously unadded faces connected to v to faces
			for k in f:
				if pool_int_array_has(faces, k): continue
				faces.append(k)
			#then add faces connected to v of vtf graph
			vtf[a] = f
			
			#add vertices other than v on face i to v of vtv graph
			var u:int = mdt.get_face_vertex(i,(j+1)%3)
			var b:PoolRealArray = DuplicateMap.vert_to_array(mdt, u)
			var w:int = mdt.get_face_vertex(i,(j+2)%3)
			var c:PoolRealArray = DuplicateMap.vert_to_array(mdt, w)
			if !vtv.has(a): vtv[a] = [b, c]
			else:
				if !vtv[a].has(b): vtv[a].append(b)
				if !vtv[a].has(c): vtv[a].append(c)
			
				
		ftf[i] = faces
		ftv[i] = verts
				
func generate_vertex_faces(var vert:PoolRealArray, 
	var dups:Dictionary = duplicates.duplicates):

	var faces:PoolIntArray
	for i in dups[vert]:
			for f in mdt.get_vertex_faces(i):
				if pool_int_array_has(faces, f): continue
				faces.append(f)
	return faces

#test if PoolInt/RealArray arr has element num
func pool_int_array_has(var arr:PoolIntArray, var num:int):
	var added:bool = false
	for i in arr.size():
		if arr[i] == num: 
			added = true
			break
	return added
