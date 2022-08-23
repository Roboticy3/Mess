extends Node

export (String) var target_property_name = "rect_position"
export (Vector2) var offset = Vector2(-13, -35)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass

func _process(_delta):
	set(target_property_name, get_viewport().get_mouse_position() + offset)
