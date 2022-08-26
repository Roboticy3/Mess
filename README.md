# Mess
Mess is a silly videogame idea I had that I'm making in Godot Engine, it lets people make their own chess variants. 
Right now it doesn't work as a full game, but you can look at the [wiki page](https://github.com/Roboticy3/Mess/wiki) for planned and current functionality.

## Current state of Mess
The pieces are moving! (sorta)
I'm currently optimizing my mesh searching algorithms to better handle larger meshes, so larger boards like b_klein perform very badly right now.

## Navigating and using this project
To open the project, import it as a Godot project in Godot 3.x, I haven't tested it with 4.x alphas.
For testing out boards, go to the Static Body in the Godot scene and change it's path value to the board you want to load.
For editing boards and pieces, refer to wiki page "Creating and Editing Boards and Pieces"

# Mess roadmap (in order)
 - Finish Portal.gd and how other scripts handle it
 - Add a main menu and level select
 - Make the game compatible with both couch and peer-to-peer multiplayer
 - Release beta branch of project
 - Take the project off public Github to work on singleplayer/campaign levels with the mechanics.

## Mess probably-wont-get-to-it roadmap (not in order)
 - Visual board and piece editors in-game with tutorials on how to use them
 - Add enough distinguishing features to the game to separate the project from its current branch and push the project to Steam as a cheap (but not free) game, users would still be able to access the project here but would be paying to keep up with updates and use features such as Steam Workshop support.
 - Create proper documentation wiki for making user-creations

I've never made a large scale project before. School and other life things will be cause for frequent and long breaks.
But, little by little I'll chisel away at this thing and gain more experience and better practice for dealing with the large scale.

### Immediate improvements down the line
In the Notes folder there is a text file called log_and_plan.txt, it contains my session-to-session coding notes on what to do.

### What to do with the game right now
Make boards and pieces using the wiki and load them to test them out.

by Pablo Ibarz
