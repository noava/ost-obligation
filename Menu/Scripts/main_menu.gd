extends Node3D

@onready var player: CharacterBody3D = $Player
var last_mouse_position := Vector2.ZERO
var is_dragging := false
var auto_rotate := true
var rotation_sensitivity := 0.03
var auto_rotate_speed := 15.0
var rotation_velocity := 0.0
var decay_speed := 0.02
var stop_at := 0.003

func _ready() -> void:
	State.menu_scene = name
	player.make_playable(false)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if event.pressed:
				last_mouse_position = event.position
				auto_rotate = false
				rotation_velocity = 0.0
	
	if event is InputEventMouseMotion and is_dragging:
		var delta_x = event.position.x - last_mouse_position.x
		rotation_velocity = delta_x * rotation_sensitivity
		last_mouse_position = event.position


func _process(delta: float) -> void:
	if not player.stationary:
		return

	if is_dragging:
		player.rotate_y(rotation_velocity)

	# slowly decay the speed until auto rotate
	elif not auto_rotate:
		rotation_velocity *= (1 - decay_speed)
		player.rotate_y(rotation_velocity)
	
		if abs(rotation_velocity) < stop_at:
			auto_rotate = true

	else:
		player.rotate_y(deg_to_rad(auto_rotate_speed*delta))

