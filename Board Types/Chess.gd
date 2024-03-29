extends Board2i

var kings := BoardVariant.new({})

func _init():
	add_element(kings, "kings")
	super._init()

func undo() -> Dictionary:
	var res:= super.undo()
	kings = current_state["kings"]
	
	return res

func add_piece(p:Piece, pos=null) -> void:
	super.add_piece(p, pos)
	
	if p.type is King2i:
		var k = get_element("kings").data.duplicate()
		k[p.get_team()] = p
		add_element(BoardVariant.new(k), "kings")

func remove_piece(p:Piece, pos=null, r=Removed.new()):
	var res = super.remove_piece(p, pos, r)
	
	if p.type is King2i:
		var k = get_element("kings").data.duplicate()
		k.erase(p.get_team())
		add_element(BoardVariant.new(k), "kings")
	
	return res

func _evaluate() -> bool:
	
	var t = get_team(null, get_turn())
	return !current_state["kings"].data.has(t)
