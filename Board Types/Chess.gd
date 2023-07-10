extends Board2i

var kings:Array[Piece] = [null, null]
func add_piece(p:Piece, pos=null) -> void:
	
	if pos == null: pos = p.get_position()
	
	var i = teams.find(p.get_team())
	if i != -1:
		var old_p = get_piece(pos)
		if p.type is King2i:
			kings[i] = p
		elif old_p is Piece and old_p.type is King2i:
			kings[i] = null
	
	super.add_piece(p, pos)

func _ready():
	super._ready()
	
	kings.sort_custom(func (a:Piece, b:Piece): 
		return a && b && a.get_team().priority > b.get_team().priority)

func should_lose(team_idx:int) -> bool:
	return kings[team_idx] == null
