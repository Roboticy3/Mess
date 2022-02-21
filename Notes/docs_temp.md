#Writing Text Instructions for Boards and Pieces (and everything you need to know about my shitty project)

##Board and Piece files (named b_name.txt and p_name.txt respectively)
	These text files define the behaviour of the game, and are separated into predefined stages entered via single characters.
	All files are read in order and start at the metadata (-1) phase, where the object's name, mesh file path, and any number of builtin or custom float properties are defines like so:

board_name

mesh.obj

variable 0 #variable with value of zero

##Board Stages and Builtin Variables

##Piece Stages and Builtin Variables
