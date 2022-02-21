class_name Team
extends Node

var color = Color.white

#All of the piece which belong to this team
var pieces:Dictionary = {}
#Store lost pieces to display them in some row out of bounds
var lost:Array = []

#friendly fire and forward properties usually override those of individual Piece objects
var ff:int = 0
var forward:Vector2 = Vector2(1, 0)

var selected:Vector2 = Vector2(0, 0)
var players:Array

var turn:int = 0

func _init(var _c:Color = Color.white, var _f:Vector2 = Vector2(0, 1), var _ff = false):
	color = _c
	ff = _ff
	forward = _f
	
func _to_string():
	return "Color: " + String(color) + ", FF: " + String(ff) + ", Forward Direction: " + String(forward)
