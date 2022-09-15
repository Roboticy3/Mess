class_name BoardConverter

#BoardConverter Class made by Pablo Ibarz
#created in December 2021

#BoardConverter started as a converter for things related to well, the board
#but now its a more general use collection of static functions because I'm too lazy to learn how to use a singleton

#search faces linearly via their index in a MeshDataTool
static func uv_to_mdata_linear(var dups:DuplicateMap, var pos:Vector2 = Vector2.ZERO) -> Array:
	var vert:PoolRealArray = DuplicateMap.format_vector(pos, 2)
	
	#store closest triangle to give a return value when no valid triangle was found
	var distance:float = INF
	var closest:Array = []
	
	var mdt:MeshDataTool = dups.mdt
	
	for i in mdt.get_face_count():
		var a:Array = uv_to_mdata_step(dups, i, pos, vert)
		if a[5]: return a
			
		var d:float = a[4].barycentric_of(pos).length()
		if d < distance:
			distance = d
			closest = a

	return closest
	
#search faces with a breadth-first search of faces starting from a guess
static func uv_to_mdata_graph(var graph:MeshGraph, var dups:DuplicateMap, 
	var pos:Vector2 = Vector2.ZERO, var guess:int = 0) -> Array:

	var vert:PoolRealArray = DuplicateMap.format_vector(pos, 2)
	
	#queue of faces to check
	var queue:PoolIntArray = [guess]
	
	#set of searched faces
	var searched:Dictionary = {
		guess:uv_to_mdata_step(dups, guess, pos, vert)
		}
	#return based on whether guess was correct
	if searched[guess][5]: 
		return searched[guess]
		
	#store closest triangle to give a return value when no valid triangle was found
	var distance:float = INF
	var closest:Array = []
	
	var _iters:int = 0
	
	while !queue.empty():
		var i:int = queue.size() - 1
		var f:int = queue[i]
		var a:Array = searched[f]
		
		var d:float = a[4].barycentric_of(pos).length()
		if d < distance:
			distance = d
			closest = a
		
		queue.remove(i)
		
		for j in graph.ftf[f]:
			if searched.has(j): continue
			searched[j] = uv_to_mdata_step(dups, j, pos, vert)
			a = searched[j]
			#if the right face is found, return it
			if a[5]: 
				return a
			queue.append(j)
			
		_iters += 1

	#print(iters)
	return closest

#check if mdt face i surroundins pos,
#if so, return an mdata array for pos in i
#otherwise, return b.length() for a least distance check in uv_to_mdata methods
static func uv_to_mdata_step(var dups:DuplicateMap, var i:int,
	var pos:Vector2, var vert:PoolRealArray) -> Array:
	
	#optimize triangle creation by making input vert array statically 
	var _verts:Array = [null, null, null]
	for j in range(0, 3):
		var v:int = dups.mdt.get_face_vertex(i, j)
		_verts[j] = dups.vert_to_array(v, true)
	var t:Triangle = Triangle.new(_verts)
	
	var b:Vector3 = t.barycentric_of(vert, 2, false)
	var a:Array = [i, t.pos_from_barycentric(b),
			dups.mdt.get_face_normal(i), pos, t, false]
	
	if t.is_surrounding(vert, 2):
		a[5] = true
	
	return a

#retrieve an Arrays object from a face index of a MeshDataTool
static func get_face_vertices(var dups:DuplicateMap, var i:int) -> Array:
	var mdt:MeshDataTool = dups.mdt
	return [dups.vert_to_array(mdt.get_face_vertex(i, 0)),
			dups.vert_to_array(mdt.get_face_vertex(i, 1)),
			dups.vert_to_array(mdt.get_face_vertex(i, 2))]

#convert from uv coordinate to square using the size in squares of the board
static func uv_to_square(var size:Vector2, var pos:Vector2) -> Vector2:
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

#convert a square in uv space to a Bound object
static func square_to_bound(var size:Vector2, var square:Vector2) -> Bound:
	var center:Vector2 = square_to_uv(size, square)
	var half_square:Vector2 = Vector2(1 / size.x, 1 / size.y) * 0.5
	return Bound.new(center + half_square, center - half_square)

