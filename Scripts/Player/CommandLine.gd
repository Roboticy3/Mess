extends LineEdit
class_name CommandLine

#the commandline is a text medium for a user to interact with a board using a player

#button to send a command
@export var send_action := "ui_text_completion_accept"

#path to the player that this commandline should use to interact with a board
@export_node_path("Player") var player_path
@onready var player:Player = get_node(player_path)

#check for the button to send a command
func _input(event):
	if event.is_action_pressed(send_action) && !text.is_empty():
		send()
		text = ""

#send a command by matching the first word in this commandline to something in the constant list of commands
#then run that command with the rest of the words as arguments
func send():
	if !player.board:
		Accessor.a_print("Player " + str(player) + " has no Board")
		return
	
	var s := text.split(" ")
	var args := s.slice(1)
	
	Accessor.a_print(text)
	
	match s[0]:
		commands[0]: select_piece(args)
		commands[1]: play(args)
		commands[2]: show_state(args)
		commands[3]: undo(args)
		commands[4]: show_options(args)
		commands[5]: execute_mcs(args)

const commands := [
	"select",
	"move",
	"show",
	"undo",
	"options",
	"macro"
]

func select_piece(args:Array):
	
	if args.size() < 2:
		Accessor.a_print("not enough arguments to select")
		return
	
	player.select_piece(args_to_vector2i(args))

func play(args:Array):
	
	if !player.selection:
		Accessor.a_print("cannot move a piece with no selection")
		return
	
	if args.size() < 2:
		Accessor.a_print("not enough arguments to move")
		return
	
	player.play(args_to_vector2i(args))

func show_state(args:Array):
	
	var b := player.board
	var idx := b.get_turn()

	var c := false
	if !args.is_empty():
		if args.has("-a"):
			for s in b.states:
				Accessor.a_print(
					Accessor.shaped_2i_state_to_string(s, b.get_shape())
				)
			return
		
		c = args.has("-c")
		
		idx = args.back().to_int()
	
	if idx >= b.states.size() || -idx > b.states.size():
		Accessor.a_print("state " + str(idx) + " out of bounds")
		return
	
	if c: Accessor.a_print(
		Accessor.shaped_2i_state_to_string(b.current_state, b.get_shape())
	)
	else: Accessor.a_print(
		Accessor.shaped_2i_state_to_string(b.get_state(idx), b.get_shape())
	)

func undo(args:Array):
	var b := player.board
	var s := b.undo()
	
	if !args.is_empty() && args[0] == "-a":
		while b.get_turn() > 1:
			undo([])
	
	Accessor.a_print(
		"undid:\n" + Accessor.shaped_2i_state_to_string(s, b.get_shape())
	)
	
	Accessor.a_print(
		"current:\n" + Accessor.shaped_2i_state_to_string(b.current_state, b.get_shape())
	)

func show_options(args:Array[String]):
	var a := args.has("-a")
	var b := player.board
	
	if !player.selection && !a:
		Accessor.a_print("cannot show options of a piece with no selection, use -a argument to show options on all pieces")
		return
	
	if a:
		for pos in b.current_state:
			var p = b.current_state[pos]
			if !(p is Piece):
				continue
				
			var p_o = p.options
			
			if !(p_o is Dictionary) || p_o.is_empty():
				continue
			
			Accessor.a_print(str(p))
			
			_show_options(p, b)
			
		return
	
	_show_options(player.selection, b)

func _show_options(p:Piece, b:Board):
	var p_o := p.options 
	for o in p_o:
		Accessor.a_print(str(o) + ":")
		if p_o is Dictionary:
			Accessor.a_print(
				Accessor.shaped_2i_state_to_string(p_o[o], b.get_shape())
			)
		else:
			Accessor.a_print(str(p_o[o]))

func args_to_vector2i(args:Array) -> Vector2i:
	var x = args[0].to_int()
	var y = args[1].to_int()
	return Vector2i(x, y)

func execute_mcs(args:Array):
	if args.is_empty():
		Accessor.a_print("path argument requred to execute a macro")
		return
	
	if !args[0].ends_with(".mcs"):
		Accessor.a_print("path argument must end in .mcs to be a macro")
		return
	
	var mcs := FileAccess.open("Macros/" + args[0], FileAccess.READ)
	text = mcs.get_line()
	
	while !mcs.eof_reached():
		
		if !text.begins_with("#"): 
			send()
		
		text = mcs.get_line()
	
