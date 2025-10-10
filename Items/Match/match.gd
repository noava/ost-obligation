extends Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var match_lit: bool = false
@export var hit_force_strength = 10.0

func _ready() -> void:
	$Flame.visible = false
	$OmniLight3D.visible = false

func primary_activation():
	if animation_player:
		animation_player.play("hit")

	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var raycast = player.get_node_or_null("CameraPivot/HeadRayCast")
	if not raycast or not raycast.is_colliding(): return
	
	var collider = raycast.get_collider()
	
	if collider is RigidBody3D:
		var hit_pos = raycast.get_collision_point()
		
		var hit_direction = (hit_pos - raycast.global_position).normalized()
		
		collider.apply_impulse(hit_direction * hit_force_strength, hit_pos - collider.global_position)

func secondary_activation():
	match_lit = !match_lit

	$Flame.visible = match_lit
	$OmniLight3D.visible = match_lit