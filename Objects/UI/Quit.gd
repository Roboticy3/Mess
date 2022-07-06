extends Node

export (String) var quit_signal:String = "button_down"

func _ready():
	connect(quit_signal, self, "quit")

func quit():
	get_tree().quit()
