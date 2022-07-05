class_name LoadScene
extends Node

#LoadScene class by Pablo Ibarz
#created July 2022

#When this button is pressed, load a Scene from a path,
#and assign a set of properties matching values.

#scene to move to
export (PackedScene) var scene:PackedScene
#signal to load the scene
export (String) var load_signal := "button_up"

#board path to be sent to the next scene
export (String) var path := ""

#state of the current scene
var current:SceneTree

#signal to send if change_scene() fails
signal failed_to_load

#connect the release of this button to changing the scene
func _ready():
	current = get_tree()
	var con_error:int = connect(load_signal, self, "change_scene")
	if con_error > 0: print(name + " has no signal \"" + load_signal + "\"")

#change the scene
func change_scene():
	
	if path.empty():
		emit_signal("failed_to_load")
		return
	
	#get the tree so the root Viewport can be accessed
	var tree:SceneTree = get_tree()
	var root:Viewport = tree.root
	
	#remove all children from the root node and free them later
	var nodes:Array = root.get_children()
	for n in nodes:
		root.remove_child(n)
		n.call_deferred("free")
	
	#load the new scene and give it the data it needs to instantiate correctly
	var next_scene:Node = scene.instance()
	next_scene.set("path", path)
	
	#add the scene into the SceneTree to load it into the game
	root.add_child(next_scene)


