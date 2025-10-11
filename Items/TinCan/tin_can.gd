@tool #For showing updated textures in the 3D view
extends Node3D

@export var image: Texture2D
@onready var tin_can: MeshInstance3D = $tin_can
@export var is_carryable: bool = true
@onready var item_scene: PackedScene = preload("res://Items/TinCan/tin_can.tscn")
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var pickup_sounds: Array[AudioStream] = [
	preload("res://Items/TinCan/Sounds/pickup_1.ogg"),
	preload("res://Items/TinCan/Sounds/pickup_2.ogg")
]
@onready var place_sounds: Array[AudioStream] = [
	preload("res://Items/TinCan/Sounds/place_1.ogg"),
	preload("res://Items/TinCan/Sounds/place_2.ogg")
]

func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	if image:
		tin_can.mesh = tin_can.mesh.duplicate()
		
		var material = tin_can.mesh.surface_get_material(1)
		if material:
			var unique_material = material.duplicate()
			unique_material.albedo_texture = image
			tin_can.mesh.surface_set_material(1, unique_material)

func get_carryable_node():
	if is_carryable:
		return self
	else:
		return null

func grab_item(is_grabbed: bool):
	if collision_shape_3d:
		collision_shape_3d.disabled = is_grabbed
	
	if is_grabbed:
		self.gravity_scale = 0
		self.freeze = true
		self.linear_velocity = Vector3.ZERO
		self.angular_velocity = Vector3.ZERO

		if pickup_sounds.size() > 0 and audio_player:
			var random_sound = pickup_sounds[randi() % pickup_sounds.size()]
			audio_player.stream = random_sound
			audio_player.play()
	else:
		self.gravity_scale = 1
		self.freeze = false

		if place_sounds.size() > 0 and audio_player:
			var random_sound = place_sounds[randi() % place_sounds.size()]
			audio_player.stream = random_sound
			audio_player.play()
