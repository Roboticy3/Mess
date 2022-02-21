#Rework file structure
	Change file references in Boards and Pieces to be relative to their directory instead of relative to the project so mesh importing for a piece will take the raw file name since the instruction set and the mesh will be organized under the same board. This will allow for boards to be easily moved around.

#Modulate Instruction.gd
	Change instruction reader to be totally dependent on a word array instead of the raw string to make instructions more flexible.

#Add ""events"" to instructions 
	Assigning a variable if the user selects a marker sharing its instruction line with the assignment, requires modulated instrucitons.

#Add extrusion to BoardConverter.square_to_box()
	square_to_box() is meant to highlight selected or available squares, but right now just proposes a flat plane of the square. It has a lot of rough edges

~Full mesh importing
	Import any mesh with proper uvs and board instructions for a fully automatically generated chessboard :)
