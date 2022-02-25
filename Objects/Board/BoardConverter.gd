class_name BoardConverter

#BoardConverter Class made by Pablo Ibarz
#created in December 2021

#BoardConverter started as a converter for things related to well, the board
#but now its a more general use collection of static functions because I'm too lazy to learn how to use a singleton

#path to the default mesh
static func default_mesh():
	return "res://Instructions/default.obj"

#return the face index, position in space and normal of mesh from a uv coordinate pos
#optionally send in a mask of face indices to exclude (mask_type == 0), include (mask_type == 1), or search first (mask_type == 2)
#TODO make search first into separate function which searches faces recursively from a starting face in mask through its connected faces
static func uv_to_mdata(var mdt:MeshDataTool, var pos:Vector2 = Vector2.ZERO, 
	var mask:Array = [], var mask_type:int = 2):
	
	#don't try to work with null positions
	if pos == null: 
		return null
	
	#integer array to convert from index to real index in mdt using mask
	#not setting anything to true_indices will lead to it being ignored in favor of regular ones
	var true_indices = []
	var size:int = 0
	
	#mask type 2 iterates through verts in the mask first
	if mask_type == 2:
		#same number of iterations as face count because every face can be searched eventually
		size = mdt.get_face_count()
		#check for indices of mdt faces in mask, and add them to the front of true indices
		#this is slower for larger masks because push_front causes a lot of re-indexing
		for i in mdt.get_face_count():
			if i in mask:
				true_indices.push_front(i)
			else:
				true_indices.append(i)
		
	#ignore empty masks in other modes, even if mask_type == 1 and mask.empty() should cause and empty loop
	elif mask.empty(): 
		size = mdt.get_face_count()
	
	#otherwise, create a mask
	else:
		#mask type 0 excludes verts in the mask
		if mask_type == 0:
			for i in mdt.get_face_count():
				if !(i in mask):
					true_indices.append(i)
			size = true_indices.size()
		#mask type 1 includes only verts in the mask
		elif mask_type == 1:
			size = mask.size()
			true_indices = mask
	
	#convert pos into Vector3 with y=0 to be compatible with Triangle's Vector3 components
	var p:Vector3 = Vector3(pos.x, 0, pos.y)
	
	for j in size:
		#assume size is the same as face count
		var i = j
		#if j fits in true_indices, reassign i to the true index
		if j < true_indices.size(): 
			i = true_indices[j]
		
		#get positions and uvs of the triangle
		var t = get_face_vertices(mdt, i)
		#copy positions of t into another triangle to calculate position later
		var u = t[0]
		
		#convert uvs into Vector3 with y=0
		for k in t[1].size():
			t[1][k] = Vector3(t[1][k].x, 0, t[1][k].y)
		#send uvs expanded into 3D into t
		t = Triangle.new(t[1])
		
		#check if the right triangle has been found
		if t.is_surrounding(p):
			#get the barycentric coordinates of p in t
			var b = t.barycentric(p)
			#then use the bcoords to weigh the positions of the tri's verts into an average for output
			#this is why the position copy was made earlier
			var out = b[0] * u[0] + b[1] * u[1] + b[2] * u[2]
			#if mask mode is 2, add surrounding faces to mask so the same mask so other functions can use the same mask multiple times for faster search
			if mask_type == 2:
				var faces:PoolIntArray = []
				for v in range(0, 3):
					faces.append_array(mdt.get_vertex_faces(mdt.get_face_vertex(i, v)))
				mask.append_array(faces)
			mask.append(i)
			#return data about the triangle
			return [i, out, mdt.get_face_normal(i), j]
	
	#if no solution is found, return null
	return null
	
#retrieve an Arrays object from a face index of a MeshDataTool
static func get_face_vertices(var mdt:MeshDataTool, var i:int):
	return [[mdt.get_vertex(mdt.get_face_vertex(i, 0)),
	mdt.get_vertex(mdt.get_face_vertex(i, 1)),
	mdt.get_vertex(mdt.get_face_vertex(i, 2))],
	[mdt.get_vertex_uv(mdt.get_face_vertex(i, 0)),
	mdt.get_vertex_uv(mdt.get_face_vertex(i, 1)),
	mdt.get_vertex_uv(mdt.get_face_vertex(i, 2))]]

#convert from uv coordinate to square using the size in squares of the board
static func uv_to_square(var size:Vector2, var pos):
	if pos == null: return null
	var large = pos * size
	large.x = floor(large.x)
	large.y = floor(large.y)
	return large
	
#convert from square on the board to uv coordinates
static func square_to_uv(var size:Vector2 = Vector2.ONE, var pos:Vector2 = Vector2.ZERO):
	var square = Vector2.ONE/size
	#add 1 to pos to adjust for board starting at 0, 0
	#subtract one half of the square size to get the uv coordinate in the center of the target square
	return (pos + Vector2.ONE)/(size) - square/2

