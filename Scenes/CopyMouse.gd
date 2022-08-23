extends Node

export (String) var target_property_name = "rect_position"
export (Vector2) var offset = Vector2(-13, -35)

func _process(delta):
	set(target_property_name, get_viewport().get_mouse_position() + offset)
