extends LineEdit
class_name CommandLine

#the commandline is a text medium for a user to interact with a board as a player

#button to send a command
@export var send_action := "ui_text_completion_accept"

#path to the player that this commandline should use to interact with a board
@export_node_path("Player") var player_path
@onready var player:Player = get_node(player_path)

#check for the button to send a command
func _process(_delta):
	if !text.is_empty() && Input.is_action_just_pressed(send_action):
		send()

#send a command by matching the first word in this commandline to something in the constant list of commands
#then run that command with the rest of the words as arguments
func send():
	var s := text.split(" ")
	var args := s.slice(1)
	
	Accessor.a_print(text)
	
	match s[0]:
		commands[0]: select_piece(args)
		commands[1]: play(args)
		commands[2]: show_state(args)
	
	text = ""

const commands := [
	"select",
	"move",
	"show"
]

func select_piece(args:Array[String]):
	
	if args.size() < 2:
		Accessor.a_print("not enough arguments to select")
		return
	
	var b := player.board
	match b.position_type:
		TYPE_NIL:
			Accessor.a_print("cannot select on board with position type TYPE_NIL")
			return
		TYPE_VECTOR2I: player.select_piece(args_to_vector2i(args))

func play(args:Array[String]):
	
	if !player.selection:
		Accessor.a_print("cannot move a piece with no selection")
		return
	
	if args.size() < 2:
		Accessor.a_print("not enough arguments to move")
		return
	
	var b := player.board
	match b.position_type:
		TYPE_VECTOR2I: player.play(args_to_vector2i(args))

func show_state(args:Array[String]):
	
	var idx := player.board.states.size() - 1
	
	if !args.is_empty():
		if args[0] == "-r" && args.size() > 1:
			idx += args[1].to_int()
		elif args[0] != "-r":
			idx = args[0].to_int()
	
	Accessor.a_print(
		Accessor.shaped_2i_state_to_string(player.board.get_state(idx))
	)

func args_to_vector2i(args:Array) -> Vector2i:
	var x = args[0].to_int()
	var y = args[1].to_int()
	return Vector2i(x, y)
