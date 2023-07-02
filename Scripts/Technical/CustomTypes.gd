class_name CustomTypes

#my own implementation of Variant.TYPE for all the bs custom classed im throwing around in this project
#super hacky, but it works

#preloaded by Accessor so everything in this script can be declared as const
#please do not use this anywhere else, i will not try because i am not interested in the devastation that may cause

#to add a new Type, add its enumerator to the TYPE enum, then add its name to the names array

enum TYPE {
	BOARD,
	PIECE,
	TEAM,
	BOUND,
	UNDEF
}
static func of(ob) -> TYPE:
	if ob is Board: return TYPE.BOARD
	elif ob is Piece: return TYPE.PIECE
	elif ob is Team: return TYPE.TEAM
	elif ob is Bound: return TYPE.BOUND
	
	return TYPE.UNDEF

const names:PackedStringArray = [
	"Board",
	"Piece",
	"Team",
	"Bound",
	"Undef"
]
static func get_name(t:TYPE) -> String:
	return names[t]
