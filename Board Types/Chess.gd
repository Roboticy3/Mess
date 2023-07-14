extends Board2i

func _init():
	
	starting_state["x"] = 0
	dynamic_state_keys = ["x"]
	
	super._init()

func _ready():
	super._ready()

func add_piece(p:Piece, pos=null):
	super.add_piece(p, pos)
	
	get_state()["x"] += 1

func remove_piece(p:Piece, pos=null):
	super.remove_piece(p, pos)
	
	get_state()["x"] -= 1

func _evaluate():
	super._evaluate()