#combine space converters into single function
static func square_to_mdata(var graph:MeshGraph, var dups:DuplicateMap,
	var size:Vector2 = Vector2.ONE, var pos:Vector2 = Vector2.ZERO) -> Array:
	var uv = square_to_uv(size, pos)
	return uv_to_mdata_graph(graph, dups, uv)

#take an input board mdt, board, and piece to return a Transform for the associated PieceMesh accosiated with piece on the mdt constructed from a BoardMesh
static func square_to_transform(var graph:MeshGraph, var dups:DuplicateMap,
	var board:Node, var piece:Piece) -> Transform:
	
	
	#reference useful piece properties in other variables
	var pos:Vector2 = piece.get_pos()
	var table:Dictionary = piece.table
	
	#create a new transform to modify
	var transform:Transform = Transform()
	
	#get mesh data on square center for position and normal of the piece
	#if the piece is not centered on its origin, offsets can be created
	var mdata = square_to_mdata(graph, dups, board.size, pos)
	#skip function if mdata returns null
	if mdata == null:
		return transform
	
	#ROTATION
	#go through each of the transformation steps
	#check piece's settings on each before running each function
	if table["rotate_mode"] != 2:
		transform.basis = square_to_basis(graph, dups, board, piece, mdata)
		
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
static func square_to_basis(var graph:MeshGraph, var dups:DuplicateMap,
	var board:Node, var piece:Piece, var mdata:Array):
	
	#up vector will take the normal of the square
	var up:Vector3 = mdata[2].normalized()
	
	#forward vector will try to look at square in forward direction from piece, and use the relative directions to form a vector
	var v:Vector2 = piece.get_forward()
	var d = 0
	#check if piece's direction goes out of bounds, if so try next orthogonal direction
	#keep trying orthogonal directions until a valid spot is found
	while !board.is_surrounding(piece.get_pos() + v) && d < 4:
		v = v.tangent()
		d += 1
	#if no directions are valid, just default to Vector3.forward
	var mf = [-1, Vector3.FORWARD, Vector3.UP]
	if d < 4 && v != Vector2.ZERO:
		mf = square_to_mdata(graph, dups, board.size, piece.get_pos() + v)
	
	#process mf[1] into a vector that is orthogonal to up
	#these vectors are not necesarily orthogonal, but a true forward can be computed from up and right later
	var fd:Vector3 = (mf[1] - mdata[1]).normalized()
	
	#last basis vector is cross of up and forward
	var rt = up.cross(fd)
	
	#to force fd to be orthogonal to up, cross up with right
	fd = rt.cross(up)
	
	#finally, send the basis as a transform into self.transform
	var b:Basis = Basis(rt, up, fd)
	
	return b

#import mesh from .obj path
static func path_to_mesh(var path:String = "", var debug:bool = false):
	#parse board using parser script into loadable mesh
	var m := ObjParse.parse_obj(path, path.substr(0, path.length() - 3) + "mtl", debug)
	
	#if mesh was not created correctly, read from default mesh path
	if m.get_surface_count() == 0:
		path = "Instructions/default/meshes/default.obj"
		m = ObjParse.parse_obj(path, path.substr(0, path.length() - 3) + "mtl", debug)
	
	return m

#create a convex or concave shape from a mesh dependant on whether or not the mesh is flat
static func mesh_to_shape(var m:Mesh):
	return m.create_trimesh_shape()

#fit uv to the square between Vector2.ZERO and Vector2.ONE
static func clamp_uv(var uv:Vector2):
	uv.x = fmod(uv.x, 1)
	uv.y = fmod(uv.y, 1)
	return uv

#cast out a ray from the camera, given a physics state s
static func raycast(var p:Vector2, var c:Camera, 
	var w:World, var v:float = INF, var mask:int = 0x7FFFFFFF):
	
	#get physics state of the current scene
	var s = w.direct_space_state
	#origin and normal of the camera
	var o:Vector3 = c.project_ray_origin(p)
	var n:Vector3 = c.project_ray_normal(p)
	#get ray intersection with that scene
	var r = s.intersect_ray(o, o + n * v, [], mask)
	#if the intersection lands, return r
	if !r.empty():
		return r
	return null

