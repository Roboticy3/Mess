extends Board2i

func _init():
	starting_state["kings"] = {}
	
	super._init()

func _ready():
	super._ready()

func add_piece(p:Piece, pos=null):
	super.add_piece(p, pos)

func remove_piece(p:Piece, pos=null):
	var r = super.remove_piece(p, pos)

func _evaluate():
	super._evaluate()

