extends Node

var debug = [null,null]

#init is called when Accessor is first loaded on game startup, ready is called whenever the SceneTree is reloaded
#both of these situations should lead to an attempted reload of the debuggers
func _init():
	debug[0] = get_node("/root/Spatial/Debug/GraphVectorize")
	debug[1] = get_node("/root/Spatial/Debug/GraphMarkStep")
func _ready():
	_init()
