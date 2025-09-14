extends Node3D

@export var target_node: Node3D
@export var mouse_sensitivity = 0.1

@export_subgroup("SpringArm")
@onready var spring_arm = $SpringArm3D
@export var zoom_speed: float = 1.0
@export var min_length: float = 1.0
@export var max_length: float = 10.0
var target_length: float = 3.0

var mouse_lock = false

func _ready():
	spring_arm.spring_length = target_length
	
func _process(delta):
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_length, delta * 5)

func _physics_process(_delta):
	if target_node != null:
		global_position = lerp(global_position, target_node.global_position,0.5)

func _input(event):
	# lock mouse
	if Input.is_action_just_pressed("exit_camera"):
		mouse_lock = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		mouse_lock = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# rotate camera
	if event is InputEventMouseMotion and mouse_lock:
		rotation_degrees.y -= mouse_sensitivity*event.relative.x
		rotation_degrees.x -= mouse_sensitivity*event.relative.y
		rotation_degrees.x = clamp(rotation_degrees.x,-89,89)
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_length = clamp(target_length - zoom_speed, min_length, max_length)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_length = clamp(target_length + zoom_speed, min_length, max_length)
