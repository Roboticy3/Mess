class_name PieceMesh
extends StaticBody

#PieceMesh class by Pablo Ibarz
#created January 2022

#control the visual and physical aspects of a Piece

#reference to Piece and parent Board
var piece:Piece
var board:Board

#collisions, visuals, and mdt for BoardConverter
var shape:CollisionShape
var mesh:ArrayMesh
var mat:Material
var mdt:MeshDataTool
#not sure if I'm actually gonna use AABB
var aabb:AABB

#these properties let PieceMesh access the game and itself
func _init(var _piece:Piece, var _board:Board, 
	#these parameters defined the physical properties of PieceMesh
	var _shape:CollisionShape = null, var _mesh:ArrayMesh = null, var _mat:Material = null):
	
	piece = _piece
	board = _board
	shape = _shape
	mesh = _mesh
	mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	mat = _mat
	
	#generate the aabb and initialize the piece
	aabb = mesh.get_aabb()
	_ready()

# Called when the node enters the scene tree for the first time.
func _ready():
	#get mesh from path
	if mesh == null: 
		mesh = BoardConverter.path_to_mesh(piece.mesh)
	
	#if no collisions were added, make one from mesh
	if shape == null: 
		#add a CollisionShape and CSGMesh child
		#use same function as BoardMesh for creating the piece collision
		shape = CollisionShape.new()
		shape.shape = BoardConverter.mesh_to_shape(mesh)
		add_child(shape)
	
	#create CSGMesh with SpatialMaterial with albedo of team's piece
	var csg = CSGMesh.new()
	csg.mesh = mesh
	csg.material = SpatialMaterial.new()
	#query board teams for material color if necessary
	if mat == null:
		mat = pmat(piece, board)
	#commit the material
	csg.material = mat
	add_child(csg)

func _to_string():
	return piece._to_string()
	
#generate material of a piece from itself and its parent board
static func pmat(var p:Piece = piece, var b:Board = board):
	var t = b.teams
	if p.get_team() < t.size():
		var m = SpatialMaterial.new()
		m.albedo_color = t[p.get_team()].get_color()
		#set opacity based on piece's opacity value multiplied by board's piece_opacity value
		var o:float = p.table["opacity"] * b.table["piece_opacity"]
		if o < 1:
			m.flags_transparent = true
		m.albedo_color.a = o
		return m
	return SpatialMaterial.new()