#add CSGsphere children to node at relative positions
#setting mode to 1 will stop the method from deleting old csgballs
static func debug_positions(var node:Node = null, var positions:Array = [], 
	var radius:float = 0.1, var mode:int = 0, var albedo:Color = Color.white):
	
	#remove old debug objects
	if mode != 1:
		for c in node.get_children():
			if c.name.find("debug") != -1:
				node.remove_child(c)
				
	#if position map is empty, exit function
	if positions.empty(): return
	
	#checks if positions is an Array of PoolRealArray, assumes all elements are of same type
	var t:bool = positions[0] is PoolRealArray
	
	var mat:SpatialMaterial = SpatialMaterial.new()
	mat.albedo_color = albedo
	
	#add new ones
	for i in positions.size(): 
		var p = positions[i]
		#if positions is an array, recursively call method across its elements,
		#shift color of successive recursions
		if p is Array:
			debug_positions(node, p, radius, 1, albedo)
			continue
			
		if t:
			p = DuplicateMap.array_to_vert_static(p)
		
		var csg = CSGSphere.new()
		csg.radius = radius
		csg.material = mat
		csg.transform.origin = p
		csg.name = "debug " + String(p)
		node.add_child(csg)

#debug positions alternative which instead takes a MeshDataTool and an array of vertex indices as arguments
static func debug_vertices(var node:Node, var mdt:MeshDataTool, var positions:PoolIntArray = [],
	var mode:int = 0, var radius:float = 0.1):
		
	if positions.size() == 0:
		return
	
	var p:PoolVector3Array = PoolVector3Array()
	p.resize(positions.size())
	
	for i in p.size():
		p[i] = mdt.get_vertex(positions[i])
	
	debug_positions(node, p, mode, radius)


static func pieces_to_string(var pieces:Dictionary) -> String:
	var s:String = ""
	
	#find the smallest square that contains all of the pieces
	var minimum:Vector2 = Vector2.INF
	var maximum:Vector2 = -Vector2.INF
	for v in pieces:
		if v.x < minimum.x: minimum.x = v.x
		if v.y < minimum.y: minimum.y = v.y
		if v.x > maximum.x: maximum.x = v.x
		if v.y > maximum.y: maximum.y = v.y
	
	#fill the tiles with pieces in them with the first char of their name, fill the others with dots
	for r in range(minimum.y, maximum.y + 1):
		for c in range(minimum.x, maximum.x + 1):
			var v:Vector2 = Vector2(c,r)
			if pieces.has(v):
				
				var p = pieces[v]
				
				if p == null:
					s += "."
				else:
					s += pieces[v].get_name().substr(0,1)
			else:
				s += "."
			s += " "
		#add a new line at the end of each row
		s += "\n"
	
	return s
	
###THE TRASH
#I hate my code but don't always want to throw it away
#BoardConverter has a lot  of that so it goes here :)

#run square to box and add mesh as a CSGMesh child of an input parent node
static func square_to_child(var parent:Node, 
	var square:Vector2=Vector2.ZERO, var material:Material = SpatialMaterial.new(), var name:String = ""):
	
	var m = square_to_box(parent, square)
	var csg = CSGMesh.new()
	csg.mesh = m
	csg.material = material
	if name.empty(): name = "Square " + String(parent.board.size)
	csg.name = name
	parent.add_child(csg)

	
	return csg

