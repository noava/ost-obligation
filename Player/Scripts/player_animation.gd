extends Node

@export var player_movement: CharacterBody3D
@export var player_holditem: Node3D

const max_step_height = 0.5

# Animations
@onready var anim_tree: AnimationTree = $"../LilMouseGuy/AnimationTree"
enum {IDLE, WALK, RUN, JUMP, HOLD, CROUCH, DEAD}
@export var curAnim: int = IDLE
@export var blend_speed = 15
var walk_val = 0
var jump_val = 0
var hold_val = 0
var crouch_val = 0
	
func _physics_process(delta: float) -> void:
	handle_animations(delta)
	update_animation_states()

func handle_animations(delta):
	match curAnim:
		IDLE:
			walk_val = lerpf(walk_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)
		WALK:
			walk_val = lerpf(walk_val, 1, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)
		RUN:
			walk_val = lerpf(clamp(walk_val * 2.0, 0.0, 1.2), 1.0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 0, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)
		HOLD:
			walk_val = lerpf(walk_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
			hold_val = lerpf(hold_val, 1, blend_speed * delta)
			crouch_val = lerpf(crouch_val, 0, blend_speed * delta)

	update_tree()

func update_tree():
	anim_tree["parameters/Walk/blend_amount"] = walk_val
	anim_tree["parameters/Hold/blend_amount"] = hold_val

func update_animation_states():
	if player_movement.is_on_floor():
		if player_movement.input_direction.length() > 0.1:
			if player_movement.speed == player_movement.WALK_SPEED:
				curAnim = WALK
			elif player_movement.speed == player_movement.SPRINT_SPEED:
				curAnim = RUN
		elif player_holditem.is_holding:
			curAnim = HOLD
		else:
			curAnim = IDLE
	else:
		curAnim = JUMP
