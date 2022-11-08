extends Node

var debug = [null,null]
var board = null

var enabled = true

#init is called when Accessor is first loaded on game startup, ready is called whenever the SceneTree is reloaded
#both of these situations should lead to an attempted reload of the debuggers
func _init():
	#skip if Accessor is disabled
	if !enabled: return
	
	debug[0] = get_node_or_null("/root/Spatial/Debug/GraphVectorize")
	debug[1] = get_node_or_null("/root/Spatial/Debug/GraphMarkStep")
	print(debug)
	var bm = get_node_or_null("/root/Spatial/Board")
	if bm: board = bm.board

func _ready():
	enabled = true
	_init()
