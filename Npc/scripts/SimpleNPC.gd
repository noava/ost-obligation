extends CharacterBody3D

class_name SimpleNPC

@export var npc_name: String = "NPC"
@export var dialogue_id: String = ""
@export var interaction_distance: float = 3.0
@export var auto_face_player: bool = true
@export var can_interact: bool = true

@export var dialogue_json_file: Resource
@export var voice_lines: Array[AudioStream] = []
@export var use_recorded_voice_lines: bool = true

@export var include_random_voice_lines: bool = false
@export var random_voice_lines: Array[AudioStream] = []
@export var random_voice_cooldown: float = 5.0
@export var random_voice_chance: float = 0.9

@export var typewriter_sound: AudioStream
@export var voice_pitch: float = 1.0
@export var voice_volume: float = 0.0
@export var typewriter_rate: int = 4

@export var movement_type: String = "static" # static, patrol, wander
@export var patrol_points: Array = []
@export var patrol_speed: float = 2.0
@export var idle_time_at_points: float = 2.0
@export var wander_radius: float = 5.0

@export var show_name_label: bool = true
@export var name_display_offset: Vector3 = Vector3(0, 2, 0)
@export var interact_prompt_text: String = "Press E to talk"
@export var show_interaction_prompt: bool = true

@export var greeting_animation: String = "wave"
@export var idle_animation: String = "idle"
@export var walking_animation: String = "walk"

var dialogue_data: Dictionary = {}
var player_reference = null
var dialogue_ui = null
var interact_area: Area3D
var name_label: Label3D
var voice_audio_player: AudioStreamPlayer3D
var random_voice_audio_player: AudioStreamPlayer3D
var typewriter_audio_player: AudioStreamPlayer3D
var animation_player: AnimationPlayer
var interaction_prompt: Node3D

var is_in_dialogue: bool = false
var current_patrol_index: int = 0
var movement_timer: float = 0.0
var is_moving: bool = false
var has_been_interacted_with: bool = false
var last_interaction_time: float = 0.0
var original_position: Vector3
var player_in_range: bool = false
var last_random_voice_time: float = 0.0
var is_playing_random_voice: bool = false

func _ready():
	original_position = global_transform.origin
	load_dialogue_data()
	setup_npc()
	connect_signals()
	add_to_group("npcs")

# TODO: Fix If statement here!!!
func _input(event):
	if event.is_action_pressed("e") and player_in_range and can_interact and not is_in_dialogue:
		interact()
	elif event.is_action_pressed("ui_cancel") and is_in_dialogue:
		stop_voice_audio()
		var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
		if dialogue_manager:
			dialogue_manager.end_dialogue()

func load_dialogue_data():
	if dialogue_json_file:
		var file_path = dialogue_json_file.resource_path
		var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
		if dialogue_manager:
			dialogue_data = dialogue_manager.load_dialogue_from_file(file_path)
		else:
			dialogue_data = load_dialogue_fallback(file_path)
		
		if dialogue_data.is_empty():
			print("⚠️ Failed to load dialogue data for ", npc_name)
		else:
			print("")
	else:
		print("⚠️ No dialogue JSON file assigned to ", npc_name)

