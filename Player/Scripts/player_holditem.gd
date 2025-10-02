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
			if held_slot_index == i:
				remove_held_item()
			else:
				hold_item(i)
	
	# Store items between hand and inventory # TODO: Place items on floor
	if Input.is_action_just_pressed(KEY_PICKUP) and not held_item_type == "bindle":
		if held_slot_index != null and player_inv.get_highlighted_slot():
			var target_slot_index = player_inv.get_highlighted_slot()
			player_inv.move_item_to_slot(held_slot_index, target_slot_index)
			hold_item(held_slot_index)

	# Handle holding bindle
	if Input.is_action_just_pressed(KEY_BIND_BINDLE):
		if held_item_type != "bindle" and not is_bindle_placed:
			hold_bindle()
		else:
			remove_held_item()

	# Place bindle
	if Input.is_action_just_pressed(KEY_PLACE) and held_item_type == "bindle":
		place_bindle()
	
	# Pickup bindle
	if Input.is_action_just_pressed(KEY_BIND_BINDLE) and is_bindle_placed:
		pick_up_bindle()

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
