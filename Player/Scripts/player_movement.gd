extends CharacterBody3D

@export var head: Node3D
@export var player_model: Node3D
var input_direction

@export_category("Movement")
@export_subgroup("Settings")
@export var WALK_SPEED := 5.0
@export var SPRINT_SPEED := 16.0
@export var ACCELERATION := 50
@export var IN_AIR_ACCEL := 5.0
@export var JUMP_VELOCITY = 8.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed = WALK_SPEED
var acceleration = ACCELERATION

# Step up
@export var MAX_STEP_HEIGHT := 0.5
@onready var step_ray: RayCast3D = $"LilMouseGuy/rig/Skeleton3D/Torso/SteppingRay"

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	move_player(delta)
	step_up()
	move_and_slide()

func move_player(delta):
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if not is_on_floor():
		# Changes movement in air
		acceleration = IN_AIR_ACCEL
		velocity.y -= gravity * delta
	else:
		acceleration = ACCELERATION
	
	# Walk
	input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	
	if direction.length() > 0.1:
		var target_yaw = atan2(direction.x, direction.z)
		# Smooth rotation
		player_model.rotation.y = lerp_angle(player_model.rotation.y, target_yaw, delta * 5.0)
	
	# Sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

func step_up():
	if step_ray.is_colliding():
		step_ray.force_raycast_update()
		var step_height = step_ray.get_collision_point().y - global_transform.origin.y
		if step_height > 0 and step_height < MAX_STEP_HEIGHT:
			global_transform.origin.y += step_height
