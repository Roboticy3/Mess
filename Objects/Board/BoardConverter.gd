class_name BoardConverter

#BoardConverter Class made by Pablo Ibarz
#created in December 2021

#BoardConverter started as a converter for things related to well, the board
#but now its a more general use collection of static functions because I'm too lazy to learn how to use a singleton

#return the face index, position in space and normal of mesh from a uv coordinate pos
static func uv_to_mdata(var graph:MeshGraph, var pos:Vector2 = Vector2.ZERO,
	var guess:int = 0, var mask:PoolIntArray = []):
	
	#the position being searched as a vertex array
	var vert:PoolRealArray = DuplicateMap.format_vector(pos, 2)
	
	#search graph with Breadth-first-search starting from face guess
	
	#queue of faces to be iterated through
	var queue:PoolIntArray = [guess]
	#triangle to set faces to, default to face guess
	var t:Triangle = Triangle.new(graph.mdt, guess)
	#Dictionary of searched faces with their result for being contained in t
	var searched:Dictionary = {guess:t.is_surrounding(vert, 2)}
	var size:int = graph.mdt.get_face_count()
	
	#result to return
	var result:Array = [guess, Vector3.ZERO, Vector3.UP, pos]
	
	#remove faces from queue until it is empty,
	#adding faces that have not been searched each iteration
	while !queue.empty():
		var n:int = queue.size() - 1
		var i:int = queue[n]
		queue.remove(n)
		
		for f in graph.ftf[i]:
			if !searched.has(f):
				#update triangle and search it
				t.from_mdt(graph.mdt, f)
				#if the correct triangle has been found, break the loop
				searched[f] = t.is_surrounding(vert, 2)
				if searched[f]: 
					result[0] = f
					break
				queue.append(f)
		
		#if all the connected faces have been searched, 
		#but the iteration count is less than the face count,
		#jump to the next unsearched face
		if queue.empty() && searched.size() < size:
			while searched.has(i):
				i += 1

			t.from_mdt(graph.mdt, i)
			searched[i] = t.is_surrounding(vert, 2)
			if searched[i]:
				result[0] = i
				break
			queue.append(i)

	var bary:Vector3 = t.barycentric_of(vert, 2)
	result[1] = t.pos_from_barycentric(bary)
	result[2] = graph.mdt.get_face_normal(result[0])
	return result

#retrieve an Arrays object from a face index of a MeshDataTool
static func get_face_vertices(var mdt:MeshDataTool, var i:int):
	return [DuplicateMap.vert_to_array(mdt, mdt.get_face_vertex(i, 0)),
			DuplicateMap.vert_to_array(mdt, mdt.get_face_vertex(i, 1)),
			DuplicateMap.vert_to_array(mdt, mdt.get_face_vertex(i, 2))]

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
static func square_to_mdata(var graph:MeshGraph, var size:Vector2 = Vector2.ONE, var pos:Vector2 = Vector2.ZERO):
	var uv = square_to_uv(size, pos)
	return uv_to_mdata(graph, uv)