#WIP return a convex cube mesh bounding a square
static func square_to_box(var board:Node, var square:Vector2=Vector2.ZERO):
	
	var debug:Dictionary = {
		"initialization":0,
		"corners":0,
		"connections":0,
		"squishing":0,
		"construction":0
	}
	
	debug["initialization"] = OS.get_ticks_msec()
	
	#size and mesh of the board
	var size:Vector2 = board.size
	var mdt:MeshDataTool = board.mdt
	var graph:MeshGraph = board.graph
	#mesh duplicates of the board
	var dups:DuplicateMap = board.duplicates
	#bound and uv corners of the square
	var b:Bound = square_to_bound(size ,square)
	var c:PoolVector2Array = b.get_corners()
	
	#surface builder st and mesh m for st to push into when the box is finished being constructed
	var m:ArrayMesh = ArrayMesh.new()
	var st:SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#guess to help uv_to_mdata_graph start closer to its target
	var guess:int = 0

	debug["initialization"] = OS.get_ticks_msec() - debug["initialization"]
	debug["corners"] = OS.get_ticks_msec()

	#vertex arrays of each corner
	var coverts:Array = []
	#faces around each corner
	var cfaces:PoolIntArray = [-1, -1, -1, -1]
	coverts.resize(4)
	for i in range(0, 4):
		#get mdata of each corner
		coverts[i] = uv_to_mdata_graph(graph, dups, c[i], guess)
		guess = coverts[i][0]
		cfaces[i] = guess
		#convert coverts to vert arrays
		coverts[i] = DuplicateMap.mdata_to_array_static(coverts[i])
		
		#add verts into surface tool
		st.add_normal(dups.array_to_vert(coverts[i], 1))
		st.add_uv(dups.array_to_vert(coverts[i], 2))
		st.add_vertex(dups.array_to_vert(coverts[i], 0))
		
	debug["corners"] = OS.get_ticks_msec() - debug["corners"]
	debug["connections"] = OS.get_ticks_msec()
		
	#integer Dictionary of faces intersecting with b and their verts
	var faces:Dictionary = {}
	#PoolRealArray Dictionary of PoolVector2Array intersections, vertices with edges that they could move to
	var outer:Dictionary = {}
	#assign verts and faces to these sets
	get_connected_to_square(graph, dups, cfaces, b, faces, outer, board)
	
	
	debug["connections"] = OS.get_ticks_msec() - debug["connections"]
	debug["squishing"] = OS.get_ticks_msec()

	#PoolRealArray Dictionary of PoolRealArrays, verts with their target positions
	var verts:Dictionary = {}
	#find closest intersection to each outer point and key its new position with its old position in verts
	for i in outer:
		#distance of closest intersection and uv of outer
		var distance:float = INF
		var uv:Vector2 = dups.array_to_vert(i, 2)
		#array of intersections and index of closest intersection
		var inter:PoolVector2Array = outer[i]
		var close:int = -1
		#ensure intersections has contents by appending the corner uvs
		inter.append_array(c)
		#loop through inter, replace close with j when inter[j] is closer than distance to uv
		for j in inter.size():
			var d:float = uv.distance_to(inter[j])
			if j - inter.size() + 4 < 0: d /= 4.0
			if d < distance:
				distance = d
				close = j
				
		#create vert array for inter[close] to add as i's movement in verts
		if close > inter.size() - 4:
			verts[i] = coverts[close - inter.size() + 4]
			continue
		
		#generate a new position if the closest was not a corner
		var mdata = uv_to_mdata_graph(graph, dups, inter[close], guess)
		guess = mdata[0]
		verts[i] = DuplicateMap.mdata_to_array_static(mdata)
	
#	debug_positions(board, verts.keys(), 0.05, 0, Color.green)
#	debug_positions(board, verts.values(), 0.05, 1, Color.blue)
			
	debug["squishing"] = OS.get_ticks_msec() - debug["squishing"]
	debug["construction"] = OS.get_ticks_msec()
	
	#if square is flat, index faces into two triangles like so
	if faces.size() <= 1:
		st.add_index(2)
		st.add_index(1)
		st.add_index(0)
		st.add_index(3)
		st.add_index(2)
		st.add_index(0)
	else:
		var count:int = 4
		var not_found:Array = []
		for i in faces:
			for j in range(0, 3):
				var v:int = mdt.get_face_vertex(i, j)
				var a:PoolRealArray = dups.vert_to_array(v)
				#replace vert array with new data if it has been moved
				if verts.has(a): a = verts[a]
				else: not_found.append(a)
				
				st.add_normal(dups.array_to_vert(a, 1))
				st.add_uv(dups.array_to_vert(a, 2))
				st.add_vertex(dups.array_to_vert(a, 0))
				st.add_index(count)
				count += 1
	
	#commit st to m and return it
	st.commit(m)
	var md = MeshDataTool.new()
	md.create_from_surface(m, 0)
	
	debug["construction"] = OS.get_ticks_msec() - debug["construction"]
	
	print(debug)
	
	return m

