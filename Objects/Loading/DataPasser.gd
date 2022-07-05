class_name DataPasser
extends Node

#DataPasser class by Pablo Ibarz
#created July 2022

#attached to the top of a scene tree, recieves data from a LoadScene object in another scene
#passes that data to other nodes on _ready, and also calls methods of those nodes

#BoardMesh Board will be assigned its path and have its begin() method run here
export (NodePath) var board_mesh := NodePath("Board")
var path:String

#apply the values in data to its key paths and initialize Boardmesh
func _ready():
	var bm:BoardMesh = get_node(board_mesh)
	bm.path = path
	bm.begin()
		