#take an input board mdt, board, and piece to return a Transform for the associated PieceMesh accosiated with piece on the mdt constructed from a BoardMesh
static func square_to_transform(var graph:MeshGraph, 
	var board:Board, var piece:Piece):
	
	
	#reference useful piece properties in other variables
	var pos:Vector2 = piece.get_pos()
	var table:Dictionary = piece.table
	
	#create a new transform to modify
	var transform:Transform = Transform()
	
	#get mesh data on square center for position and normal of the piece
	#if the piece is not centered on its origin, offsets can be created
	var mdata = square_to_mdata(graph, board.size, pos)
	#skip function if mdata returns null
	if mdata == null:
		return transform
	
	#ROTATION
	#go through each of the transformation steps
	#check piece's settings on each before running each function
	if table["rotate_mode"] != 2:
		transform.basis = square_to_basis(graph, board, piece, mdata)
		
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
static func square_to_basis(var graph:MeshGraph, var board:Board, 
	var piece:Piece, var mdata:Array):
	
	var mdt:MeshDataTool = graph.mdt
	if mdata == null: return Basis()
	
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
		mf = square_to_mdata(graph, board.size, piece.get_pos() + v)
	
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
	
	#mdata of each uv corner
	var coverts:Array = []
	coverts.resize(4)
	for i in range(0, 4):
		#get mdata of each corner
		coverts[i] = uv_to_mdata(graph, c[i])
		#convert coverts to vert arrays
		coverts[i] = dups.mdata_to_array(coverts[i])
		
		#add verts into surface tool
		st.add_normal(DuplicateMap.array_to_vert(coverts[i], 1))
		st.add_uv(DuplicateMap.array_to_vert(coverts[i], 2))
		st.add_vertex(DuplicateMap.array_to_vert(coverts[i], 0))
		
	#integer Dictionary of faces intersecting with b and their verts
	var faces:Dictionary = {}
	#PoolRealArray Dictionary of PoolVector2Array intersections, vertices with edges that they could move to
	var outer:Dictionary = {}
	#assign verts and faces to these sets
	get_connected_to_square(mdt, dups, b, faces, outer)
	
	#PoolRealArray Dictionary of PoolRealArrays, verts with their target positions
	var verts:Dictionary = {}
	#bool Array of whether each corner has been filled
	#find closest intersection to each outer point
	for i in outer:
		#distance of closest intersection and uv of outer
		var distance:float = INF
		var uv:Vector2 = DuplicateMap.array_to_vert(i, 2)
		#array of intersections and index of closest intersection
		var inter:PoolVector2Array = outer[i]
		var close:int = -1
		#ensure intersections has contents by appending the corner uvs
		inter.append_array(c)
		#loop through inter, replace close with j when inter[j] is closer than distance to uv
		for j in inter.size():
			var d:float = uv.distance_to(inter[j])
			if d < distance:
				distance = d
				close = j
		#create vert array for inter[close] to add as i's movement in verts
		if close > inter.size() - 4:
			verts[i] = coverts[close - inter.size() + 4]
		else:
			var mdata = uv_to_mdata(graph, inter[close])
			verts[i] = DuplicateMap.mdata_to_array(mdata)
				
	#if square is flat, index faces into two triangles like so
	if faces.empty():
		st.add_index(2)
		st.add_index(1)
		st.add_index(0)
		st.add_index(3)
		st.add_index(2)
		st.add_index(0)
	else:
		var count:int = 4
		for i in faces:
			for j in range(0, 3):
				var v:int = mdt.get_face_vertex(i, j)
				var a:PoolRealArray = DuplicateMap.vert_to_array(mdt, v)
				#replace vert array with new data if it has been moved
				if verts.has(a): a = verts[a]
				
				st.add_normal(DuplicateMap.array_to_vert(a, 1))
				st.add_uv(DuplicateMap.array_to_vert(a, 2))
				st.add_vertex(DuplicateMap.array_to_vert(a, 0))
				st.add_index(count)
				count += 1
	
		
	#commit st to m and return it
	st.commit(m)
	var md = MeshDataTool.new()
	md.create_from_surface(m, 0)
	return m

#isolate sets of vertices and faces in a mesh represented by a MeshDataTool and a duplicates Dictionary
#these sets are faces intersecting Bound b and vertices outside, but connected to those faces
#faces are represented as int indices of mdt and verts as PoolRealArray vertex arrays
static func get_connected_to_square(var mdt:MeshDataTool, var dups:DuplicateMap, var b:Bound,
	var faces:Dictionary = {}, var outer:Dictionary = {}):

	var duplicates:Dictionary = dups.duplicates

	#for each vertex in the dupmap, check if it is inside b or has edges intersecting b
	#store any connected faces to duplicates of "a" that fill these conditions
	for a in duplicates:
		#if uv of a is inside b, add all connected triangles
		var uv:Vector2 = DuplicateMap.array_to_vert(a, 2)
		
		#flags for whether a is inside b, and whether its connected to a face intersecting b
		var inside:bool = b.is_surrounding(uv)
		var connected:bool = inside
		
		#store uv intersections of edges from a with b
		var intersections:PoolVector2Array = []
			
		#loop through duplicates of a to find intersections and connections to b
		for i in duplicates[a]:
			#get the faces of each duplicate
			var fs:PoolIntArray = mdt.get_vertex_faces(i)
			#check each connected face
			for f in fs:
				#construct and array of vertices from the face verts
				var v:PoolIntArray = [-1, -1, -1]
				for j in range(0, 3):
					v[j] = mdt.get_face_vertex(f, j)
				
				#if uv is inside b, add faces connected to a to faces
				if inside: 
					faces[f] = v
				#otherwise, check for edge intersecitons with b
				else: 
					for j in range(0, 3):
						var uv1:Vector2 = mdt.get_vertex_uv(v[j])
						var uv2:Vector2 = mdt.get_vertex_uv(v[(j + 1) % 3])
						#if there are intersections, add face and flag connected
						var inter:PoolVector2Array = b.edge_set_intersection([uv1, uv2])
						if inter.empty(): continue
						#add intersections not already found
						for k in inter.size():
							var added:bool = false
							for l in intersections.size():
								if intersections[l] == inter[k]: 
									added = true
									break
							if !added: intersections.append(inter[k])
						faces[f] = v
					
				#if this face connected to a has an intersection, flag connected
				if faces.has(f):
					connected = true
		
		#final check to update connected if there are intersections
		if !intersections.empty(): connected = true
		
		#add a to the appropriate set depending on inside and connected
		if !inside && connected: outer[a] = intersections
	return [faces, outer]

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

