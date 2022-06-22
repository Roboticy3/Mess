class_name Team
extends Node

var color = Color.white

#All of the piece which belong to this team
var pieces:Dictionary = {}
#Store lost pieces to display them in some row out of bounds
var lost:Array = []

#position of this team in a Board's Team array
var i:int = 0

#friendly fire and forward properties usually override those of individual Piece objects
var ff:int = 0
var forward:Vector2 = Vector2.DOWN

var selected:Vector2 = Vector2.ZERO
var players:Array

var turn:int = 0

func _init(var _c:Color = Color.white, var _f:Vector2 = Vector2(0, 1), 
	var _ff:int = 0, var _i:int = 0):
	color = _c
	ff = _ff
	forward = _f
	i = _i
