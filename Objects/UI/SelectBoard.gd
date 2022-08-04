class_name SelectBoard
extends MenuButton

#SelectBoard Class by Pablo Ibarz
#created July 2022

#Given a directory, find all the folders containing a board file (e.g. "b_name.txt") in that directory
#Add each folder with a board file into this OptionButton's Item list

#path to the directory where board files are usually stored
export (String) var boards_dir := "Instructions/"
#path to the selected Board
export (String) var path := "Instructions/default/b_default.txt"

#array of folders found that have boards in them
var folders:PoolStringArray = []

var popup:PopupMenu

#signal to send when a board is selected
signal new_selection

func _ready() -> void:
	popup = get_popup()
	refresh()
	#warning-ignore return_value_discarded
	var _con_error:int = popup.connect("id_pressed", self, "select")

#update the text in the MenuButton and the path to the selected Board
func select(var idx:int = -1) -> void:
	text = popup.get_item_text(idx)
	path = folders[idx] + text
	#send the board selection signal
	emit_signal("new_selection")

#search path for valid files and replace the current options of this OptionButton's item list
func refresh() -> void:
	#check if the directory is valid
	var dir := Directory.new()
	var err = dir.open(boards_dir)
	if err != OK: return
	
	#clear the current item list and folder set
	popup.clear()
	folders = PoolStringArray()
	
	#number of new items
	var count:int = 0
	
	#loop through each file in the directory
	dir.list_dir_begin()
	var folder:String = dir.get_next()
	#dir.get_next() will automatically spit out an empty string when the end of the directory is hit
	while !folder.empty():
		
		#if this folder is actually a file, skip the loop
		#this will also catch navigational paths "." and ".."
		if folder.find(".") != -1: 
			folder = dir.get_next()
			continue
		
		#make a directory from the current folder
		var fdir := Directory.new()
		var pf:String = boards_dir + folder + "/"
		#if this folder cannot be opened, skip the loop
		err = fdir.open(pf)
		if err != OK: 
			folder = dir.get_next()
			continue
		
		#open the folder and iterate through its files
		fdir.list_dir_begin(true) #flag to ignore navigational paths
		var file:String = fdir.get_next()
		while !file.empty():
			#skip files that are not text files and are not named as a board would
			if file.find(".") == -1: 
				file = fdir.get_next()
				continue
			if !file.begins_with("b_"): 
				file = fdir.get_next()
				continue
			
			#if the file is still being read, it's probably a board, add it as an option
			popup.add_radio_check_item(file, count)
			#add this folder to the folder array
			folders.append(pf)
			count += 1
			
			file = fdir.get_next()
			
		
		#move onto the next folder
		folder = dir.get_next()
	
	
