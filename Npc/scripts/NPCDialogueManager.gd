extends Node

signal dialogue_started
signal dialogue_ended
signal dialogue_choice_made(choice_index, choice_text)
signal dialogue_updated

var dialogue_data = {}
var current_dialogue = {}
var current_dialogue_index = 0
var current_npc = null
var is_dialogue_active = false


func load_dialogue_from_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file != null:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var result = json.parse(json_text)
		if result == OK:
			return json.data
		else:
			return {}
	else:
		return {}

func start_dialogue(npc_reference, dialogue_data_dict: Dictionary, dialogue_id: String):
	current_npc = npc_reference
	if dialogue_id in dialogue_data_dict:
		current_dialogue = dialogue_data_dict[dialogue_id]
		current_dialogue_index = 0
		var was_already_active = is_dialogue_active
		is_dialogue_active = true
		
		if not was_already_active:
			emit_signal("dialogue_started")
		else:
			update_dialogue_ui()
		return true
	else:
		return false

func update_dialogue_ui():
	emit_signal("dialogue_updated")

func get_current_dialogue_text():
	if not is_dialogue_active or current_dialogue.is_empty():
		return ""
	
	var text_array = current_dialogue.get("text", [])
	if current_dialogue_index < text_array.size():
		return process_dialogue_variables(text_array[current_dialogue_index])
	return ""

func process_dialogue_variables(text: String) -> String:
	if current_npc and current_npc.has_method("get_player_name"):
		text = text.replace("&", current_npc.get_player_name())
	return text

func advance_dialogue():
	if not is_dialogue_active:
		return false
		
	current_dialogue_index += 1
	var text_array = current_dialogue.get("text", [])
	
	if current_dialogue_index >= text_array.size():
		handle_dialogue_completion()
		return false
	return true

func handle_dialogue_completion():
	if "action" in current_dialogue:
		execute_actions(current_dialogue["action"])
	
	if "next" in current_dialogue:
		handle_next_dialogue()
	else:
		end_dialogue()

func handle_next_dialogue():
	var next_data = current_dialogue["next"]
	var next_id = ""
	
	if typeof(next_data) == TYPE_STRING:
		next_id = next_data
	elif typeof(next_data) == TYPE_ARRAY:
		for condition in next_data:
			if typeof(condition) == TYPE_DICTIONARY:
				if "if" in condition and check_condition(condition["if"]):
					next_id = condition["id"]
					break
			else:
				next_id = condition
				break
	
	if next_id != "":
		start_dialogue(current_npc, current_npc.dialogue_data, next_id)
	else:
		end_dialogue()

func get_dialogue_choices():
	if not is_dialogue_active:
		return []
	
	var choices = current_dialogue.get("choices", [])
	var available_choices = []
	
	for choice in choices:
		if "show_only_if" in choice:
			if not check_condition(choice["show_only_if"]):
				continue
		available_choices.append(choice)
	
	return available_choices

func select_choice(choice_index: int):
	var choices = get_dialogue_choices()
	
	if choice_index >= 0 and choice_index < choices.size():
		var choice = choices[choice_index]
		
		if "action" in choice:
			execute_actions(choice["action"])
		
		if "next" in choice:
			start_dialogue(current_npc, current_npc.dialogue_data, choice["next"])
		else:
			end_dialogue()
		
		emit_signal("dialogue_choice_made", choice_index, choice["text"])
	else:
		print("Invalid choice index: ", choice_index, " (available: ", choices.size(), ")")

func check_condition(condition: String) -> bool:
	if current_npc and current_npc.has_method("check_dialogue_condition"):
		return current_npc.check_dialogue_condition(condition)
	return false

func execute_actions(actions: Array):
	for action in actions:
		if current_npc and current_npc.has_method("execute_dialogue_action"):
			current_npc.execute_dialogue_action(action)

func end_dialogue():
	is_dialogue_active = false
	current_dialogue = {}
	current_dialogue_index = 0
	current_npc = null
	emit_signal("dialogue_ended")
