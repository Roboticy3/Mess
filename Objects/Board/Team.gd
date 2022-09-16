class_name Team

#position of this team in a Board's Team array
var i:int = 0

var board

#aw shit here we go again
var table:Dictionary = {"ff":0,"fx":0,"fy":1,"angle":0, #friendly fire, forward driection and angle
	"sx":INF,"sy":INF, #selected position
	"cr":1.0,"cg":1.0,"cb":1.0, #team color
	"turn":0, "name":"team"}

#store keys that table and pieces' tables have at the beginning of the game to keep track of their values even if they dissapear
var start_keys:Array = []

func _init(var _b = null, var _c:Color = Color.white, var _f:Vector2 = Vector2(0, 1), var _i:int = 0):
	
	board = _b
	
	set_color(_c)
	set_forward(_f)
	i = _i
	set_name("team " + String(i))
	
	start_keys = table.keys()
	
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
#set false to true to ignore this check
func set_selected(var s:Vector2, var force := false) -> bool:
	if force || board.get_piece(s) != null: 
		table["sx"] = s.x
		table["sy"] = s.y
		return true
	return false
	
func get_selected() -> Vector2:
	return Vector2(table["sx"],table["sy"])
	
func set_name(var name := "team") -> void:
	table["name"] = name
	
func get_name() -> String:
	return table["name"]
	
func get_turn() -> int:
	return table["turn"]
	
#get and keys act on table
	
#return value paired with the input key from the team's table
#if the key is in any pieces' tables, returns the sum of that key's piece values across all pieces
func get(var key:String):
	
	#return value to modify, not strongly typed because it could either be a float, int or string in the end
	var value = 0
	#set to true when key is found in a piece table
	var in_pieces := false
	
	#loop through every piece
	var pieces = board.get_pieces()
	if key.match("key"): print(BoardConverter.pieces_to_string(pieces))
	for v in pieces:
		
		if pieces[v].get_team() != i: continue
		
<<<<<<< Updated upstream
#		if pieces[v].get_name().match("King"):
#			print(pieces[v])
=======
		if pieces[v].get_name().match("King"):
			#print(pieces[v])
			pass
>>>>>>> Stashed changes
		
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
	
func keys() -> Array: return start_keys

func set_color(var c:Color) -> void:
	table["cr"] = c.r
	table["cg"] = c.g
	table["cb"] = c.b
	
func get_color() -> Color:
	return Color(table["cr"],table["cg"],table["cb"])
	
func _to_string() -> String:
	
	var s:String = ""
	
	#find the smallest square that contains all of the pieces
	var minimum:Vector2 = Vector2.INF
	var maximum:Vector2 = -Vector2.INF
	var pieces = board.current
	for v in pieces:
		if v.x < minimum.x: minimum.x = v.x
		if v.y < minimum.y: minimum.y = v.y
		if v.x > maximum.x: maximum.x = v.x
		if v.y > maximum.y: maximum.y = v.y
	
	#fill the tiles with pieces in them with the first char of their name, fill the others with dots
	for r in range(minimum.y, maximum.y + 1):
		for c in range(minimum.x, maximum.x + 1):
			var v:Vector2 = Vector2(c,r)
			if pieces.has(v):
				
				var p = pieces[v]
				
				if p == null || p.get_team() != i:
					s += "."
				else:
					s += pieces[v].get_name().substr(0,1)
			else:
				s += "."
			s += " "
		#add a new line at the end of each row
		s += "\n"
	
	return s + String(table)
	
