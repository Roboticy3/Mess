class_name BoardMesh
extends Node

#BoardMesh class by Pablo Ibarz
#created in January 2022 

#a BoardMesh is set up after its Board, and handles how pieces will display on a mesh in-game

#reference to a Board
var board:Board

#board instruction path, mesh object, mdt object (for BoardConverter), and default mesh path meant to be set in the editor
export (String) var path:String = "Instructions/cube"
export (Resource) var mesh = null
var mdt:MeshDataTool = null
export (Resource) var default = null

#store the size of the board in squares
export (Vector2) var size:Vector2 = Vector2.ONE

#material of the board
export (Resource) var mat_board = null
#material of the square highlight
export (Resource) var mat_highlight = null

#dictionary of a mesh and collision shape of a certain piece, keyed by its name
#this collection stops each individual piece from having to load its mesh and collision individually
var piece_types:Dictionary = {}
#this collection prevents BoardConverter from having to run square_to_box on the same square multiple times
var square_meshes:Dictionary = {}

#Vector2 Dictionary of PieceMeshes, keeps track of piece models
var pieces:Dictionary = {}

#a margin from the edges of (0, 0) and (1, 1) in uv space that uv values will be clamped to
var uv_margin:float = 0.0001
#store duplicate vertices for more efficient mesh searching
var duplicates:Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	#copy path to a usable board path
	var _path:String = "" + path
	#if path ends in "/", copy folder name and remove end
	var i:int = _path.find_last("/")
	var p:String = _path.substr(i)
	if i + 1 == _path.length():
		_path = _path.substr(0, _path.length() - 1)
		i = _path.find_last("/")
		p = _path.substr(i)
	#if path does not prefix with _b, assume it is a folder and add b_folder_name.txt onto the end
	if _path.find("b_") != 0:
		p = p.substr(1)
		path = _path + "/b_" + p + ".txt"
	#otherwise, take path as-is (no operation)
	print(path)
	
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
	duplicates = BoardConverter.find_duplicates(mdt)

	#create the board's collision shape
	var shape = BoardConverter.mesh_to_shape(m)
	
	#send collision shape and mesh to children
	var children = get_children()
	for c in children:
		
		if c is CSGMesh:
			#set mesh to parent object
			c.set("mesh", mesh)
			#run uv_from_board after setting the shader so the shader can be sent uv data
			mat_board = c.get("material")
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
	
	#generate piece objects
	var ps = board.pieces
	for v in ps:
		pieces[v] = create_piece(ps[v], v)

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
	#otherwise, hope ShaderMaterial has "size" parameter
	elif material is ShaderMaterial:
		mat_board.set_shader_param("size", board.maximum - board.minimum)
		pass

#initialize a PieceMesh p at a position v on the board
func create_piece(var p:Piece, var v:Vector2):
	#if the piece is not recorded in the piece_types dict, update dict with its data
	var pdata = {}
	if !([p._to_string()] in piece_types):
		pdata["mat"] = PieceMesh.pmat(p, board)
		pdata["mesh"] = BoardConverter.path_to_mesh(p.mesh)
		pdata["shape"] = BoardConverter.mesh_to_shape(pdata["mesh"])
		pdata["transform"] = BoardConverter.square_to_transform(mdt, board, p)
		piece_types[p._to_string()] = pdata
	#otherwise, copy piece data out of current dict
	else:
		pdata = piece_types[p.name]
	
	#create the piece mesh with all the right references, then add the PieceMesh object to self's tree
	var pm = PieceMesh.new(p, board 
			,pdata["shape"], pdata["mesh"], pdata["mat"]
			)
	add_child(pm)
	
	#set pm's reference to its piece and transforms and return pm to be added to table
	pm.piece = p
	pm.transform = pdata["transform"]
	return pm

#transform the piece in from to to, change location, rotation, and scale accordingly
func move_piece(var from:Vector2, var to:Vector2):
	
	#if to contains a PieceMesh, remove that object before continuing
	if pieces.has(to):
		remove_child(pieces[to])
		pieces.erase(to)
	
	#update the dictionary
	pieces[to] = pieces[from]
	pieces.erase(from)
	
	#move the PieceMesh object into the right spot
	var p:PieceMesh = pieces[to]
	p.transform = BoardConverter.square_to_transform(mdt, board, p.piece)

#highlight a square on the board by running square_to_child and adding the child's index to the square_mesh cache
#if mode is set to 1, hide all squares outside of the array
#if mode is set to 2, hide all squares in the array
func highlight_square(var vs:PoolVector2Array = [], var mode:int = 1):
	
	#hide everything to start if mode is 1
	if mode == 1:
		for c in get_children():
			if c.name.find("Square") != -1:
				c.visible = false

	for v in vs:
		#if a square mesh for this square has already been created, just unhide it
		if square_meshes.has(v):
			var csg = square_meshes[v]
			if mode == 2: csg.visible = false
			#mode 2 hides selection
			else: csg.visible = true
		else:
			var csg = BoardConverter.square_to_child(self, v, mat_highlight)
			square_meshes[v] = csg
			if mode == 2: csg.visible = false

#use board.mark to highlight a set of square meshes
func mark_from(var v:Vector2):
	var pos = board.mark(v).keys()
	highlight_square(pos)
	
#run this method whenever a player clicks on a square
#generally handles all interactions a Player object could have with the main Board object
func handle(var v:Vector2, var team:int = 0):
	
	var p:Dictionary = board.pieces
	
	#check if square is a selectable piece
	if v in p && team == p[v].team:
		#mark from selectable piece
		mark_from(v)
	#check if square is a square that can be moved to
	if v in board.marks:
		#get updates to the board to apply to BoardMesh while updating the Board's data as well
		var moves:Array = board.execute_turn(v)
		#move mesh of piece into correct place
		for i in moves[0]:
			move_piece(i, moves[0][i])
		#clear board marks
		highlight_square()
		
	return board.get_team() #get team from board in case there is one player which has to switch
