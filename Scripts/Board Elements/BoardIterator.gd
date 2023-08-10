class_name BoardIterator

var state:={}

var i:=-1
var pos:=[null]
var val:=[null]
var done:=true

var options:={}

var j:=-1
var o_pos:=[null]
var o_val:=[null]
var o_done:=true

var set_options := false

var all_options_break := false
func all_options_start(b:Board):
	piece_start(b)
	all_options_step(b)
	
	all_options_break = false

func all_options_step(b:Board):
	if done:
		return
	
	options_step()
	
	if o_done:
		while o_done && !done:
			piece_step()
			options_start(b)
		
		options_step()

func piece_start(b:Board):
	state = b.current_state.duplicate()
	
	i = -1
	pos = state.keys()
	val = state.values()
	
	if pos.is_empty():
		done = true
		return
	
	done = false

func piece_step():
	
	i += 1
	while i < pos.size():
		if val[i] is Piece: break
		
		i += 1
		
	if i >= pos.size():
		done = true
		return
	
	done = false

func options_start(b:Board):
	if done: return
	options = val[i].generate_options(b, set_options)
	if set_options: val[i].options = {}
	
	j = -1
	o_pos = options.keys()
	o_val = options.values()
	
	if o_pos.is_empty():
		o_done = true
		return
	
	o_done = false

func options_step():
	
	j += 1
	
	if j >= o_pos.size():
		o_done = true
		return
	
	o_done = false

func is_all_options_done():
	return done

func get_all_options_cur() -> Array:
	return [pos[i], val[i], o_pos[j], o_val[j]]

func all_options_iter_full(b:Board, action:Callable):
	all_options_start(b)
	
	while !done:
		var cur := get_all_options_cur()
		
		action.callv(cur)
		
		all_options_step(b)

func all_options_should_break(yn:=true):
	done = yn
	all_options_break = yn

func all_options_did_break() -> bool:
	return all_options_break
