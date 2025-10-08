extends Control

class_name DialogueUI

@onready var dialogue_panel = $DialoguePanel
@onready var character_name_label = $DialoguePanel/VBox/NameLabel
@onready var dialogue_text_label = $DialoguePanel/VBox/DialogueText
@onready var choices_container = $DialoguePanel/VBox/ChoicesContainer
@onready var continue_button = $DialoguePanel/VBox/ContinueButton

var typewriter_speed = 0.05
var is_typing = false
var full_text = ""
var current_text = ""
var typewriter_timer = 0.0
var is_updating_display = false
var was_skipped_by_user = false

func _ready():
	add_to_group("dialogue_ui")
	visible = false
	
	# Connect signals
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if dialogue_manager:
		dialogue_manager.connect("dialogue_started", _on_dialogue_started)
		dialogue_manager.connect("dialogue_ended", _on_dialogue_ended)
		dialogue_manager.connect("dialogue_updated", _on_dialogue_updated)
	
	# Connect continue button
	if continue_button:
		continue_button.connect("pressed", _on_continue_pressed)

func _process(delta):
	if is_typing:
		update_typewriter(delta)

func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("e"):
		if is_typing:
			was_skipped_by_user = true
			complete_typewriter()
		else:
			var focused_button = get_viewport().gui_get_focus_owner()
			if focused_button and focused_button.get_parent() == choices_container:
				return
			else:
				advance_or_select()
	elif event.is_action_pressed("ui_cancel"):
		var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
		if dialogue_manager and dialogue_manager.current_npc:
			was_skipped_by_user = true
			var current_npc = dialogue_manager.current_npc
			if current_npc.has_method("stop_voice_audio"):
				current_npc.stop_voice_audio()
		if dialogue_manager:
			dialogue_manager.end_dialogue()



func show_dialogue():
	visible = true


func hide_dialogue():
	visible = false
	clear_choices()

func update_dialogue_display():
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if not dialogue_manager:
		return
		
	var dialogue_text = dialogue_manager.get_current_dialogue_text()
	var current_npc = dialogue_manager.current_npc
	
	
	if current_npc:
		character_name_label.text = current_npc.npc_name
	
	start_typewriter(dialogue_text)
	await update_choices()

func update_choices():
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if not dialogue_manager:
		return
		
	var choices = dialogue_manager.get_dialogue_choices()
	if choices.size() > 0:
		await show_choices(choices)
	else:
		await clear_choices()



func start_typewriter(text: String):
	full_text = text
	current_text = ""
	is_typing = true
	typewriter_timer = 0.0
	dialogue_text_label.text = ""
	was_skipped_by_user = false
	
	if text == "":
		complete_typewriter()
		return
	
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if dialogue_manager:
		var current_npc = dialogue_manager.current_npc
		if current_npc and current_npc.use_recorded_voice_lines:
			# Small delay to ensure dialogue index is properly set
			await get_tree().process_frame
			current_npc.play_dialogue_voice("", {})

func update_typewriter(delta):
	if not is_typing:
		return
		
	typewriter_timer += delta
	if typewriter_timer >= typewriter_speed:
		typewriter_timer = 0.0
		
		if current_text.length() < full_text.length():
			current_text += full_text[current_text.length()]
			dialogue_text_label.text = current_text
		else:
			complete_typewriter()

func complete_typewriter():
	is_typing = false
	current_text = full_text
	dialogue_text_label.text = current_text
	
	if was_skipped_by_user:
		var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
		if dialogue_manager and dialogue_manager.current_npc:
			var current_npc = dialogue_manager.current_npc
			if current_npc.has_method("stop_voice_audio"):
				current_npc.stop_voice_audio()
		was_skipped_by_user = false
	else:
		print("")
	
	show_continue_options()
	
	await get_tree().process_frame
	if choices_container.get_child_count() > 0:
		var first_choice = choices_container.get_child(0)
		if first_choice is Button:
			first_choice.grab_focus()

func show_continue_options():
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if not dialogue_manager:
		return
		
	var choices = dialogue_manager.get_dialogue_choices()
	if choices.size() > 0:
		continue_button.visible = false
	else:
		continue_button.visible = true

func show_choices(choices: Array):
	await clear_choices()
	
	for i in range(choices.size()):
		var choice = choices[i]
		var button = Button.new()
		button.text = choice["text"]
		button.custom_minimum_size = Vector2(200, 40)
		
		var callable = _on_choice_selected.bind(i)
		button.connect("pressed", callable)
		choices_container.add_child(button)
		
		if i == 0:
			button.grab_focus()
	

func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()
	await get_tree().process_frame

func advance_or_select():
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if not dialogue_manager:
		return
		
	if dialogue_manager.get_dialogue_choices().size() > 0:
		return
	
	if not dialogue_manager.advance_dialogue():
		return
	
	update_dialogue_display()

func _on_continue_pressed():
	advance_or_select()

func _on_choice_selected(choice_index: int):
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if dialogue_manager:
		dialogue_manager.select_choice(choice_index)

func _on_dialogue_started():
	if not visible:
		show_dialogue()
	await update_dialogue_display()

func _on_dialogue_ended():
	if visible:
		hide_dialogue()

func _on_dialogue_updated():
	await update_dialogue_display()
