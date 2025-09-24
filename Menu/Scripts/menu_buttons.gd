extends Control

@onready var buttons: Control = $"."
@onready var main_menu: Node3D = $".."

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://World/testing.tscn")

func _on_multiplayer_pressed() -> void:
	print("pressed multiplayer")
	var lobby = preload("uid://ba6m63vr3xhqn")
	var scene = lobby.instantiate()
	main_menu.add_child(scene)
	buttons.hide()

func _on_exit_pressed() -> void:
	get_tree().quit()
