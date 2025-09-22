extends Node3D
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	player.make_playable(false)
