extends KinematicBody
class_name Player

#Player class created by Pablo Ibarz
#created January 2022

#store a reference to the board in the scene
export (Resource) var board
#store reference to BoardMesh object in the physical board
export (Resource) var board_mesh

#the team with which the player can interact with
export (int) var team = 0

#distance a player can click to
export (int) var vision = 2000000

#Player script object should be attached to a KinematicBody with Camera child
var camera:Camera

#debug cube is an object than can be moved around to visualize test features
var debug_cube:CSGBox

#map of keyboard keybinds using scancode for key buttons and button indices for mouse buttons
var keymap:Dictionary = {"z":87,"x":68,"-z":83,"-x":65,"y":32,"-y":16777237,
						"slct":1,"grab":2, "zin":4, "zout":5}
				
#keep track of the player's target_motion and camera rotation
#this way the global input map doesn't have to be used
var target_motion:Dictionary = {"z":0, "x":0, "y":0, "r":Vector2.ZERO, "zoom":0}
#momentum chases target_motion to smooth movement
var momentum:Dictionary = {"z":0, "x":0, "y":0, "zoom":0}

#the acceleration of momentum in u/s/s
export (float) var accel = 50.0

#speed of the player in u/s
export (float) var speed = 5.0

#sensitivity of the player in rad/100pix
export (float) var sens = 0.75

#last click the player made in uv_space
export (Vector2) var uv_last = Vector2.ZERO

#whether or not the camera is rotating
var looking:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#find camera in children
	var children = get_children()
	for c in children:
		if c is Camera:
			camera = c
	
	#player should be a child of a rigidbody, get siblings of rigid body to gain references to board and debug cube
	var siblings = get_parent().get_children()
	for s in siblings:
		if s is CSGBox:
			debug_cube = s

#run movement functions on physics timestep
func _physics_process(delta):
	look(delta)
	accelerate(delta)
	move(delta)
	
#apply acceleration so momentum approaches target_motion
func accelerate(var delta:float):
	for tm in momentum.keys():
		var d = sign(target_motion[tm] - momentum[tm])
		momentum[tm] += d * accel * delta

#set target_motion to player transforms
func move(var delta:float):
	#get local axes of the camera
	var axes = transform.basis
	
	#flatten y of axes for movement
			#flip z axis
	axes = {"z":(axes.z * -Vector3(1, 0, 1)).normalized(),
			"x":(axes.x * Vector3(1, 0, 1)).normalized(),
			#up is always up
			"y":Vector3.UP}
	
	#multiply vectors by target_motion and apply the translation and rotation
	#flip z
	var vector = Vector3.ZERO
	for a in axes.keys():
		vector += axes[a] * momentum[a] * delta
	
	#move by origin
	#transform.origin += vector * delta
	
	#use move_and_collide to stop player from moving through the board
	var col = move_and_collide(vector)

func look(delta):
	#multiply rotation motions by delta and sens
	var axes = transform.basis
	var rots = target_motion["r"] * delta * -sens/100
	#use true y axis for horizontal rotation to make rotation more intuitive
	transform = rotate(Vector3.UP, rots.x)
	#do not rotate vertical camera past cutoffs
	var limit = 0.95
	var rot = rotate(axes.x, rots.y)
	if abs(rot.basis.z.y) < limit:
		transform = rot
	#counteract any roll that the camera might have suffered
	var tilt = (transform.basis.x / transform.basis.y).y
	transform = rotate(transform.basis.z, -tan(tilt))
	
	#reset mouse movement so user does not have to send another input to stop the camera
	target_motion["r"] = Vector2.ZERO

#rotated around an axis around the origin
func rotate(var axis:Vector3 = Vector3.UP, var phi:float = 0, var origin:Vector3 = Vector3.ZERO):
	var o = transform.origin
	var t = transform
	t.origin = origin
	t = t.rotated(axis, phi)
	t.origin = o
	return t

#activated on button presses and mouse movements
func _input(event):
	if event is InputEventMouseButton || event is InputEventKey:
		update_target_motion(event)
	
	#set rotation vector when looking
	if event is InputEventMouseMotion && looking:
		target_motion["r"] = event.speed

#take an input_event and check if it is a movement key, then use set_target_motion() accordingly
func update_target_motion(var event):
	
	#get value of event based on type
	var escan = 0
	if event is InputEventKey:
		escan = event.scancode
	elif event is InputEventMouseButton:
		escan = event.button_index
	
	for i in keymap.keys():
		#get value on possible movment inputs
		var vscan = keymap[i]
		
		#see if current input matches any set actions
		#if there's a match, execute the appropriate code
		if vscan == escan:
			if i in ["z", "x", "y"]:
				set_target_motion(event.is_pressed(), i)
			elif i in ["-z", "-x", "-y"]: 
				set_target_motion(event.is_pressed(), i)
			elif vscan == keymap["slct"] && event.is_pressed():
				request_square(event)
			#only look if user is right-clicking
			elif vscan == keymap["grab"]:
				#stop values from overflowing on rising or falling edge of click
				target_motion["r"] = Vector2.ZERO
				if event.is_pressed():
					looking = true
				else:
					looking = false

#set target_motion to non-zero if event.is_pressed()
func set_target_motion(var on_off:bool = true, var key:String = "z"):
	var s = speed
	if key.begins_with("-"): 
		s *= -1
		key.erase(0, 1)
	
	if on_off:
		target_motion[key] = s
	else:
		target_motion[key] = 0
		
#try to select a uv from the board
func request_square(var event:InputEventMouseButton):
	var r = BoardConverter.raycast(event.position, camera, 
		get_world(), vision)
	
	#if ray hits something
	if r != null && !r.empty():
		#REWORK check if collider is a piece, if so return piece position
		var square:Vector2
		if r["collider"] is KinematicBody:
			square = r["collider"].piece.pos
		#otherwise, return uv square of board
		else:
			var uv = BoardConverter.mpos_to_uv(board_mesh.mdt, 
				board_mesh.transform, transform, r["position"])
			
			square = BoardConverter.uv_to_square(board_mesh.size, uv)
			
		print(square)
		
		board_mesh.highlight_square([square], 1)
		return square
	return null
