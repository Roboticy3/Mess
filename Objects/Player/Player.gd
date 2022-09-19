extends KinematicBody
class_name Player

#Player class created by Pablo Ibarz
#created January 2022

###BOARD REFERENCES

#store a reference to the board in the scene
var board:Board
#store reference to BoardMesh object in the physical board
var board_mesh:BoardMesh

#the team with which the player can interact with
export (int) var team = 0

###CAMERA PROPERTIES

#distance a player can click to
export (int) var vision = 2000000

#Camera child of the Player
export (NodePath) var camera_path := NodePath("Player Camera")
var camera:Camera

#Viewport the Player can use to sample uv coordinates from the board
export (NodePath) var viewport_path := NodePath("Viewport")
var uv_query:Node

###MOVEMENT DATA

#keep track of the player's target_motion and camera rotation
#this way the global input map doesn't have to be used
var target_motion:Dictionary = {"v":Vector3.ZERO, "r":Vector2.ZERO, "zoom":0,
	"b":Vector2.ZERO}
#momentum chases target_motion to smooth movement
var momentum:Dictionary = {"v":Vector3.ZERO, "zoom":0,
	"b":Vector2.ZERO}

#last click the player made in uv_space
export (Vector2) var uv_last = Vector2.ZERO

###SENSITIVITY AND SPEED

#the acceleration of momentum in u/s/s
export (float) var accel = 50.0

#speed of the player in u/s
export (float) var speed = 4.0

#sensitivity of the player in rad/100pix
export (float) var sens = 0.1

#dead zone on the controller axes
#index 0 for left stick and 1 for right
export (PoolRealArray) var dead_zone = [0.05, 0.05]
#controller look sensitivity
export (int) var stick_sens = 500

###BUTTONS

#lock the camera
export (String) var cam_lock := "ctrl"
export (bool) var inverted_cam_lock := false;

#rotate the board and slow movement
export (String) var rotate_board := "ck_1"
export (String) var precision := "ctrl"

#esc key
export (String) var esc := "ui_cancel"

###UI REFERENCES
export (NodePath) var menu_path := NodePath("../Menu")
onready var menu := get_node(menu_path)

export (NodePath) var ui_path := NodePath("../UI")
onready var ui := get_node(ui_path)

export (NodePath) var reticle_path := NodePath("../UI/Reticle")
onready var reticle := get_node(ui_path)

export (NodePath) var gameover_path := NodePath("../GameOver")
onready var gameover := get_node(gameover_path)

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
	if event is InputEventMouseMotion:
		var ck1 := Input.get_action_raw_strength(rotate_board)
		var ctrl := Input.get_action_raw_strength(cam_lock)
		if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
			target_motion["r"] = event.relative
		
		if ck1 != 0:
			target_motion["b"] = event.speed
			
		
	#if the board_mesh has not been activated yet, do so on the first keystroke
	if !board_mesh.awake && event is InputEventKey:
		board_mesh.begin(board_mesh.path)

#handle button inputs each frame
func _process(_delta):
	
	#camera buttons
	var ctrl:float = Input.get_action_raw_strength(cam_lock)
	var ck1:float = Input.get_action_raw_strength(rotate_board)
	
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
	else: v *= speed / (1 + 4 * Input.get_action_raw_strength(precision))
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
		if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED): 
			uv_query.warp_mouse(mpos + Vector2(azimuth, zenith) * stick_sens / 100)
		
		#if r is not going to be zero, multiply r by the stick sensitivity and the state of the look button (0 or 1)
		#this makes r not zero if and only if both the right stick is moving and the look button is being held
		r *= ctrl * ck1 * stick_sens
	target_motion["r"] = r
	
	#lock or unlock the mouse according to keypresses or visibility
	if (ctrl != 0 || ck1 != 0) || menu.visible || gameover.visible: 
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	#reset the target motion and transform of board_mesh according to changes in ck1
	if ck1 == 0:
		target_motion["b"] = Vector2.ZERO
		if ctrl == 0:
			board_mesh.transform = board_mesh.transform.interpolate_with(Transform(), 0.5)
	
#make momentum move towards target motion
func accelerate(var delta:float):
	for tm in momentum.keys():
		var d = target_motion[tm] - momentum[tm]
		momentum[tm] += d * accel * delta

func look(delta):
	#multiply rotation motions by delta and sens
	var axes = transform.basis
	var rots = target_motion["r"] * delta * -sens
	
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
	
	#rotate the board by its target rotations
	rots = momentum["b"] * delta * sens / 100
	board_mesh.global_rotate(Vector3.UP, rots.x)
	board_mesh.global_rotate(transform.basis.x, rots.y)
	

#rotated around an axis around the origin
func rotate(var axis:Vector3 = Vector3.UP, var phi:float = 0, var origin:Vector3 = Vector3.ZERO):
	var o = transform.origin
	var t = transform
	t.origin = origin
	t = t.rotated(axis.normalized(), phi)
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
