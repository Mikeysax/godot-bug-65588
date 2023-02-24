extends Node3D

var _camera_controller: Node3D
var _spring_arm: SpringArm3D
var _camera: Camera3D
var _camera_controller_target: Node3D

const LOOK_LEFT: String = "look_left"
const LOOK_RIGHT: String = "look_right"
const LOOK_UP: String = "look_up"
const LOOK_DOWN: String = "look_down"

@export var camera_controller_target_path: NodePath
@export var max_x_rotation: float = 75
@export var min_x_rotation: float = -55
@export var spring_arm_max_zoom: float = 4
@export var spring_arm_min_zoom: float = 0.1
@export var camera_z_distance_from_spring_arm: float = -5
@export var vertical_sensitivity: float = 0.002
@export var horizontal_sensitivity: float = 0.002
@export var joypad_vertical_sensitivity: float = 0.03
@export var joypad_horizontal_sensitivity: float = 0.03
@export var camera_controller_horizontal_offset: float = 0.0
@export var camera_controller_vertical_offset: float = 1.8
@export var camera_controller_lerp_speed: float = 5.0
@export var camera_size: int = 4
@export var camera_fov: float = 44.0
@export var camera_near: float = 0.05
@export var camera_far: int = 4000
@export var camera_controller_rotation_x: float = -30.0 / 100.0
@export var camera_controller_rotation_y: float = 360.0 / 100.0

@onready var current_zoom: float = spring_arm_max_zoom

var joypad_view_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_physics_process(true)
	set_as_top_level(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_nodes()
	setup_spring_arm()
	setup_camera()

func get_nodes() -> void:
	_camera_controller_target = get_node(camera_controller_target_path)
	_camera_controller = get_node(".")
	_spring_arm = get_node("SpringArm")
	_camera = get_node("SpringArm/Camera")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_camera_controller_rotation_with_mouse(event)
	update_joypad_view_direction()

func _process(_delta: float) -> void:
	update_camera_controller_rotation_with_joypad()

func _physics_process(delta: float) -> void:
	update_spring_arm_zoom(delta)
	follow_camera_controller_target(delta)

func setup_spring_arm() -> void:
	var side_offset: Vector3 = Vector3(camera_controller_horizontal_offset, 0, 0)
	_spring_arm.spring_length = spring_arm_max_zoom
	_spring_arm.margin = spring_arm_min_zoom
	_spring_arm.position = side_offset

func setup_camera() -> void:
	setup_camera_distance()
	setup_camera_zoom()
	setup_camera_rotation()

func setup_camera_distance() -> void:
	_camera.position = Vector3(0, 0, camera_z_distance_from_spring_arm)

func setup_camera_zoom() -> void:
	_camera.fov = camera_fov
	_camera.size = camera_size
	_camera.near = camera_near
	_camera.far = camera_far

func setup_camera_rotation() -> void:
	pass
	
func update_camera_controller_rotation_with_mouse(event: InputEventMouseMotion) -> void:
	update_camera_controller_rotation(event.relative, horizontal_sensitivity, vertical_sensitivity)

func update_camera_controller_rotation_with_joypad() -> void:
	if joypad_view_direction == Vector2.ZERO:
		return
	update_camera_controller_rotation(joypad_view_direction, joypad_horizontal_sensitivity, joypad_vertical_sensitivity)

func update_camera_controller_rotation(direction: Vector2, horizontal_sens: float, vertical_sens: float) -> void:
	_camera_controller.rotation.y -= direction.x * horizontal_sens
	_camera_controller.rotation.y = wrapf(_camera_controller.rotation.y, 0.0, TAU)
	# NOTE: Using + or - below on the X axis will invert the vertical camera movement. Using + when the camera is flipped
	# 180 fixes the inversion. The camera is flipped 180 so that the player and camera controller are aligned in rotation
	_camera_controller.rotation.x += direction.y * vertical_sens
	_camera_controller.rotation.x = clamp(_camera_controller.rotation.x, deg_to_rad(min_x_rotation), deg_to_rad(max_x_rotation))
	
func update_joypad_view_direction() -> void:
	joypad_view_direction = Vector2(
		Input.get_axis(LOOK_LEFT, LOOK_RIGHT), 
		Input.get_axis(LOOK_UP, LOOK_DOWN)
	)
	
func update_spring_arm_zoom(delta: float) -> void:
	_spring_arm.spring_length = lerp(
		_spring_arm.spring_length, 
		current_zoom, 
		delta * camera_controller_lerp_speed
	)

func follow_camera_controller_target(delta: float) -> void:
	var height_offset: Vector3 = Vector3(0, camera_controller_vertical_offset, 0)
	var new_target_position: Vector3 = lerp(
		_camera_controller.global_position,
		_camera_controller_target.global_position + height_offset,
		delta * camera_controller_lerp_speed
	)
	_camera_controller.position = new_target_position