#combine space converters into single function
static func square_to_mdata(var mdt:MeshDataTool = null, var size:Vector2 = Vector2.ONE, var pos:Vector2 = Vector2.ZERO):
	var uv = square_to_uv(size, pos)
	return uv_to_mdata(mdt, uv)

#take an input board mdt, board, and piece to return a Transform for the associated PieceMesh accosiated with piece on the mdt constructed from a BoardMesh
static func square_to_transform(var mdt:MeshDataTool, 
	var board:Board, var piece:Piece):
	
	#reference useful piece properties in other variables
	var pos:Vector2 = piece.pos
	var table:Dictionary = piece.table
	
	#create a new transform to modify
	var transform:Transform = Transform()
	
	#get mesh data on square center for position and normal of the piece
	#if the piece is not centered on its origin, offsets can be created
	var mdata = square_to_mdata(mdt, board.size, pos)
	#skip function if mdata returns null
	if mdata == null:
		return transform
	
	#ROTATION
	#go through each of the transformation steps
	#check piece's settings on each before running each function
	if table["rotate_mode"] != 2:
		transform.basis = square_to_basis(mdt, board, piece, mdata)
		
	#SCALE
	#scale does not need the mdata step, but has to be executed after rotation
	#if scale mode is 0, scale piece by board's piece scale param
	if table["scale_mode"] == 0:
		transform = transform.scaled(Vector3.ONE * board.table["piece_scale"])
	#TODO if scale mode is 1, dynamically scale piece, this is left up to PieceMesh
	#if scale mode is 2, ignore scaling
	
	#TRANSLATION
	#translate the piece to the center of the square after the scaling and rotation steps
	if table["translate_mode"] != 2:
		transform.origin = mdata[1]
	
	return transform

#convert the normal of a square on the board to a set of basis vectors
static func square_to_basis(var mdt:MeshDataTool, var board:Board, 
	var piece:Piece, var mdata:Array):
		
	if mdata == null: return Basis()
	
	#up vector will take the normal of the square
	var up:Vector3 = mdata[2].normalized()
	
	#forward vector will try to look at square in forward direction from piece, and use the relative directions to form a vector
	var v:Vector2 = piece.get_forward()
	var d = 0
	#check if piece's direction goes out of bounds, if so try next orthogonal direction
	#keep trying orthogonal directions until a valid spot is found
	while !board.is_surrounding(piece.pos + v) && d < 4:
		v = v.tangent()
		d += 1
	#if no directions are valid, just default to Vector3.forward
	var mf = [-1, Vector3.FORWARD, Vector3.UP]
	if d < 4 && v != Vector2.ZERO:
		mf = square_to_mdata(mdt, board.size, piece.pos + v)
	
	#process mf[1] into a vector that is orthogonal to up
	#these vectors are not necesarily orthogonal, but a true forward can be computed from up and right later
	var fd:Vector3 = (mf[1] - mdata[1]).normalized()
	
	#last basis vector is cross of up and forward
	var rt = up.cross(fd)
	
	#to force fd to be orthogonal to up, cross up with right
	fd = up.cross(rt)
	
	#finally, send the basis as a transform into self.transform
	var b:Basis = Basis(rt, up, fd)
	
	return b

#run square to box and add mesh as a CSGMesh child of an input parent node
static func square_to_child(var parent:Node, var mdt:MeshDataTool, var size:Vector2, 
	var square:Vector2=Vector2.ZERO, var material:Material = SpatialMaterial.new(), var name:String = ""):
	
	var m = square_to_box(mdt, size, square, parent)
	var csg = CSGMesh.new()
	csg.mesh = m
	csg.material = material
	if name.empty(): name = "Square " + String(size)
	csg.name = name
	parent.add_child(csg)
	
	return csg

