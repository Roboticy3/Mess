# Mess
Mess is a silly videogame idea I had that I'm making in Godot Engine, it lets people make their own chess variants. 
Right now it doesn't work as a full game, but you can look at the [wiki page](https://github.com/Roboticy3/Mess/wiki) for planned and current functionality.

## Current state of Mess
The pieces dont move. The instruction interpereter for custom pieces is super-advanced conceptually, and I've been putting it off.
My code is a mess. This has always been part of the joke of the project, but moving it to a public GitHub page was done with the thought that maybe I'll learn a little from pull requests and stuff.

## Navigating and using this project
To open the project, import it as a Godot project in Godot 3.x, I haven't tested it with 4.x alphas.
For testing out boards, go to Static Body in the Godot scene and change it's path value to the board you want to load.
For editing boards and pieces, refer to wiki page "Editing Boards and Pieces"

# Mess roadmap (in order)
 - Make better comments so the code isn't completely unreadable to other GitHub users
 - Make game comprehensible to look at
 - Rework Instruction.gd to be more modular to allow for greater versatility in the way players write custom pieces
 - Add step-wise marking and turns to make the game playable
 - Finish Portal.gd and how other scripts handle it
 - Make docs for piece and board editors
 - Add a main menu and level select
 - Make the game compatible with both couch and peer-to-peer multiplayer
 - Release beta branch of project

## Mess probably-wont-get-to-it roadmap (not in order)
 - Visual board and piece editors in-game with tutorials on how to use them
 - Add enough distinguishing features to the game to separate the project from its current branch and push the project to Steam as a cheap (but not free) game, users would still be able to access the project here but would be paying to keep up with updates and use features such as Steam Workshop support.
 - Refactor whole project with better code
 - Create proper documentation wiki for making user-creations

I've never made a large scale project before. School and other life things will be cause for frequent and long breaks.
But, little by little I'll chisel away at this thing and gain more experience and better practice for dealing with the large scale.

### Immediate improvements down the line
In the Notes folder there is a text file called log_and_plan.txt, it contains my session-to-session notes on what to do.
The other file, long_term.md, contains slightly larger goals that most have to do with keeping the project clean.
	in long_term, finished goals are prefixed by tildes ~, and unfinished ones are untagged.
Right now I'm at the top of the Roadmap above.

by Pablo Ibarz