#use board and player nodes to convert screen position to a uv position on the board
static func mpos_to_uv(var board:Node, var player:Node, var pos:Vector2 = Vector2.ZERO):
	
	#https://stackoverflow.com/questions/72206128/when-raycasting-forms-multiple-intersections-which-point-does-it-return-can-wh/72208596#72208596
	#get Viewport/Camera stack and player Camera from player Node
	var maincam:Camera
	var viewport:Viewport
	var camera:Camera
	var minstance:MeshInstance
	for i in player.get_children():
		if i is Viewport:
			viewport = i
			for j in viewport.get_children():
				if j is Camera:
					camera = j
				elif j is MeshInstance:
					minstance = j
		elif i is Camera:
			maincam = i
	
	#update viewport's size and camera's properties into the correct positions
	viewport.size = viewport.get_viewport().size
	copy_camera_properties_from(maincam, camera)

	#copy board's ArrayMesh mesh to minstance
	minstance.mesh = board.mesh
	#grab the texture from the viewport and convert it to an image
	var tex:Texture = viewport.get_texture()
	var image:Image = tex.get_data()
	#locking the image allows for BoardConverter to read it
	image.lock()
	
	
	#get the color of the uv material at the point where the player clicked, getting the uv coord in return
	var color:Color = image.get_pixelv(pos)
	if color.a != 0: return Vector2(color.r, color.g)
	
	image.unlock()
	

#non-destructively copy camera properties from one camera to another
static func copy_camera_properties_from(var from:Camera, var to:Camera) -> void:
	to.global_transform = from.global_transform
	to.fov = from.fov
	to.keep_aspect = from.keep_aspect
	to.cull_mask = from.cull_mask
	to.h_offset = from.h_offset
	to.environment = from.environment
	to.v_offset = from.v_offset
	to.doppler_tracking = from.doppler_tracking
	to.projection = from.projection
	to.size = from.size
	to.frustum_offset = from.frustum_offset
	to.near = from.near
	to.far = from.far

#import mesh from .obj path
static func path_to_mesh(var path:String = "", var debug:bool = false):
	#parse board using parser script into loadable mesh
	var m = ObjParse.parse_obj(path, path.substr(0, path.length() - 3) + "mtl", debug)
	
	#create mdt to read mesh
	var mdt:MeshDataTool = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	#if mesh was not created correctly, read from default mesh path
	if mdt.get_vertex_count() == 0:
		path = "Instructions/default/meshes/default.obj"
		m = ObjParse.parse_obj(path, path.substr(0, path.length() - 3) + "mtl", debug)
	
	return m

#create a convex or concave shape from a mesh dependant on whether or not the mesh is flat
static func mesh_to_shape(var m:Mesh):
	return m.create_trimesh_shape()

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
			verts[v] = [f, mdt.get_vertex(v), mdt.get_vertex_normal(v)]
	
	#in case vert_to_triangle_fan doesnt have dictionary args, return them back out
	return [verts, faces]

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
	var r = s.intersect_ray(o, n * v, [], mask)
	#if the intersection lands, return r
	if !r.empty():
		return r
	return null

#add CSGsphere children to node at relative positions
#setting mode to 1 will stop the method from deleting old csgballs
static func debug_positions(var node:Node = null, var positions:Array = [], 
	var radius:float = 0.1, var mode:int = 0):
	
	#remove old debug objects
	if mode != 1:
		for c in node.get_children():
			if c.name.find("debug") != -1:
				node.remove_child(c)
				
	#if position map is empty, exit function
	if positions.empty(): return
	
	#material to apply to the CSGBalls
	var material:Material = SpatialMaterial.new()
	
	#checks if positions is an Array of PoolRealArray, assumes all elements are of same type
	var t:bool = positions[0] is PoolRealArray
	
	#add new ones
	for p in positions: 
		if t:
			p = DuplicateMap.array_to_vert(p)
		
		var csg = CSGSphere.new()
		csg.radius = radius
		csg.material = material
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