func load_dialogue_fallback(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file != null:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var result = json.parse(json_text)
		if result == OK:
			return json.data
		else:
			print("Error parsing JSON: ", json.get_error_message())
	return {}

func setup_npc():
	interact_area = Area3D.new()
	interact_area.name = "InteractionArea"
	var collision_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = interaction_distance
	collision_shape.shape = sphere
	interact_area.add_child(collision_shape)
	add_child(interact_area)
	
	if show_name_label:
		name_label = Label3D.new()
		name_label.name = "NameLabel"
		name_label.text = npc_name
		name_label.position = name_display_offset
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label.modulate = Color(1, 1, 0.8)
		add_child(name_label)
	
	voice_audio_player = AudioStreamPlayer3D.new()
	voice_audio_player.name = "VoiceAudio"
	add_child(voice_audio_player)
	
	random_voice_audio_player = AudioStreamPlayer3D.new()
	random_voice_audio_player.name = "RandomVoiceAudio"
	add_child(random_voice_audio_player)
	
	typewriter_audio_player = AudioStreamPlayer3D.new()
	typewriter_audio_player.name = "TypewriterAudio"
	add_child(typewriter_audio_player)
	
	animation_player = get_node_or_null("AnimationPlayer")
	
	if show_interaction_prompt:
		create_interaction_prompt()
	
	call_deferred("find_references")

func find_references():
	player_reference = get_tree().get_nodes_in_group("player")[0] if get_tree().has_group("player") else null
	dialogue_ui = get_tree().get_nodes_in_group("dialogue_ui")[0] if get_tree().has_group("dialogue_ui") else null
	
	if not player_reference:
		print("⚠️ No player found in 'player' group")
	if not dialogue_ui:
		print("⚠️ No dialogue UI found in 'dialogue_ui' group")

func create_interaction_prompt():
	interaction_prompt = Node3D.new()
	interaction_prompt.name = "InteractionPrompt"
	
	var prompt_label = Label3D.new()
	prompt_label.text = interact_prompt_text
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.position = Vector3(0, 1.5, 0)
	prompt_label.modulate = Color(1, 1, 1, 0.8)
	
	interaction_prompt.add_child(prompt_label)
	add_child(interaction_prompt)
	interaction_prompt.visible = false

func connect_signals():
	if interact_area:
		interact_area.connect("body_entered", _on_interaction_area_entered)
		interact_area.connect("body_exited", _on_interaction_area_exited)
	
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if dialogue_manager:
		dialogue_manager.connect("dialogue_ended", _on_dialogue_ended)

func _physics_process(delta):
	if not is_in_dialogue:
		handle_movement(delta)
	
	if auto_face_player and player_reference and is_player_nearby():
		face_player()

func handle_movement(delta):
	match movement_type:
		"patrol":
			handle_patrol_movement(delta)
		"wander":
			handle_wander_movement(delta)
		"static":
			play_idle_animation()

func handle_patrol_movement(delta):
	if patrol_points.size() < 2:
		return
	
	var target_pos = patrol_points[current_patrol_index]
	var distance_to_target = global_transform.origin.distance_to(target_pos)
	
	if distance_to_target < 0.5:
		if not is_moving:
			play_idle_animation()
			movement_timer += delta
			if movement_timer >= idle_time_at_points:
				current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
				movement_timer = 0.0
				is_moving = true
	else:
		is_moving = true
		play_walk_animation()
		var direction = (target_pos - global_transform.origin).normalized()
		velocity = direction * patrol_speed
		move_and_slide()

func handle_wander_movement(delta):
	movement_timer += delta
	if movement_timer >= idle_time_at_points:
		var random_offset = Vector3(
			randf_range(-wander_radius, wander_radius),
			0,
			randf_range(-wander_radius, wander_radius)
		)
		var target_pos = original_position + random_offset
		
		var direction = (target_pos - global_transform.origin).normalized()
		if global_transform.origin.distance_to(target_pos) > 1.0:
			play_walk_animation()
			velocity = direction * patrol_speed
			move_and_slide()
		else:
			movement_timer = 0.0
			play_idle_animation()

func face_player():
	if player_reference:
		var direction = (player_reference.global_transform.origin - global_transform.origin)
		direction.y = 0
		if direction.length() > 0:
			look_at(global_transform.origin + direction, Vector3.UP)

func is_player_nearby() -> bool:
	if not player_reference:
		return false
	return global_transform.origin.distance_to(player_reference.global_transform.origin) <= interaction_distance

func interact():
	if not can_interact:
		return
	
	if dialogue_data.is_empty():
		return
	
	
	hide_interact_prompt()
	
	play_greeting_animation()
	
	has_been_interacted_with = true
	last_interaction_time = Time.get_ticks_msec() / 1000.0
	
	if dialogue_id != "":
		start_dialogue()
	else:
		print("⚠️ No dialogue_id set for ", npc_name)

func start_dialogue():
	stop_random_voice_line()
	
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if dialogue_manager and dialogue_manager.start_dialogue(self, dialogue_data, dialogue_id):
		is_in_dialogue = true
		if not dialogue_ui:
			print("⚠️ No dialogue UI found")
	else:
		print("⚠️ NPCDialogueManager not found or dialogue failed to start")

func play_dialogue_voice_line(dialogue_index: int):
	
	if use_recorded_voice_lines and voice_lines.size() > dialogue_index:
		var audio_file = voice_lines[dialogue_index]
		
		if audio_file and voice_audio_player:
			voice_audio_player.stream = audio_file
			voice_audio_player.pitch_scale = voice_pitch
			voice_audio_player.volume_db = voice_volume
			voice_audio_player.play()
		else:
			if not audio_file:
				print("⚠️ No audio file at index ", dialogue_index)
			if not voice_audio_player:
				print("⚠️ No voice_audio_player found")
	else:
		print("⚠️ Voice lines not enabled or index out of range")

func play_typewriter_sound():
	if typewriter_sound and typewriter_audio_player:
		typewriter_audio_player.stream = typewriter_sound
		typewriter_audio_player.pitch_scale = voice_pitch + randf_range(-0.1, 0.1)
		typewriter_audio_player.volume_db = voice_volume - 10.0
		typewriter_audio_player.play()

func get_current_dialogue_audio_index() -> int:
	var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
	if dialogue_manager and dialogue_manager.current_npc == self:
		return dialogue_manager.current_dialogue_index
	return -1

func play_dialogue_voice(_voice_id: String = "", _voice_config: Dictionary = {}):
	if use_recorded_voice_lines:
		var audio_index = get_current_dialogue_audio_index()
		play_dialogue_voice_line(audio_index)

func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func play_greeting_animation():
	if greeting_animation != "":
		play_animation(greeting_animation)

func play_idle_animation():
	if idle_animation != "":
		play_animation(idle_animation)

func play_walk_animation():
	if walking_animation != "":
		play_animation(walking_animation)

func _on_interaction_area_entered(body):
	if body == player_reference:
		player_in_range = true
		if not is_in_dialogue:
			show_interact_prompt()
		
		play_random_voice_line_on_approach()

func _on_interaction_area_exited(body):
	if body == player_reference:
		player_in_range = false
		hide_interact_prompt()
		
		stop_random_voice_line()
		
		if is_in_dialogue:
			stop_voice_audio()
			var dialogue_manager = get_node_or_null("/root/NPCDialogueManager")
			if dialogue_manager:
				dialogue_manager.end_dialogue()

func show_interact_prompt():
	if interaction_prompt:
		interaction_prompt.visible = true

func hide_interact_prompt():
	if interaction_prompt:
		interaction_prompt.visible = false

func stop_voice_audio():
	if voice_audio_player and voice_audio_player.playing:
		voice_audio_player.stop()

func play_random_voice_line_on_approach():
	if not include_random_voice_lines:
		return
	
	if random_voice_lines.is_empty():
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_random_voice_time < random_voice_cooldown:
		return
	
	if randf() > random_voice_chance:
		return
	
	if is_in_dialogue or is_playing_random_voice:
		return
	
	var random_index = randi() % random_voice_lines.size()
	var random_audio = random_voice_lines[random_index]
	
	if random_audio and random_voice_audio_player:
		random_voice_audio_player.stream = random_audio
		random_voice_audio_player.pitch_scale = voice_pitch + randf_range(-0.1, 0.1)
		random_voice_audio_player.volume_db = voice_volume
		random_voice_audio_player.play()
		
		is_playing_random_voice = true
		last_random_voice_time = current_time
		
		if not random_voice_audio_player.finished.is_connected(_on_random_voice_finished):
			random_voice_audio_player.finished.connect(_on_random_voice_finished)

func stop_random_voice_line():
	if random_voice_audio_player and random_voice_audio_player.playing:
		random_voice_audio_player.stop()
		is_playing_random_voice = false

func _on_random_voice_finished():
	is_playing_random_voice = false

func _on_dialogue_ended():
	is_in_dialogue = false
	stop_voice_audio()
	play_idle_animation()
	
	if player_in_range:
		show_interact_prompt()
	
	if dialogue_ui:
		dialogue_ui.hide_dialogue()

func get_player_name() -> String:
	return "Player"

func check_dialogue_condition(condition: String) -> bool:
	match condition:
		"first_meeting":
			return not has_been_interacted_with
		"recent_interaction":
			return (Time.get_ticks_msec() / 1000.0 - last_interaction_time) < 300.0
	return false

func execute_dialogue_action(action: String):
	var parts = action.split(" ", false, 1)
	var command = parts[0] if parts.size() > 0 else ""
	var parameter = parts[1] if parts.size() > 1 else ""
	
	match command:
		"play_animation":
			play_animation(parameter)
		"mark_interacted":
			has_been_interacted_with = true
