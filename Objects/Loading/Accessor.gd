extends Node

onready var debug_vectorize_exec_times = get_node("/root/Spatial/Debug/GraphVectorize")
onready var debug_mark_step_exec_times = get_node("/root/Spatial/Debug/GraphMarkStep")

func _init():
	debug_vectorize_exec_times = get_node("/root/Spatial/Debug/GraphVectorize")
	debug_mark_step_exec_times = get_node("/root/Spatial/Debug/GraphMarkStep")

func _ready():
	_init()
	print(debug_vectorize_exec_times,debug_mark_step_exec_times)