#take in a MeshGraph and mdata for the corners of a square b,
#then write to faces Dictionary indices of faces connected to the square b 
#write vertex data of vertices on connected faces but not in b
static func get_connected_to_square(var graph:MeshGraph, var dups:DuplicateMap,
	var cfaces:PoolIntArray, var b:Bound, var faces:Dictionary, var outer:Dictionary,
#send in the board to debug off of if necessary
	var _board:Node) -> void:
	
	var mdt:MeshDataTool = graph.mdt
	
	#int PoolIntArray Dictionary of faces connected to b and their outer vertices
	var searched:Dictionary = {}
	
	#assign faces around the corners of the square using cfaces
	for i in range(0, 4):
		var f:int = cfaces[i]
		var v:PoolIntArray = [-1, -1, -1]
		
		#find verts on each that are outer vertices and assign verts to v, construct edges
		for j in range(0, 3):
			v[j] = mdt.get_face_vertex(f, j)
			mdt.get_vertex_uv(v[j])
		var inters:Array = [null, null, null]
		var out:PoolIntArray = is_face_touching_uv_b(mdt, v, b, inters)
		
		#if uv_to_mdata_graph approximated, corners can be disconnected
		#add them to outer with no intersections anyways, so they can get compressed into corners
		faces[f] = v
		if out == disconnected:
			searched[f] = [PoolIntArray([0, 1, 2]), 
				[PoolVector2Array(), PoolVector2Array(), PoolVector2Array()]]
		else: searched[f] = [out, inters]
	
	#a queue of faces to search for connectivity
	var queue:PoolIntArray = []
	#fill queue with faces connected to the corner faces
	for f in faces:
		for i in graph.ftf[f]:
			if !searched.has(i): queue.append(i)
	
	#pop through queue until it is empty
	#if the current face is connected to b, add its neighbors to queue and its intersections to outer
	while !queue.empty():
		var i:int = queue.size() - 1
		var f:int = queue[i]
		queue.remove(i)
		
		#check if current face is connected to b, collecting its outer verts and intersections along the way
		var v:PoolIntArray = [-1, -1, -1]
		for j in range(0, 3):
			v[j] = mdt.get_face_vertex(f, j)
		var inters:Array = [null, null, null]
		var out:PoolIntArray = is_face_touching_uv_b(mdt, v, b, inters)
		searched[f] = [out, inters]

		#if the face is not connected, do not continue to add its data to faces and outer,
		#and do not queue is neighbors
		if out == disconnected: continue
		faces[f] = v
		#update_outer(outer, mdt, f, out, inters)
		for j in graph.ftf[f]:
			if !searched.has(j): queue.append(j)
	
	#use searched Dictionary to link intersections with vertex arrays in outer
	for i in searched:
		var pair:Array = searched[i]
		var out:PoolIntArray = pair[0]
		var inters:Array = pair[1]
		
		if out == disconnected: continue
		
		#assign intersections to outer
		for j in out.size():
			var o:int = out[j]
			var v:int = faces[i][o]
			
			var a:PoolRealArray = dups.vert_to_array(v)
			var c:PoolVector2Array = inters[o]
			if outer.has(a): outer[a].append_array(c)
			else: outer[a] = c

#constant for is_face_touching_uv_b to use instead of null or false
const disconnected:PoolIntArray = PoolIntArray([-1])

#check if a face in the input mdt is touching a Bound in uv space
#returns a PoolIntArray of outer vertices if the face is touching
#return disconnected if not
#fill and input intersections array, 
#WARNING: intersections array will only store edge sets if an inner vertex is found 
static func is_face_touching_uv_b(var mdt:MeshDataTool, var v:PoolIntArray,
	var b:Bound, var intersections:Array = []) -> PoolIntArray:
	
	#Array of outer vertices to return if face is touching
	var out:PoolIntArray = []
	
	var touching:bool = false
	
	#find if any vertices of face are inside b, construct out
	for i in range(0, 3):
		var uv:Vector2 = mdt.get_vertex_uv(v[i])
		if b.is_surrounding(uv): touching = true
		else: out.append(i)
	
	#if the face has outer vertices, look for intersections
	if out.empty() && touching: return out
	var inters:Array = [null, null, null]
	for i in range(0, 3):
		var uv0:Vector2 = mdt.get_vertex_uv(v[i])
		var uv1:Vector2 = mdt.get_vertex_uv(v[(i + 1) % 3])
		var e:PoolVector2Array = [uv0, uv1]
		
		inters[i] = b.edge_set_intersection(e)
		if !inters[i].empty(): touching = true
	#send edge intersections to intersection array such that inter[i] has two sets of intersections for its adjacent edges
	for i in range(0, 3):
		#intersections from i to i + 1
		intersections[i] = inters[i]
		#intersections from i - 1 to i
		intersections[i].append_array(inters[(i - 1) % 3])
	
	if touching: return out
	return disconnected
	
