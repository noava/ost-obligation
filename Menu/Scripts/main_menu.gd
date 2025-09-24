extends Node3D
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	State.menu_scene = name
	player.make_playable(false)
