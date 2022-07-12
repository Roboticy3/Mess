extends KinematicBody
class_name Player

#Player class created by Pablo Ibarz
#created January 2022

#store a reference to the board in the scene
var board:Board
#store reference to BoardMesh object in the physical board
var board_mesh:BoardMesh

#the team with which the player can interact with
export (int) var team = 0

#distance a player can click to
export (int) var vision = 2000000

#Camera child of the Player
export (NodePath) var camera_path:NodePath
var camera:Camera

#Viewport the Player can use to sample uv coordinates from the board
export (NodePath) var viewport_path:NodePath
var uv_query:Node

#debug cube is an object than can be moved around to visualize test features
var debug_cube:CSGBox
				
#keep track of the player's target_motion and camera rotation
#this way the global input map doesn't have to be used
var target_motion:Dictionary = {"v":Vector3.ZERO, "r":Vector2.ZERO, "zoom":0}
#momentum chases target_motion to smooth movement
var momentum:Dictionary = {"v":Vector3.ZERO, "zoom":0}

#the acceleration of momentum in u/s/s
export (float) var accel = 50.0

#speed of the player in u/s
export (float) var speed = 4.0

#sensitivity of the player in rad/100pix
export (float) var sens = 0.75

#dead zone on the controller axes
#index 0 for left stick and 1 for right
export (PoolRealArray) var dead_zone = [0.05, 0.05]
#controller look sensitivity
export (int) var stick_sens = 500

#last click the player made in uv_space
export (Vector2) var uv_last = Vector2.ZERO

#whether or not the camera is rotating
var looking:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#use NodePaths to find nodes
	camera = get_node(camera_path)
	uv_query = get_node(viewport_path)
	
func set_mesh(var mesh:Mesh) -> void:
	uv_query.set_mesh(mesh)

#run movement functions on physics timestep
func _physics_process(delta):
	#apply movement based on momentum
	move_and_slide(momentum["v"])
	#rotate the camera
	look(delta)
	#update momentum based on target_motion
	accelerate(delta)

#handle non-button inputs with Events
func _input(event):
	#if the mouse is moving and the camera rotate button is being held, rotate the camera
	if event is InputEventMouseMotion && Input.is_action_pressed("ck_1"):
		var e:InputEventMouseMotion = event
		target_motion["r"] = e.speed
		
	#if the board_mesh has not been activated yet, do so on the first keystroke
	if !board_mesh.awake && event is InputEventKey:
		board_mesh.begin(board_mesh.path)

#handle button inputs each frame
func _process(_delta):
	#movement buttons sum to velocities along either axis
	var xz:Vector2 = Input.get_vector("mv_left", "mv_right", "mv_forward", "mv_back")
	var y:float = Input.get_axis("mv_down","mv_up")
	#transform x and z movement to match rotation
	var bx:Vector3 = transform.basis.x * Vector3(1, 0, 1)
	var bz:Vector3 = transform.basis.z * Vector3(1, 0, 1)
	
	#create movement vector and account for deadzone manually
	var h:Vector3 = (xz.x * bx.normalized() + xz.y * bz.normalized())
	var v:Vector3 = Vector3(0, y, 0) + h
	if v.length() < dead_zone[0]: v = Vector3.ZERO
	else: v *= speed / (1 + 4 * Input.get_action_raw_strength("ctrl"))
	#apply movement to target motion
	target_motion["v"] = v
	
	#clicking on pieces
	var click:bool = Input.is_action_just_pressed("ck_0")
	if click:
		request_square(uv_query.get_mouse_position())
	
	#controller look
	var azimuth:float = Input.get_axis("lk_left","lk_right")
	var zenith:float = Input.get_axis("lk_up","lk_down")
	var r:Vector2 = Vector2(azimuth, zenith)
	if r.length() < dead_zone[1]: r = Vector2.ZERO
	else: 
		#use r to move the mouse within the screen to select a piece
		var mpos:Vector2 = uv_query.get_mouse_position()
		var ck1:float = Input.get_action_raw_strength("ck_1")
		if ck1 == 0: uv_query.warp_mouse(mpos + r / uv_query.size * stick_sens * 50)
		
		#if r is not going to be zero, multiply r by the stick sensitivity and the state of the look button (0 or 1)
		#this makes r not zero if and only if both the right stick is moving and the look button is being held
		r *= ck1 * stick_sens
	target_motion["r"] = r
	
#make momentum move towards target motion
func accelerate(var delta:float):
	for tm in momentum.keys():
		var d = target_motion[tm] - momentum[tm]
		momentum[tm] += d * accel * delta

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
		
#try to select a square on the board given a position on the screen
func request_square(var position:Vector2):
	
	#create raycast data
	var r = BoardConverter.raycast(position, camera, 
		get_world(), vision)
	
	#if ray hits something
	if r != null && !r.empty():
		#check if collider is a piece, if so return piece position
		var square:Vector2
		if r["collider"] is PieceMesh:
			square = r["collider"].piece.get_pos()
		#otherwise, return uv square of board
		else:
			var uv = uv_query.query(position)
			#print(uv)
			square = BoardConverter.uv_to_square(board_mesh.size, uv)

		#handle square selection
		team = board_mesh.handle(square, team)
		return square
	return null