#get all verts and faces connected to an index in mdt
#return [0] is vert dictionary, return [1] is face dicitonary
static func vert_to_triangle_fan(var dups:DuplicateMap, var i:int = 0, 
	var verts:Dictionary = {}, var faces:Dictionary = {}, var edges:bool = false):
	
	var mdt:MeshDataTool = dups.mdt
	
	#get connected faces
	var fs:Array
	if edges:
		fs = mdt.get_edge_faces(i)
	else:
		fs = mdt.get_vertex_faces(i)
	
	#loop through faces and add their verts
	for f in fs:
		#add face to faces dict so calling function can see the faces being searched
		faces[f] = get_face_vertices(dups, f)[0]
		for j in range(0, 3):
			var v = mdt.get_face_vertex(f, j)
			#same deal as faces
			verts[v] = [f, mdt.get_vertex(v), mdt.get_vertex_normal(v)]
	
	#in case vert_to_triangle_fan doesnt have dictionary args, return them back out
	return [verts, faces]

#convert mouse position in pixels from the top left to uv from the bottom left
static func mpos_to_screenuv(var pos:Vector2):
	#find size of screen at the time to normalize pos, then invert pos.y
	pos /= OS.window_size
	pos.y = 1 - pos.y
	return pos

#use board and player nodes to convert screen position to a uv position on the board
static func mpos_to_uv(var board:Node, var transform:Transform, 
	var pos:Vector3 = Vector3.ZERO) -> Vector2:
	
	var mdt:MeshDataTool = board.mdt
	
	#transforms to flatten triangles to the screen
	var flat:Transform = Transform(Vector3.RIGHT,Vector3.UP, 
							Vector3.ZERO,Vector3.ZERO)
							
	var bt:Transform = board.transform
	
	#array of triangles surrounding pos
	var surrounding:Array = []
	var surr_flat:Array = []
	var positions:PoolVector3Array = []
	var debug:Array = []
	
	#fill the array of triangles surrounding the input position
	for i in mdt.get_face_count():
		#skip faces facing the wrong direction
		if mdt.get_face_normal(i).dot(transform.basis.z) <= 0: continue
		
		var verts:Array = [null, null, null]
		for j in range(0, 3):
			var v:int = mdt.get_face_vertex(i, j)
			verts[j] = DuplicateMap.mdt_to_array(mdt, v)
		
		#save untransformed version of triangle
		var t:Triangle = Triangle.new(verts)
		
		var tface:Triangle = Triangle.new(verts)
		tface.xform_with(bt, true)
		var face:Transform = face_to_transform(mdt, i, Vector3.ONE * i)
		tface.xform_with(face)
		tface.xform_with(flat)
		
		var pface:Vector3 = flat.xform(face.xform(pos))
		
		if tface.is_surrounding(pface):
			surrounding.append(t)
			surr_flat.append(tface)
			positions.append(pface)
			debug.append_array(t.verts)
			
	if surrounding.empty(): return Vector2.ZERO
	
	#find the flattened surrounding triangle with the least barycentric magnitude for the input position
	var mag:float = INF
	var baryf:Vector3
	var tri:Triangle
	for i in surrounding.size():
		var m:float = surrounding[i].center().distance_to(pos)
		if m < mag:
			mag = m
			baryf = surr_flat[i].barycentric_of(positions[i])
			tri = surr_flat[i]
	
	return tri.pos_from_barycentric(baryf, 2)
	
static func face_to_transform(var mdt:MeshDataTool, var i:int,
	var o:Vector3 = Vector3.ZERO) -> Transform:
	
	var x:Vector3 = Vector3.RIGHT
	var z:Vector3 = mdt.get_face_normal(i)
	var y:Vector3 = z.cross(x)
	x = z.cross(y)
	
	return Transform(x, y, z, -o)
