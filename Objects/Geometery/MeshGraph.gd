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
var vtf:Array
var vtv:Array

func _init(var _mdt:MeshDataTool, var _duplicates:DuplicateMap):
	mdt = _mdt
	duplicates = _duplicates
	
	generate_face_graphs()
	
func generate_face_graphs():
	var dups:Dictionary = duplicates.duplicates
	
	var N:int = mdt.get_face_count()
	ftf.resize(N)
	ftv.resize(N)
	
	for i in N:
		var faces:PoolIntArray = []
		var verts:Array = []
		
		for j in range(0, 3):
			var v:int = mdt.get_face_vertex(i,j)
			var a:PoolRealArray = DuplicateMap.vert_to_array(mdt, v)
			verts.append(a)
			
			#iterate through faces of each duplicate of a
			for k in dups[a]: for f in mdt.get_vertex_faces(k):
				if f == i: continue
				var added:bool = false
				for l in faces.size():
					if faces[l] == f: added = true
				if added: continue
				faces.append(f)
				
		ftf[i] = faces
		ftv[i] = verts
