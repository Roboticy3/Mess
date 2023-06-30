class_name CustomTypes

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