#WIP return a convex cube mesh bounding a square
static func square_to_box(var mdt:MeshDataTool, var size:Vector2, var square:Vector2=Vector2.ZERO,
	#node input is only used for debugging, usually ignore
	var node:Node = null):
		
	#get uv bound of square
	var b:Bound = square_to_bound(size, square)
	
	#keep faces intersecting square as indices keying arrays of inner verts
	var faces:Dictionary = {}
	#keep vertices connected to verts in the square as indices keying position
	var verts:Dictionary = {}
	#keep verts which are outside the square to know which ones to move late
	var outside:PoolIntArray = []
	
	#loop through verts of faces and add every face connected to a vert inside the square
	for i in mdt.get_face_count():
		
		#loop through verts/edges of i
		for j in range(0, 3):
			var v:int = mdt.get_face_vertex(i, j)
			#skip verts that have already been handled
			if v in verts:
				continue
			
			#if vertex is in b, add connected faces and their vertices to dicts
			var uv:Vector2 = mdt.get_vertex_uv(v)
			if b.is_surrounding(uv):
				vert_to_triangle_fan(mdt, v, verts, faces)
			
			#otherwise, check if uv edge between v and the next face vertex intersects b
			else:
				#get edge and verts
				var e:int = mdt.get_face_edge(i,j)
				v = mdt.get_edge_vertex(e, 0)
				uv = mdt.get_vertex_uv(v)
				var u:int = mdt.get_edge_vertex(e, 1)
				var uv2:Vector2 = mdt.get_vertex_uv(u)
				
				#cursedmathgames
				var cross = b.edge_set_intersection([uv, uv2])
				if !cross.empty():
					#add verts connected to both v and u
					vert_to_triangle_fan(mdt, e, verts, faces, true)
	
	#set outside verts by checking through keys
	for v in verts.keys():
		var uv:Vector2 = mdt.get_vertex_uv(v)
		if !b.is_surrounding(uv):
			outside.append(v)
	
	#TODO slide vertices into corners of square
	
	#get vertex corners of the square
	var corners:Array = []
	var c = b.get_corners()
	corners.resize(4)
	var mask:Array = Array()
	#loop through each corner and retrieve their mdata
	for i in range(0, 4):
		#clamp uvs to a range that is less likely return null for being OOB
		c[i].y = max(min(c[i].y, 0.999), 0.001)
		c[i].x = max(min(c[i].x, 0.999), 0.001)
		corners[i] = uv_to_mdata(mdt, c[i], mask)
		
	
	#find closest point on the square to send outside vertices to
	var outpos:PoolVector3Array = []
	outpos.resize(outside.size())
	for i in outside.size():
		outpos[i] = mdt.get_vertex(outside[i])
	#debug_positions(node, outpos)
	
	#construct a mesh from inner verts and connected outer verts
	var st = slice_mesh(mdt, verts.keys(), faces.keys(), verts)

	var m:Mesh = Mesh.new()
	return st.commit(m)

#convert a square in uv space to a Bound object
static func square_to_bound(var size:Vector2, var square:Vector2):
	var center:Vector2 = square_to_uv(size, square)
	var half_square:Vector2 = Vector2(1 / size.x, 1 / size.y) * 0.5
	return Bound.new(center + half_square, center - half_square)

#convert mouse position in pixels from the top left to uv from the bottom left
static func mpos_to_screenuv(var pos:Vector2):
	#find size of screen at the time to normalize pos, then invert pos.y
	pos /= OS.window_size
	pos.y = 1 - pos.y
	return pos

#convert raycast hit to uv on mesh by projecting mesh onto camera and seeing if any triangles surround the input position
static func mpos_to_uv(var mdt:MeshDataTool, var board:Transform, 
	var transform:Transform, var pos:Vector3 = Vector3.ZERO):
	
	var p:Vector3 = transform.xform_inv(pos)
	#send p into xy plane
	p.z = 0
	
	#Triangle array of triangles projected into Camera space
	var triangles:Array = []
	#array of distances used to sort triangles
	var distances:PoolRealArray = []
	
	#loop through each triangle on the mdt and add triangles that surround p
	for i in mdt.get_face_count():
		#skip faces facing away from the camera
		if mdt.get_face_normal(i).dot(transform.basis.z) < 0:
			continue
			
		#get camera space position of triangle
		var tri = get_face_vertices(mdt, i)
		#project positions into world space, and then camera space
		var t = tri[0]
		for j in range(0, 3):
			t[j] = board.xform(t[j])
			t[j] = transform.xform_inv(t[j])
			t[j].z = 0
		tri = Triangle.new(tri[0], tri[1])

		#check if triangle is surrounding modded pos p
		if tri.is_surrounding(p):
			triangles.append(tri)
			t = get_face_vertices(mdt, i)
			t = Triangle.new(t[0], t[1])
			distances.append(t.center().distance_to(pos))

	#get closest triangle to p
	var d = INF
	var m = -1
	for i in distances.size():
		var t = get_face_vertices(mdt, i)
		t = Triangle.new(t[0], t[1])
		if distances[i] < d:
			m = i
	#if nothing is less than infinity, something is horribly wrong
	if m == -1:
		return null
	

	#return barycentric uv coords of p with the mth element of triangles
	return triangles[m].uv(p)

