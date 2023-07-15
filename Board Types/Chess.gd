extends Board2i

func _init():
	build = false
	super._init()

func _ready():
	super._ready()

func add_piece(p:Piece, pos=null):
	super.add_piece(p, pos)

func remove_piece(p:Piece, pos=null, r=Removed.new()):
	super.remove_piece(p, pos, r)

func _evaluate():
	super._evaluate()

