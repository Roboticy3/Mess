class_name BoardMesh
extends Node

#BoardMesh class by Pablo Ibarz
#created in January 2022 

#a BoardMesh is set up after its Board, and handles how pieces will display on a mesh in-game

#reference to a Board
var board:Board

#board instruction path, mesh object, mdt object (for BoardConverter), and default mesh path meant to be set in the editor
export (String) var path:String
export (Resource) var mesh = null
var mdt:MeshDataTool = null
export (Resource) var default = null

#store the size of the board in squares
export (Vector2) var size:Vector2 = Vector2.ONE

#material of the board
export (Material) var mat_board = ResourceLoader.load("res://Materials/DwithHighlights.tres")
#material of the square highlight
export (Material) var mat_highlight = ResourceLoader.load("res://Materials/highlight1.tres")

#paths to this BoardMesh's rendering and collision children, must be filled for either to work
export (NodePath) var board_shape_path:NodePath
export (NodePath) var board_collider_path:NodePath

#dictionary of a mesh and collision shape of a certain piece, keyed by its name
#this collection stops each individual piece from having to load its mesh and collision individually
var piece_types:Dictionary = {}

#Vector2 Dictionary of PieceMeshes, keeps track of piece models
var pieces:Dictionary = {}

#a margin from the edges of (0, 0) and (1, 1) in uv space that uv values will be clamped to
var uv_margin:float = 0.0001
#store duplicate vertices and graph of mdt for more efficient mesh searching
var duplicates:DuplicateMap
#store duplicates only by position, not considering uvs and normals, to avoid MeshGraph building large amounts of islands
var dups_pos_only:DuplicateMap
var graph:MeshGraph

var players := Array()

#set to true at the end of the begin() method, signifies that this BoardMesh and its Board are finished loading
var awake := false

#signal to emit when the board emits its win signal
signal end
	
#construct the Board and the BoardMesh
#distinguish from _ready() to better control the initialization of the board
func begin(var _path:String = ""):
	path = _path
	print(path)
	
	#retrieve board reference from spatial parent if possible
	board = Board.new(path)
	
	#link the board's end signal to this BoardMesh end signal
	board.connect("end", self, "end")
	
	#the size is the maximum corner of the board minus the minimum
	#"1" is added because the uv map considers 0, 0 as the bottom left corner and not the bottom left square
	size = board.maximum-board.minimum + Vector2.ONE
	
	#send mesh to visual objects
	var m:Mesh = init_mesh()
	#send board to player objects
	send_board()
			
	print(board)
	
	#generate piece objects
	var ps = board.pieces
	for v in ps:
		create_piece(ps[v], v)
	
	#send mesh and collision shape to physics objects
	send_shape(m)
	
	awake = true

#create a mesh and send it out to the Board Shape Node in BoardMesh's tree
func init_mesh():
	
	#set mesh from obj path and copy into shorthand m
	mesh = BoardConverter.path_to_mesh(board.get_mesh())
	var m = mesh
	mdt = MeshDataTool.new()
	mdt.create_from_surface(m, 0)
	#map duplicate vertices and create graph of mesh for easier manipulation of the mesh
	duplicates = DuplicateMap.new(mdt, true, false, true)
	#create a duplicate map that only considers positions to send into a MeshGraph
	dups_pos_only = DuplicateMap.new(mdt, true, false, false)
	graph = MeshGraph.new(mdt, dups_pos_only)
	
	#set opacity of material based on board property
	var a:float = board.table["opacity"]
	if mat_board is SpatialMaterial: mat_board.albedo_color.a = a
	elif mat_board is ShaderMaterial: mat_board.set_shader_param("alpha", a)
	if a == 1:
		mat_board.flags_transparent = false
	
	#set board size based on board property
	var s:Vector3 = get("scale")
	s *= board.table["scale"]
	set("scale", s)

	return m

#find the players in the scene and give them the information they need about the board
func send_board():
	#send self's data to player objects
	var siblings = get_parent().get_children()
	for s in siblings:
		if s is KinematicBody:
			players.append(s)
			s.set("board_mesh", self)
			s.set("material", mat_board)
			s.set("board", board)
			s.set_mesh(mesh)
	
#resolve the collisions of the board
func send_shape(var m:Mesh):
	
	#flag board's collision boolean
	var noclip:bool = false
	if board.table["collision"] != 1: noclip = true
	
	#create the board's collision shape
	var shape = BoardConverter.mesh_to_shape(m)
	
	#send collision shape and mesh to children
	var c:Node = get_node(board_shape_path)
	#set mesh to parent object
	c.set("mesh", mesh)
	#run uv_from_board after setting the shader so the shader can be sent uv data
	mat_board = c.get("material")
	uv_from_board(c)
	
	c = get_node(board_collider_path)
	c.set("shape", shape)
	#if there is no collision, change to collision layer so that players can pass through but rays can still hit
	if noclip: set("collision_layer", 2)

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
	#otherwise, assume the ShaderMaterial is handling highlighting and set its properties accordingly
	elif material is ShaderMaterial:
		mat_board.set_shader_param("uv1_scale", scale)
		mat_board.set_shader_param("uv1_offset", offset)
		mat_highlight = mat_board.get_next_pass()
		mat_highlight.set_shader_param("uv1_scale", scale)
		mat_highlight.set_shader_param("uv1_offset", offset)

