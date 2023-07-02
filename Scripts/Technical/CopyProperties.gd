extends Node
class_name CopyProperties

#copies a property from one Node to this Node, 
#default values show settings to copy the debug text from Accessor

#the variable in this Node being assigned to
var reciever_prop:="text"

#the path to the source being copied from, and the name of the variable being copied from this source
@export_node_path var source_path := NodePath("/root/Accessor")
@onready var source = get_node(source_path)
@export var source_prop:="a_debug"
#copies when this signal is emitted from the source
@export var copy_signal := "a_print_signal"

#flags
@export var copy_every_frame := false
@export var copy_on_ready := true

func _ready():
	source.connect(copy_signal, copy)
	
	set_process(copy_every_frame)
	if copy_on_ready: copy()

func _process(_delta):
	copy()

func copy ():
	var x = source.get(source_prop)
	set(reciever_prop, x)
