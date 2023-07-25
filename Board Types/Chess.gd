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
		kings = BoardVariant.new(kings.data.duplicate())
		kings.data[p.get_team()] = p
		add_element(kings, "kings")

func remove_piece(p:Piece, pos=null, r=Removed.new()):
	var res = super.remove_piece(p, pos, r)
	
	if p.type is King2i:
		kings = BoardVariant.new(kings.data.duplicate())
		kings.data.erase(p.get_team())
		add_element(kings, "kings")
		print(p, self)
	
	return res

func _evaluate() -> bool:
	
	var t = get_team(null, get_turn())
	return !current_state["kings"].data.has(t)
