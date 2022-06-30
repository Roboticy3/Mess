extends KinematicBody
class_name Player

#Player class created by Pablo Ibarz
#created January 2022

#store a reference to the board in the scene
export (Resource) var board
#store reference to BoardMesh object in the physical board
export (Mesh) var board_mesh

#the team with which the player can interact with
export (int) var team = 0

#distance a player can click to
export (int) var vision = 2000000

#Camera child of the Player
export (NodePath) var camera_path:NodePath
var camera:Camera

#Viewport the Player can use to sample uv coordinates from the board
export (NodePath) var viewport_path:NodePath
var uv_query:UvQuerier

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
export (PoolRealArray) var dead_zone = [0.1, 0.1]

#last click the player made in uv_space
export (Vector2) var uv_last = Vector2.ZERO

#whether or not the camera is rotating
var looking:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#use NodePaths to find nodes
	camera = get_node(camera_path)
	uv_query = get_node(viewport_path) as UvQuerier
	
func set_mesh(var mesh:Mesh) -> void:
	uv_query.set_mesh(mesh)
	

#run movement functions on physics timestep
func _physics_process(delta):
	#apply movement based on target motion
	move(delta)
	look(delta)
	accelerate(delta)

#handle non-button inputs with Events
func _input(event):
	#if the mouse is moving and the camera rotate button is being held, rotate the camera
	if event is InputEventMouseMotion && Input.is_action_pressed("ck_1"):
		var e:InputEventMouseMotion = event
		target_motion["r"] = e.speed

#handle button inputs each frame
func _process(delta):
	#movement buttons
	var z:float = Input.get_action_raw_strength("mv_back") - Input.get_action_raw_strength("mv_forward")
	var x:float = Input.get_action_raw_strength("mv_right") - Input.get_action_raw_strength("mv_left")
	var y:float = Input.get_action_raw_strength("mv_up") - Input.get_action_raw_strength("mv_down")
	var v:Vector3 = Vector3(x, y, z)
	if v.length() < dead_zone[0]: v = Vector3.ZERO
	else: v *= speed
	target_motion["v"] = v
	
	#controller look
	var azimuth:float = Input.get_action_raw_strength("lk_right") - Input.get_action_strength("lk_left")
	var zenith:float = Input.get_action_strength("lk_down") - Input.get_action_raw_strength("lk_up")
	var r:Vector2 = Vector2(azimuth, zenith)
	if r.length() < dead_zone[1]: r = Vector2.ZERO
	else: r *= Input.get_action_raw_strength("ck_1") * 500
	target_motion["r"] = r
	
#apply acceleration so momentum approaches target_motion
func accelerate(var delta:float):
	for tm in momentum.keys():
		var d = target_motion[tm] - momentum[tm]
		momentum[tm] += d * accel * delta

func look(delta):
	#multiply rotation motions by delta and sens
	var axes = transform.basis
	var rots = target_motion["r"] * delta * -sens/100
	print(rots)
	
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
	
func move(var delta:float) -> void:
	move_and_collide(momentum["v"] * delta)
		
#try to select a uv from the board
func request_square(var event:InputEventMouseButton):
	
	#create raycast data
	var r = BoardConverter.raycast(event.position, camera, 
		get_world(), vision)
	
	#if ray hits something
	if r != null && !r.empty():
		#REWORK check if collider is a piece, if so return piece position
		var square:Vector2
		if r["collider"] is KinematicBody:
			square = r["collider"].piece.get_pos()
		#otherwise, return uv square of board
		else:
			var uv = uv_query.query(event.position)
			square = BoardConverter.uv_to_square(board_mesh.size, uv)

		#handle square selection
		team = board_mesh.handle(square, team)
		return square
	return null
