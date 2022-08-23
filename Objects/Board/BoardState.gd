class_name BoardState
extends Node

#BoardState class by Pablo Ibarz
#created August 2022

#store only the part of a Board that changes during each turn

#the turn this BoardState represents in the Board
var turn:int

#dictionary of pieces representing the state of the board at the above turn
#only holds pieces that are different from the pieces in the last state
var pieces := {}

#reference to the Board that this BoardState belongs to
var board

#arrays of winning and losing teams in this state
var winners:Array = []
var losers:Array = []

#array of possible BoardStates for the turn after this one's
var possible:Array = []

#a BoardState can be built from the owner board, and will interperet the current turn
func _init(var _board = null):
	
	#do not try to initialize from a null board
	if _board == null: return
	
	#fill properties with the given arguments
	board = _board
	
	#fill the rest of the properties from the board
	turn = board.get_turn()

#copy of Board.clear(), with the addition of a check to see if another BoardState already freed each piece
func clear() -> void:
	pieces.clear()
	
#print out all of the pieces in this BoardState
func _to_string():
	
	var s:String = "\n"
	
	#find the smallest square that contains all of the pieces
	var minimum:Vector2 = Vector2.INF
	var maximum:Vector2 = -Vector2.INF
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
				if p == null:
					s += "."
				else:
					s += String(pieces[v].get_name())[0]
			else:
				s += "."
			s += " "
		#add a new line at the end of each row
		s += "\n"
		
	return s
	
