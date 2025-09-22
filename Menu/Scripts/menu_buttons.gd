extends VBoxContainer


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://World/testing.tscn")


func _on_multiplayer_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()
