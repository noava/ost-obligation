extends Control

@onready var buttons: Control = $"."
@onready var main_menu: Node3D = $".."

func _on_start_pressed() -> void:
	State.single_player = true
	get_tree().change_scene_to_file(State.game_scene.resource_path)

func _on_multiplayer_pressed() -> void:
	if !State.steam_initialized:
		print("Steam is not initialized, cannot do multiplayer")
		return

	State.single_player = false
	var lobby = preload("uid://ba6m63vr3xhqn")
	var scene = lobby.instantiate()
	main_menu.add_child(scene)
	buttons.hide()

func _on_exit_pressed() -> void:
	get_tree().quit()