#initialize a PieceMesh p at a position v on the board
func create_piece(var p:Piece, var v:Vector2):
	#destroy any piece currently occupying the square
	if pieces.has(v): destroy_piece(v)
	
	var can_collide:bool = false
	
	#if the piece is not recorded in the piece_types dict, update dict with its data
	var pdata = {}
	if !([p.get_name()] in piece_types):
		pdata["mat"] = PieceMesh.pmat(p, board)
		pdata["mesh"] = BoardConverter.path_to_mesh(p.get_mesh())
		
		#flag collision to be added if the piece and board collision modes align correctly
		var bpcoll:bool = board.table["piece_collision"] == 1
		var pcoll:int = board.table["collision"]
		if bpcoll || pcoll == 2 && pcoll != 1:
			can_collide = true
		
		pdata["shape"] = BoardConverter.mesh_to_shape(pdata["mesh"])
		pdata["transform"] = BoardConverter.square_to_transform(graph, duplicates, board, p)
		piece_types[p._to_string()] = pdata
	#otherwise, copy piece data out of current dict
	else:
		pdata = piece_types[p.get_name()]
	
	var coll = pdata["shape"]
	if !can_collide: coll = CollisionShape.new()
	
	#create the piece mesh with all the right references, then add the PieceMesh object to self's tree
	var pm := PieceMesh.new(p, board 
			,coll, pdata["mesh"], pdata["mat"]
			)
	add_child(pm)
	
	#set pm's reference to its piece and transforms and return pm to be added to table
	pm.piece = p
	pm.transform = pdata["transform"]
	pieces[v] = pm

#transform the piece in from to to, change location, rotation, and scale accordingly
func move_piece(var from:Vector2, var to:Vector2):
	
	#if to contains a PieceMesh, remove that object before continuing
	if pieces.has(to): destroy_piece(to)
	
	#update the dictionary
	pieces[to] = pieces[from]
	pieces.erase(from)
	
	#move the PieceMesh object into the right spot
	var p:PieceMesh = pieces[to]
	p.transform = BoardConverter.square_to_transform(graph, duplicates, board, p.piece)

#destroy the PieceMesh at the input Vector2 square
#do not attempt to destroy at an empty square
func destroy_piece(var at:Vector2):
	if !pieces.has(at): return
	remove_child(pieces[at])
	#free the piece to avoid a memory leak
	pieces[at].free()
	pieces.erase(at)

#highlight squares on the board by sending their positions to a texture which is rendered by mat_board
#only works if mat_board is a ShaderMaterial
#if mode is set to 1, hide all squares outside of the array
#if mode is set to 2, hide all squares in the array
func highlight_squares(var vs:PoolVector2Array = [], var mode:int = 1) -> void:

	#"clear" previous squares by ignoring the last sent texture to the shader
	if mode == 1:
		mat_highlight.set_shader_param("highlight_count", 0)
	
	#don't create a new image if no squares are being selected
	if vs.empty(): return
	
	#shaders can't take in arrays, so use a texture with a height of 1 instead
	var image:Image = Image.new()
	#format 9 stores two values with floating point precision
	image.create(vs.size(), 1, false, 15)
	image.lock()
	for i in vs.size():
		var c:Color = Color(vs[i].x, vs[i].y, 0.0)
		image.set_pixel(i, 0, c)
	var tex:ImageTexture = ImageTexture.new()
	tex.lossy_quality = 1.0
	tex.create_from_image(image)
	mat_highlight.set_shader_param("highlights", tex)
	mat_highlight.set_shader_param("highlight_count", vs.size())

#use board.mark to highlight a set of square meshes from a starting square v
func mark(var v:Vector2) -> void:
	var pos = board.mark(v)
	board.marks = pos
	board.set_selected(v)
	highlight_squares(pos.keys())
	
#run this method whenever a player clicks on a square
#generally handles all interactions a Player object could have with the main Board object
func handle(var v:Vector2, var team:int = 0):
	
	var p:Dictionary = board.pieces
	#print(v)

	#check if square is a square that can be moved to
	if v in board.marks:
		#get updates to the board to apply to BoardMesh while updating the Board's data as well
		#execute_turn() update's the boards data from the selected mark and returns the changes for BoardMesh to execute visually
		var changes:Array = board.execute_turn(v)
		if !board.losers.empty(): end()
		for i in changes.size():
			var c = changes[i]
			if c is PoolVector2Array:
				move_piece(c[0], c[1])
			elif c is Array:
				var square:Vector2 = Vector2(c[1],c[2])
				create_piece(board.pieces[square],square)
			elif c is Vector2:
				destroy_piece(c)
			
		
		#clear board marks
		highlight_squares()
		
	#check if square is a selectable piece
	elif v in p && team == p[v].get_team():
		#mark from selectable piece
		mark(v)
		
	return get_team() #get team from board in case there is one player which has to switch

#get the team moving on the current turn from board
func get_team() -> int:
	return board.get_team()

#emit the end game signal into the node tree
func end() -> void:
	emit_signal("end")

#get the arrays of winners and losers from the board
func get_winners() -> PoolIntArray:
	return board.winners
func get_losers() -> PoolIntArray:
	return board.losers
