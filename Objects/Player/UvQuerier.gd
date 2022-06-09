class_name UvQuerier
extends Viewport

# Script created on 6/9/2022 by Pablo Ibarz
# can convert a position on the screen to a uv coordinate in a set of CSGMesh objects

# Attach this script to a Viewport that has a Camera child and at least 1 CSGMesh child, 
# then assign the children to camera_path and csg_paths, 
# and the Camera whose screen positions are being queried to target_path

# This script will only work properly if all assigned CSGMesh children have the UVs.tres material applied to them
export (NodePath) var camera_path:NodePath
var camera:Camera
export (NodePath) var target_path:NodePath
var target:Camera
export (Array, NodePath) var csg_paths:Array
var csg:Array

export (ViewportTexture) var texture:ViewportTexture

func _ready() -> void:
	camera = get_node(camera_path)
	target = get_node(target_path)
	csg = Array()
	for csg_path in csg_paths: csg.append(get_node(csg_path))

#returns the uv position on the closest CSGMesh to the camera at the input screen_position
#if no uv position is found, it returns Vector2(NaN, NaN)
func query(var screen_position:Vector2) -> Vector2:
	
	var image:Image = texture.get_data()
	image.lock()
	
	var color:Color = image.get_pixelv(screen_position)
	#UVs.tres encodes the uv coordinates on a CSGMesh into the red and green channels
	if color.a != 0.0: 
		var uv:Vector2 = Vector2(color.r, color.g)
		return sRGBxy_to_linear(uv)
	
	return Vector2(NAN, NAN)

#convert UV in shader from sRGB to linear
func sRGBxy_to_linear(var uv:Vector2):
	var x := sRGBx_to_linear(uv.x)
	var y := sRGBx_to_linear(uv.y)
	return Vector2(x, y)

#convert an sRGB value to its linear equivalent
#https://entropymine.com/imageworsener/srgbformula/
func sRGBx_to_linear(var x:float) -> float:
	if x > 1.0: return 1.0
	
	if x <= 0.04045: return x / 12.92
	else: return pow((x + 0.055)/1.055, 2.4)
	
	return 0.0
	
#match this Viewport's Camera's settings to the main camera's
func _process(var delta:float) -> void:
	camera.global_transform = target.global_transform
	camera.h_offset = target.h_offset
	camera.v_offset = target.v_offset
	camera.frustum_offset = target.frustum_offset
	camera.fov = target.fov
	camera.keep_aspect = target.keep_aspect
	camera.near = target.near
	camera.far = target.far
	camera.size = target.size
	
	size = get_tree().root.get_viewport().size
