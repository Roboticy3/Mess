class_name PieceType
extends Node

#PieceType class by Pablo Ibarz
#created August 2022

#stores Piece data that is the same across all Pieces being loaded from the same path

#the path to the piece type
export (String, FILE, "p_*.txt") var path := ""
var div := ""

#the instructions
var mark := []
var destroy := []
var create := []
var relocate := []

#reference to the board
var board

#starting table for this piece type
var table := {"name":"*pieceName*", "mesh":"Instructions/pieces/default/meshes/pawn.obj",
			 "moves":0, "fx":0, "fy":0, "ff":0,
			 "scale_mode": 0, "rotate_mode":0, "translate_mode":0,
			 "scale": 1.0/3.0, "px":0, "py":0, "angle":0, "opacity": 1,
			 "team":0, "collision":0, "lx":0, "ly":0}

func _init(var _board = null, var _path := ""):
	if _board == null: return
	board = _board
	path = _path
	_ready()

func _ready():
	#add .txt to the end of the file path if its not already present
	if !path.ends_with(".txt"):
		path += ".txt"
		
	#set div to only include the file path up to the location of the piece
	div = path.substr(0, path.find_last("/") + 1)
	
	#create list of interperetation functions to send to a Reader
	#Piece only needs to add the mark instructions at ready
	var funcs:Dictionary = {"m":"m_phase","t":"t_phase","c":"c_phase","r":"r_phase"}
	#use Reader to interperet the instruction file into usable behavior 
	var r:Reader = Reader.new(self, funcs, path, 3, board, true, false)
	#if Reader sees a bad file, do not continue any further
	if r.badfile: return
	r.read()
	
#initialize variables in this Board's table
#warning-ignore:unused_argument
#warning-ignore:unused_argument
func _phase(var I, var vec:Array = [], var persist:Array = []):
	
	#try to update table from metadata line, essentially initializing the table
	#only do table updates if I vectorizes to a non-empty array, this will allow for primitive conditionals before piece vars
	var key:String = ""
	var s = I.to_string_array()
	if !s.empty(): key = I.update_table(table)
	#if no key was returned, update table has failed
	if key.empty(): return
	
	#let meshes access folders outside of this piece's pack if they start with an @
	if key.match("mesh"):
		if table[key].begins_with("@"):
			table[key] = table[key].substr(1, -1)
		else: table[key] = div + table[key]
	
#Piece behaviour phases are interpereted on the fly by a Board object,
#and therefore only the instruction needs to be stored
#warning-ignore:unused_argument
#warning-ignore:unused_argument
func m_phase(var I, var vec:Array = [], var persist:Array = []) -> void:
	var c:String = I.contents
	#primitive comment parser and empty checking to avoid adding empty marks
	c = c.substr(0, c.find("#"))
	if !c.empty(): mark.append(I)

#warning-ignore:unused_argument
#warning-ignore:unused_argument
func t_phase(var I, var vec:Array = [], var persist:Array = []) -> void:
	var c:String = I.contents
	c = c.substr(0, c.find("#"))
	if !c.empty(): destroy.append(I)

#warning-ignore:unused_argument
#warning-ignore:unused_argument
func c_phase(var I, var vec:Array = [], var persist:Array = []) -> void:
	var c:String = I.contents
	#primitive comment parser and empty checking to avoid adding empty marks
	c = c.substr(0, c.find("#"))
	if !c.empty(): create.append(I)

#warning-ignore:unused_argument
#warning-ignore:unused_argument
func r_phase(var I, var vec:Array = [], var persist:Array = []) -> void:
	var c:String = I.contents
	c = c.substr(0, c.find("#"))
	if !c.empty(): relocate.append(I)
