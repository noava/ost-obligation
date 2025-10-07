@tool
extends Area3D

@export var item_data: ItemData
@export var quantity: int = 1
@onready var item: Node3D = $Item
@onready var prompt_label: Label3D = $PromptLabel
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@export var collect_sound: AudioStream = preload("res://Items/Collectable/collectable.wav")
var is_highlighted: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	
	prompt_label.hide()

	# Display item in 3D
	if item_data and item_data.item_scene:
		var item_instance = item_data.item_scene.instantiate()
		
		item.add_child(item_instance)

func _process(_delta):
	if Engine.is_editor_hint():
		return
	
	# Rotate when highlighted
	if is_highlighted:
		item.rotate_y(deg_to_rad(-90.0 * _delta))
	else:
		item.rotation_degrees = Vector3.ZERO
	
	# Check if player is looking at this
	var should_highlight = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var raycast = player.get_node_or_null("CameraPivot/HeadRayCast")
		if raycast and raycast.is_colliding() and raycast.get_collider() == self:
			should_highlight = true
			if Input.is_action_just_pressed("e"):
				add_to_inventory(player)
	
	if should_highlight and not is_highlighted:
		apply_highlight()
	elif not should_highlight and is_highlighted:
		remove_highlight()

func apply_highlight():
	is_highlighted = true
	if item_data.stackable:
		prompt_label.text = "%s x%d" % [item_data.name, quantity]
	else:
		prompt_label.text = "%s" % item_data.name
	prompt_label.show()

func remove_highlight():
	is_highlighted = false
	prompt_label.hide()

func _on_body_entered(body: Node3D):
	if body.name == "Player" and item_data:
		add_to_inventory(body)

func add_to_inventory(player: Node3D):
	var player_inv = player.get_node_or_null("UI/InventoryInterface")
	if not player_inv:
		print("Could not find player inventory")
		return
	
	var inventory_data = player_inv.inventory_data
	var added = false
	
	# First pass: try to stack with existing items
	for i in range(inventory_data.slot_datas.size()):
		var slot = inventory_data.slot_datas[i]
		
		if slot and slot.item_data == item_data and item_data.stackable:
			slot.quantity += quantity
			added = true
			break
	
	# Second pass: find empty slot if not stacked
	if not added:
		for i in range(inventory_data.slot_datas.size()):
			var slot = inventory_data.slot_datas[i]
			
			if slot == null or slot.item_data == null:
				var new_slot = SlotData.new()
				new_slot.item_data = item_data
				new_slot.quantity = quantity
				inventory_data.slot_datas[i] = new_slot
				added = true
				break
	
	if added:
		# Refresh UI
		player_inv.ui_inventory.set_inventory_data(inventory_data)
	
		# Refresh Picnic
		var picnic = get_tree().current_scene.get_node_or_null("Picnic")
		if picnic:
			picnic.set_inventory_data(inventory_data)
		
		item.hide()
		
		if collect_sound and audio_player:
			audio_player.stream = collect_sound
			audio_player.play()
			await audio_player.finished
		queue_free()

	else:
		print("Inventory full!")
