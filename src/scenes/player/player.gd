extends CharacterBody3D

@export var _camera_path: NodePath

var _root_node: CharacterBody3D
var _camera_root: Node3D
var _camera: Camera3D
var _camera_basis: Basis
var _player: Node3D
var _skeleton: Skeleton3D
var _body_collision: CollisionShape3D
var _animation_player: AnimationPlayer

const X_AXIS: String = "x"
const Y_AXIS: String = "y"
const LEFT: String = "left"
const RIGHT: String = "right"
const UP: String = "up"
const DOWN: String = "down"
const SPRINT: String = "sprint"
const RUN: String = "run"
const WALK: String = "walk"
const IDLE: String = "idle"
const JUMP: String = "jump"
const ASCENDING: String = "ascending"
const DESCENDING: String = "descending"
const ACCELERATING: String = "accelerating"
const DECELERATING: String = "decelerating"

var input_direction: Vector2 = Vector2.ZERO
var move_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	_root_node = get_node('.')
	_camera_root = get_node(_camera_path)
	_camera = _camera_root.get_node('SpringArm/Camera')
	_player = get_node("player")
	_skeleton = %Skeleton3D
	_body_collision = get_node("BodyCollision")
	_animation_player = get_node("AnimationPlayer")
	_animation_player.play("Player/Run")

func _input(event: InputEvent) -> void:
	input_direction = Vector2(
		Input.get_axis(LEFT, RIGHT),
		Input.get_axis(UP, DOWN)
	)

func _physics_process(delta: float) -> void:
	_camera_basis = _camera.get_global_transform().basis
	
	move_direction = Vector3.ZERO
	move_direction += _camera_basis.z * input_direction.y
	move_direction += _camera_basis.x * input_direction.x
	move_direction.y = 0
	move_direction = move_direction.normalized()
	
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0, velocity.z)
	var target_horizontal_distance: Vector3 = move_direction * 10.0
	horizontal_velocity = horizontal_velocity.lerp(target_horizontal_distance, 10.0 * delta)
	
	if move_direction.length() == 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
		
	velocity.y += -14.0 * delta
	
	var current_rotation_target: float = atan2(move_direction.x, move_direction.z)
	var previous_rotation: float = _player.rotation.y
	_player.rotation.y = lerp_angle(
		previous_rotation, 
		current_rotation_target,
		delta * 7.0
	)

	
	if Input.is_action_just_pressed("jump"):
		velocity.y += 7.0
	
	move_and_slide()
