extends Node
class_name CopyProperties

var reciever_prop:="text"

@export_node_path var source_path := NodePath("/root/Accessor")
@onready var source = get_node(source_path)
@export var source_prop:="a_debug"

@export var copy_every_frame := false
@export var copy_on_ready := true

@export var copy_signal := "a_print_signal"

func _ready():
	if !copy_every_frame:
		set_process(false)
	
	source.connect(copy_signal, copy)
	
	if copy_on_ready: copy()

func _process(_delta):
	copy()

func copy ():
	var x = source.get(source_prop)
	set(reciever_prop, x)