#import mesh from .obj path
static func path_to_mesh(var path:String = "", var debug:bool = false):
	#parse board using parser script into loadable mesh
	var m = ObjParse.parse_obj(path, path.substr(0, path.length() - 3) + "mtl", debug)
	
	#check if mesh was created correctly
	var mdt:MeshDataTool = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	if mdt.get_vertex_count() == 0:
		path = default_mesh()
		m = ObjParse.parse_obj(path, path.substr(0, path.length() - 3) + "mtl", debug)
	
	return m

#create a convex or concave shape from a mesh dependant on whether or not the mesh is flat
static func mesh_to_shape(var m:Mesh):
	#create the collision shape of the board as a concave shape if and only if the board is not flat
	
	#plane from first face by which to compare every other face and determine if the mesh is flat
	var flat = true
	var plane = Plane()
	
	#why is this necesary?
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	#loop through faces until a valid plane is found
	for i in mdt.get_face_count():
		if plane == Plane():
			var t = get_face_vertices(mdt, i)
			t = Triangle.new(t[0], t[1])
			plane = t.plane(mdt.get_face_normal(i))
		else:
			break
	
	#loop through verts and add them to an array of vertices
	#check if each vertex projects into the plane, if all verts are roughly coplanar, convex shapes will be a better solution
	for i in range(0, mdt.get_vertex_count()):
		var p = mdt.get_vertex(i)
		if (plane.project(p) - p).length() != 0:
			flat = false
			break
	
	var shape
	#if mesh is not flat, use a concave shape
	if !flat:
		shape = m.create_trimesh_shape()
	else:
		#if mesh is not flat, make a convex shape
		m.create_convex_shape()
	
	return shape

#slice mesh in mdt into a smaller mesh from an array of vertex indices and face indices to take from
#the last argument can be used to send in new positions for vertices
#returns a surface tool
static func slice_mesh(var mdt:MeshDataTool, var vertex_indices:PoolIntArray,
		var face_indices:PoolIntArray, var positions:Dictionary = {}):
	
	#construct a mesh using surface tool
	var st:SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES) 
	var m:Mesh = Mesh.new()
	
	#"sift" vertex indices into an integer range from 0 to n, link to original indices with a key
	var indexmap:Dictionary = {}
	var sorted:Array = Array(vertex_indices)
	sorted.sort()
	for i in sorted.size():
		indexmap[sorted[i]] = i
		i += 1
	
	#go through sorted verts and add them to the surface tool
	for v in sorted:
		st.add_normal(mdt.get_vertex_normal(v))
		st.add_uv(mdt.get_vertex_uv(v))
		var pos:Vector3
		#use position dictionary so new positions can be sent in by other functions
		if v in positions:
			pos = positions[v]
		else:
			pos = mdt.get_vertex(v)
		st.add_vertex(pos)
	
	#use sifted indices to index faces in groups of 3
	for f in face_indices:
		for i in range(0, 3):
			var v = mdt.get_face_vertex(f, i)
			st.add_index(indexmap[v])
	
	return st

#get all verts and faces connected to an index in mdt
#return [0] is vert dictionary, return [1] is face dicitonary
static func vert_to_triangle_fan(var mdt:MeshDataTool, var i:int = 0, 
	var verts:Dictionary = {}, var faces:Dictionary = {}, var edges:bool = false):
	
	#get connected faces
	var fs:Array
	if edges:
		fs = mdt.get_edge_faces(i)
	else:
		fs = mdt.get_vertex_faces(i)
	
	#loop through faces and add their verts
	for f in fs:
		#add face to faces dict so calling function can see the faces being searched
		faces[f] = get_face_vertices(mdt, f)[0]
		for j in range(0, 3):
			var v = mdt.get_face_vertex(f, j)
			#same deal as faces
			verts[v] = mdt.get_vertex(v)
	
	#in case vert_to_triangle_fan doesnt have dictionary args, return them back out
	return [verts, faces]

#cast out a ray from the camera, given a physics state s
static func raycast(var p:Vector2, var c:Camera, 
	var w:World, var v:float = INF, var mask:int = 0x7FFFFFFF):
	
	#get physics state of the current scene
	var s = w.direct_space_state
	#get ray intersection with that scene
	var r = s.intersect_ray(
		c.project_ray_origin(p), c.project_ray_normal(p) * v,
		[], mask)
	#if the intersection lands, return r
	if !r.empty():
		return r
	return null

#add CSGsphere children to node at relative positions
static func debug_positions(var node:Node = null, var positions:PoolVector3Array = [], 
	var radius:float = 0.1, var material:Material = SpatialMaterial.new()):
	
	#remove old debug objects
	for c in node.get_children():
		if c.name.find("debug") != -1:
			node.remove_child(c)
	
	#add new ones
	for p in positions:
		var csg = CSGSphere.new()
		csg.radius = radius
		csg.material = material
		csg.transform.origin = p
		csg.name = "debug " + String(p)
		node.add_child(csg)
