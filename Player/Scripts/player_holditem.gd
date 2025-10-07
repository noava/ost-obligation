extends Node

@onready var item_holder: Node3D = $"../LilMouseGuy/rig/Skeleton3D/HandR/ItemHolder"
@export var player_model: Node3D
@onready var player_inv: Control = $"../UI/InventoryInterface"
@onready var head_ray_cast: RayCast3D = $"../CameraPivot/HeadRayCast"

var is_holding: bool = false
var item_bindle: PackedScene = preload("res://Items/Bindle/bindle.tscn")
var picnic_scene: PackedScene = preload("res://Inventory/Picnic/picnic.tscn")
var is_bindle_placed: bool = false
var q_hold_time := 0.0
var held_item_type: String = "none"
var placed_bindle: Node3D = null
var held_slot_index = null
var ui_slot = null
var carried_item: PackedScene = null
var is_carrying: bool = false

@export_category("Key Binds")
@export_subgroup("Interacting")
@export var KEY_BIND_1 := "key_1"
@export var KEY_BIND_2 := "key_2"
@export var KEY_BIND_3 := "key_3"
@export var KEY_BIND_BINDLE := "key_4"
@export var KEY_PLACE := "q"
@export var KEY_PICKUP := "e"
var item_keys = [KEY_BIND_1, KEY_BIND_2, KEY_BIND_3]


func _physics_process(_delta: float) -> void:
	# Handle holding items
	for i in range(item_keys.size()):
		if Input.is_action_just_pressed(item_keys[i]):
			if is_carrying:
				place_carried_item()
			if held_slot_index == i:
				remove_held_item()
			else:
				hold_item(i)
	
	# Store and merge items between hand and inventory
	if Input.is_action_just_pressed(KEY_PICKUP) and not held_item_type == "bindle":
		if held_slot_index != null and player_inv.get_highlighted_slot():
			var target_slot_index = player_inv.get_highlighted_slot()
			player_inv.move_item_to_slot(held_slot_index, target_slot_index)
			hold_item(held_slot_index)

	# Handle holding bindle
	if Input.is_action_just_pressed(KEY_BIND_BINDLE):
		if is_carrying:
			place_carried_item()
		if held_item_type != "bindle" and not is_bindle_placed and not is_carrying:
			hold_bindle()
		else:
			remove_held_item()

	# Place bindle
	if Input.is_action_just_pressed(KEY_PLACE) and held_item_type == "bindle":
		place_bindle()
	
	# Pickup bindle
	if Input.is_action_just_pressed(KEY_BIND_BINDLE) and is_bindle_placed:
		pick_up_bindle()
	
	# Carry item
	var collider = head_ray_cast.get_collider()
	if collider and collider.has_method("get_carryable_node"):
		if Input.is_action_just_pressed(KEY_PICKUP):
			if collider.get_carryable_node() and held_item_type == "none":
				carry_item_from_world(collider)
			else:
				print("Cannot carry this")

	# Drop carried items or place items
	if Input.is_action_just_pressed(KEY_PLACE) and not held_item_type == "bindle":
		if not held_slot_index:
			place_carried_item()
		
		drop_item()

func hold_item(slot_index: int):
	remove_held_item()
	held_slot_index = slot_index

	var slot_data = player_inv.inventory_data.slot_datas[slot_index]
	if slot_data and slot_data.item_data and slot_data.item_data.item_scene:
		is_holding = true
		var item_instance = slot_data.item_data.item_scene.instantiate()
		item_instance.position = Vector3(0, -0.1, 0.235)
		item_holder.add_child(item_instance)
		held_item_type = slot_data.item_data.name

	player_inv.ui_inventory.highlight_slot(slot_index)

func drop_item():
	if held_slot_index == null:
		return
	
	var slot_data = player_inv.inventory_data.slot_datas[held_slot_index]
	if slot_data and slot_data.item_data:
		var collectable_scene = preload("res://Items/Collectable/collectable.tscn")
		var collectable_instance = collectable_scene.instantiate()
		
		collectable_instance.item_data = slot_data.item_data
		collectable_instance.quantity = slot_data.quantity
		
		get_tree().current_scene.add_child(collectable_instance)
		
		if head_ray_cast.is_colliding():
			collectable_instance.global_position = head_ray_cast.get_collision_point()
		else:
			var forward = player_model.global_transform.basis.z.normalized()
			collectable_instance.global_position = player_model.global_position + forward * 1.5
		
		player_inv.inventory_data.slot_datas[held_slot_index] = null
		player_inv.ui_inventory.set_inventory_data(player_inv.inventory_data)
	
	remove_held_item()

func hold_bindle():
	remove_held_item()
	is_holding = true
	var bindle = item_bindle.instantiate()
	bindle.rotation_degrees = Vector3(69, 190, 0)
	item_holder.add_child(bindle)
	held_item_type = "bindle"

func remove_held_item():
	if item_holder.get_child_count() > 0 and item_holder.get_child(0):
		item_holder.get_child(0).queue_free()
	held_item_type = "none"
	is_holding = false
	carried_item = null
	if held_slot_index:
		player_inv.ui_inventory.highlight_slot(held_slot_index)
	held_slot_index = null

func place_bindle():
	placed_bindle = picnic_scene.instantiate()
	self.placed_bindle = placed_bindle

	placed_bindle.rotation.y = player_model.rotation.y - PI
	placed_bindle.transform.origin = get_parent().transform.origin
	get_tree().current_scene.add_child(placed_bindle)
	placed_bindle.set_inventory_data(player_inv.inventory_data)
	remove_held_item()
	is_bindle_placed = true

func pick_up_bindle():
	if is_bindle_placed:
		is_bindle_placed = false
		hold_bindle()
		placed_bindle.queue_free()

func carry_item_from_world(item_node: Node3D):
	place_carried_item()
	is_carrying = true
	item_node.grab_item(true)
	item_node.get_parent().remove_child(item_node)
	item_node.position = Vector3(0, 0, 0)
	item_node.rotation = Vector3(0, 0, 0)
	item_holder.add_child(item_node)

func place_carried_item():
	if not is_carrying or item_holder.get_child_count() == 0:
		return
	var carried_node = item_holder.get_child(0)
	item_holder.remove_child(carried_node)
	get_tree().current_scene.add_child(carried_node)

	carried_node.rotation.y = player_model.rotation.y - PI
	
	if head_ray_cast.is_colliding():
		var drop_position = head_ray_cast.get_collision_point()
		carried_node.global_transform.origin = drop_position
	else:
		var forward = player_model.global_transform.basis.z.normalized()
		var drop_position = player_model.global_transform.origin + forward * 1.5
		carried_node.global_transform.origin = drop_position
	
	carried_node.grab_item(false)
	remove_held_item()
	is_carrying = false
