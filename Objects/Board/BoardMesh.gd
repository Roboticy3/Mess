#a BoardMesh is set up after its Board, and handles how pieces will display on a mesh in-game
class_name BoardMesh
extends Node

#reference to a Board
var board = null

export (String) var path:String = "Instructions/b_cube.txt"
export (Resource) var mesh = null
var mdt:MeshDataTool = null
export (Resource) var default = null

#store the size of the board in squares
export (Vector2) var size:Vector2 = Vector2.ONE

export (Resource) var shader = null

#dictionary of a mesh and collision shape of a certain piece, keyed by its name
#this collection stops each individual piece from having to load its mesh and collision individually
var piece_types:Dictionary = {}
#this collection prevents BoardConverter from having to run square_to_box on the same square multiple times
var square_meshes:Dictionary = {}

#debug mesh to test stuff on
var debug = null

# Called when the node enters the scene tree for the first time.
func _ready():
	#retrieve board reference from spatial parent if possible
	board = Board.new(path)
	
	#the size is the maximum corner of the board minus the minimum
	#"1" is added because the uv map considers 0, 0 as the bottom left corner and not the bottom left square
	size = board.maximum-board.minimum + Vector2.ONE
	
	#set mesh from obj path and copy into shorthand m
	mesh = BoardConverter.path_to_mesh(board.mesh)
	var m = mesh
	mdt = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	
	#create the board's collision shape
	var shape = BoardConverter.mesh_to_shape(m)
	
	#send collision shape and mesh to children
	var children = get_children()
	for c in children:
		
		if c is CSGMesh:
			#set mesh to parent object
			c.set("mesh", mesh)
			#run uv_from_board after setting the shader so the shader can be sent uv data
			shader = c.get("material")
			uv_from_board(c)
			
		#find child that is a collision shape to set the shape to
		if c is CollisionShape:
			c.set("shape", shape)
			
	
	#send self's data to player objects
	var siblings = get_parent().get_children()
	for s in siblings:
		if s is KinematicBody && "board_mesh" in s:
			s.set("board_mesh", self)
			s.set("board", board)
			
	print(board)
	
	#generate team objects
	var ps = board.pieces
	for v in ps.keys():
		create_piece(ps[v], v)
	
	print(board.table)

#remap uv settings from board shape
func uv_from_board(var object:Node):
	
	#offset uvs by the minimum corner of the board
	var offset = Vector3()
	offset.x = board.minimum.x
	offset.y = board.minimum.y

	#scale is divided by two because the checkerboard texture is 2x2
	var scale = Vector3()
	scale.x = size.x
	scale.y = size.y
	scale /= 2
	
	#get reference to the material, then use setter functions to access it
	var material = object.get("material")
	#only offset uvs if shader is the right type
	if material is SpatialMaterial:
		material.set_uv1_offset(offset)
		material.set_uv1_scale(scale)
	else:
		shader.set_shader_param("size", board.maximum - board.minimum)
		pass

#initialize a PieceMesh p at a position v on the board
func create_piece(var p:Piece, var v:Vector2):
	#if the piece is not recorded in the piece_types dict, add its data
	var pdata = {}
	if !([p._to_string()] in piece_types):
		pdata["mat"] = PieceMesh.pmat(p, board)
		pdata["mesh"] = BoardConverter.path_to_mesh(p.mesh)
		pdata["shape"] = BoardConverter.mesh_to_shape(pdata["mesh"])
		pdata["transform"] = BoardConverter.square_to_transform(mdt, board, p)
		piece_types[p._to_string()] = pdata
	#otherwise, copy piece data out
	else:
		pdata = piece_types[p.name]
	#create the piece mesh with all the right references
	var pm = PieceMesh.new(p, board 
			,pdata["shape"], pdata["mesh"], pdata["mat"]
			)
	add_child(pm)
	
	pm.transform = pdata["transform"]

#highlight a square on the board by running square_to_child and adding the child's index to the square_mesh cache
#if mode is set to 1, hide all squares outside of the array
#if mode is set to 2, hide all squares in the array
func highlight_square(var vs:PoolVector2Array, var mode:int = 0):
	if mode == 1:
		for c in get_children():
			if c.name.find("Square") != -1:
				c.visible = false
	
	for v in vs:
		if true:
			var csg = BoardConverter.square_to_child(self, mdt, board.size, v)
			#square_meshes[v] = csg
			if mode == 2: csg.visible = false
		else:
			var csg = square_meshes[v]
			csg.visible = true
			if mode == 2: csg.visible = false
		
	

