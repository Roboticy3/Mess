class_name PieceMesh
extends KinematicBody

var piece:Piece
var board:Board

var shape:CollisionShape
var mesh:ArrayMesh
var mdt:MeshDataTool
#the piece's footprint of its base relative to its scale
var aabb:AABB
var mat:Material

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
	aabb = mesh.get_aabb()
	mat = _mat
	_ready()

# Called when the node enters the scene tree for the first time.
func _ready():
	#get mesh from path
	if mesh == null: 
		mesh = BoardConverter.path_to_mesh(piece.mesh, false)
	
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
	
	#print(get_children())
	

func _to_string():
	return piece._to_string()
	
#generate material of a piece from itself and its parent board
static func pmat(var p:Piece = piece, var b:Board = board):
	var t = b.teams
	if p.team < t.size():
		var m = SpatialMaterial.new()
		m.albedo_color = t[p.team].color
		return m
	return SpatialMaterial.new()
