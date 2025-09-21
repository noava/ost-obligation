extends Node

@onready var item_holder: Node3D = $"../LilMouseGuy/rig/Skeleton3D/HandR/ItemHolder"
@export var player_model: Node3D
@onready var player: CharacterBody3D = $".."

var is_holding: bool = false
var item_candle: PackedScene = preload("res://Items/Candle/candle.tscn")
var item_bindle: PackedScene = preload("res://Items/Bindle/bindle.tscn")
var picnic_scene: PackedScene = preload("res://Inventory/Picnic/picnic.tscn")
var is_bindle_placed: bool = false
var q_hold_time := 0.0
var held_item_type: String = "none"
var placed_item: Node3D = null

@export_category("Key Binds")
@export_subgroup("Interacting")
@export var KEY_BIND_1 := "key_1"
@export var KEY_BIND_2 := "key_2"
@export var KEY_BIND_3 := "key_3"
@export var KEY_BIND_BINDLE := "key_4"
@export var KEY_PLACE := "q"
@export var KEY_PICKUP := "key_4"


func _physics_process(_delta: float) -> void:
	# Handle holding items
	if Input.is_action_just_pressed(KEY_BIND_1):
		hold_item(0)
	if Input.is_action_just_pressed(KEY_BIND_2):
		hold_item(1)
	if Input.is_action_just_pressed(KEY_BIND_3):
		hold_item(2)

	# Handle holding bindle
	if Input.is_action_just_pressed(KEY_BIND_BINDLE):
		if held_item_type != "bindle" and not is_bindle_placed:
			hold_bindle()
		else:
			remove_held_item()

	# Place bindle
	if held_item_type == "bindle" and Input.is_action_just_pressed(KEY_PLACE):
		place_item()
	
	# Pickup bindle
	if is_bindle_placed and Input.is_action_just_pressed(KEY_PICKUP):
		pick_up_bindle()

func hold_item(slot_index: int):
	var slot_data = player.inventory_data.slot_datas[slot_index]
	remove_held_item()
	is_holding = true
	if slot_data and slot_data.item_data.item_scene:
		var item_instance = slot_data.item_data.item_scene.instantiate()
		item_instance.position = Vector3(0, -0.1, 0.235)
		item_holder.add_child(item_instance)
		held_item_type = slot_data.item_data.name

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

func place_item():
	placed_item = picnic_scene.instantiate()
	self.placed_item = placed_item

	placed_item.rotation.y = player_model.rotation.y - PI
	placed_item.transform.origin = get_parent().transform.origin
	get_tree().current_scene.add_child(placed_item)
	placed_item.set_inventory_data(player.inventory_data)
	remove_held_item()
	is_bindle_placed = true

func pick_up_bindle():
	if is_bindle_placed:
		is_bindle_placed = false
		hold_bindle()
		placed_item.queue_free()
