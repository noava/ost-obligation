extends Area3D

@export var bounce_force: float = 10.0
@onready var bounce_sound: AudioStream = preload("res://Items/Mushroom/bounce.wav")
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@export var is_carryable: bool = true
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var pickup_sounds: Array[AudioStream] = [
	preload("res://Items/TinCan/Sounds/pickup_1.ogg"),
	preload("res://Items/TinCan/Sounds/pickup_2.ogg")
]
@onready var place_sounds: Array[AudioStream] = [
	preload("res://Items/TinCan/Sounds/place_1.ogg"),
	preload("res://Items/TinCan/Sounds/place_2.ogg")
]

func _ready():
	body_entered.connect(bounce_player)

func bounce_player(player_body: Node3D):
	if player_body.is_in_group("player"):
		if player_body.has_method("set_velocity"): # and not player_body.is_on_floor():
			player_body.velocity.y = bounce_force
	
		# Sound 
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

	if is_grabbed:
		if pickup_sounds.size() > 0 and audio_player:
			var random_sound = pickup_sounds[randi() % pickup_sounds.size()]
			audio_player.stream = random_sound
			audio_player.play()
	
	else:
		if place_sounds.size() > 0 and audio_player:
			var random_sound = place_sounds[randi() % place_sounds.size()]
			audio_player.stream = random_sound
			audio_player.play()
