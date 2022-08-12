class_name BoardState
extends Node

#BoardState class by Pablo Ibarz
#created August 2022

#store only the part of a Board that changes during the game
#link to the last and next BoardStates from different turns and look forward into future turns to check for checkmate

#BoardStates of the last and next turn
var last
var next

#the turn this BoardState represents in the Board
var turn:int

#Array of possible BoardStates for the next turn
var possible := []

#dictionary of pieces representing the state of the board at the above turn
#only holds pieces that are different from the pieces in the last state
var pieces := {}

#reference to the Board that this BoardState belongs to
var board

#a BoardState can be built from the owner board, the last and next BoardStates
func _init(var _board = null, var _last = null, var _next = null):
	
	#do not try to initialize from a null board
	if _board == null: return
	
	#fill properties with the given arguments
	board = _board
	#allow last and next to be null in case this BoardState represents the final and/or first turn
	last = _last
	next = _next
	
	#fill the rest of the properties from the board
	turn = board.get_turn()
	#if there is no last BoardState, duplicate the table from Board
	if last == null:
		pieces = board.duplicate_all()
	
#print out all of the pieces in this BoardState
func _to_string():
	
	var s:String
	
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
				s += pieces[v].get_name().substr(0,1)
			else:
				s += "."
			s += " "
		#add a new line at the end of each row
		s += "\n"
		
	return s
	
