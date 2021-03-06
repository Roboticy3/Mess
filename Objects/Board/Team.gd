class_name Team
extends Node

#All of the piece which belong to this team
var pieces:Dictionary = {}
#Store lost pieces to display them in some row out of bounds
var lost:Array = []

#position of this team in a Board's Team array
var i:int = 0

var players:Array

var turn:int = 0

#aw shit here we go again
var table:Dictionary = {"ff":0,"fx":0,"fy":1,"angle":0, #friendly fire, forward driection and angle
	"sx":INF,"sy":INF, #selected position
	"cr":1.0,"cg":1.0,"cb":1.0 #team color
	}

func _init(var _c:Color = Color.white, var _f:Vector2 = Vector2(0, 1), 
	var _ff:int = 0, var _i:int = 0):
	set_color(_c)
	set_ff(_ff)
	set_forward(_f)
	i = _i
	
func set_ff(var mode:int) -> void:
	table["ff"] = mode
	
func get_ff() -> bool:
	return table["ff"]

func set_forward(var f:Vector2) -> void:
	table["fx"] = f.x
	table["fy"] = f.y
	table["angle"] = -f.angle_to(Vector2.DOWN)
	
func get_forward() -> Vector2:
	return Vector2(table["fx"],table["fy"])
	
#set selected if the team has a piece in the input square
#returns false if there is no piece here
func set_selected(var s:Vector2) -> bool:
	if has(s): 
		table["sx"] = s.x
		table["sy"] = s.y
		return true
	return false
	
func get_selected() -> Vector2:
	return Vector2(table["sx"],table["sy"])
	
func has(var v:Vector2) -> bool:
	return pieces.has(v)
	
func erase(var v:Vector2) -> bool:
	return pieces.erase(v)
	
#return value paired with the input key from the team's table
#if the key is in any pieces' tables, returns the sum of that key's piece values across all pieces
func get_table(var key:String):
	
	#return value to modify, not strongly typed because it could either be a float, int or string in the end
	var value = 0
	#set to true when key is found in a piece table
	var in_pieces := false
	
	#loop through every piece
	for v in pieces:
		#if the key is found in a piece's table, add its value to the total value
		var t:Dictionary = pieces[v].table
		if t.has(key):
			#key is now in a piece
			in_pieces = true
			
			#if the value is a String, convert the total value to a String
			if t[key] is String:
				value = String(value) + t[key]
			#otherwise, add the value to the total as a number
			else:
				value += t[key]
	
	#if no result was found from pieces, but one was found from this Team's table,
	#take a value from the Team's table
	if !in_pieces && table.has(key): return table[key]
	#otherwise, return the value
	return value
	
func set_color(var c:Color) -> void:
	table["cr"] = c.r
	table["cg"] = c.g
	table["cb"] = c.b
	
func get_color() -> Color:
	return Color(table["cr"],table["cg"],table["cb"])
	
func _to_string() -> String:
	return "[Team(" + String(i) + ") : " + String(get_color()) + "]"
