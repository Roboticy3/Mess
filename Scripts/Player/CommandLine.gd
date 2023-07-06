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
		commands[3]: undo()
		commands[4]: show_options(args)

const commands := [
	"select",
	"move",
	"show",
	"undo",
	"options"
]

func select_piece(args:Array[String]):
	
	if args.size() < 2:
		Accessor.a_print("not enough arguments to select")
		return
	
	player.select_piece(args_to_vector2i(args))

func play(args:Array[String]):
	
	if !player.selection:
		Accessor.a_print("cannot move a piece with no selection")
		return
	
	if args.size() < 2:
		Accessor.a_print("not enough arguments to move")
		return
	
	player.play(args_to_vector2i(args))

func show_state(args:Array[String]):
	
	var b := player.board
	var idx := b.states.size() - 1

	var c := false
	if !args.is_empty():
		if args.has("-a"):
			for s in b.states:
				Accessor.a_print(
					Accessor.shaped_2i_state_to_string(s, b.shape)
				)
			return
		
		c = args.has("-c")
		
		idx = args.back().to_int()
	
	if idx >= b.states.size() || -idx > b.states.size():
		Accessor.a_print("state " + str(idx) + " out of bounds")
		return
	
	if c: Accessor.a_print(
		Accessor.shaped_2i_state_to_string(b.current_state, b.shape)
	)
	else: Accessor.a_print(
		Accessor.shaped_2i_state_to_string(b.get_state(idx), b.shape)
	)

func undo():
	var b := player.board
	var s := b.undo()
	
	Accessor.a_print(
		"undid:\n" + Accessor.shaped_2i_state_to_string(s, b.shape)
	)
	
	Accessor.a_print(
		"current:\n" + Accessor.shaped_2i_state_to_string(b.current_state, b.shape)
	)

func show_options(args:Array[String]):
	var a := args.has("-a")
	var b := player.board
	
	if !player.selection && !a:
		Accessor.a_print("cannot show options of a piece with no selection, use -a argument to show options on all pieces")
		return
	
	if a:
		for pos in b.current_state:
			var p:Piece = b.current_state[pos]
			if !(p is Piece):
				continue
				
			var p_o := p.options
			
			if p_o.is_empty():
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
				Accessor.shaped_2i_state_to_string(p_o[o], b.shape)
			)
		else:
			Accessor.a_print(str(p_o[o]))

func args_to_vector2i(args:Array) -> Vector2i:
	var x = args[0].to_int()
	var y = args[1].to_int()
	return Vector2i(x, y)
