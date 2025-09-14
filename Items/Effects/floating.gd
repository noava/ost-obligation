extends Node3D

@export var float_amplitude: float = 0.25
@export var float_speed: float = 2.0
@export var rotation_speed: float = 45.0

var base_height: float

func _ready():
	base_height = global_transform.origin.y

func _process(delta: float):
	var offset = sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_amplitude
	var pos = global_transform.origin
	pos.y = base_height + offset
	global_transform.origin = pos

	rotate_y(deg_to_rad(rotation_speed * delta))
