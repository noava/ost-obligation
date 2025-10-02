extends Area3D

@export var bounce_force: float = 10.0
@export var bounce_sound: AudioStream
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@export var is_carryable: bool = true
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _ready():
	body_entered.connect(bounce_player)

func bounce_player(player_body: Node3D):
	if player_body.name.to_lower().contains("player"):
		if player_body.has_method("set_velocity"): # and not player_body.is_on_floor():
			player_body.velocity.y = bounce_force
	
  # Sound 
  # TODO: Create sound for items
	if bounce_sound and audio_player:
		audio_player.stream = bounce_sound
		audio_player.play()
	
func get_carryable_node():
	if is_carryable:
		return self
	else:
		return null

func grab_item(is_grabbed: bool):
	if collision_shape_3d:
		collision_shape_3d.disabled = is_grabbed
