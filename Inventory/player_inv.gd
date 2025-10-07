extends Control

@export var inventory_data: InventoryData
@onready var player: CharacterBody3D = $"../.."
@onready var ui_inventory: PanelContainer = $UiInventory
@onready var hold_item: Node3D = $"../../HoldItem"
@onready var head_ray_cast: RayCast3D = $"../../CameraPivot/HeadRayCast"

var highlighted_slot: Node = null

func _ready() -> void:
	ui_inventory.set_inventory_data(inventory_data)

func _physics_process(_delta: float) -> void:
	update_slot_highlight()
				
func update_slot_highlight():
	var new_highlighted_slot = null
	if head_ray_cast.is_colliding():
		var collider = head_ray_cast.get_collider()
		if collider != player and collider.has_node("Selectable"):
			new_highlighted_slot = collider

	if new_highlighted_slot != highlighted_slot:
		if highlighted_slot and highlighted_slot.has_method("set_selectable"):
			highlighted_slot.set_selectable(false)
		if new_highlighted_slot and new_highlighted_slot.has_method("set_selectable"):
			new_highlighted_slot.set_selectable(true)
		highlighted_slot = new_highlighted_slot

func get_highlighted_slot():
	if highlighted_slot:
		return highlighted_slot.get_index() + 3
	return null

func move_item_to_slot(from_index: int, to_index: int) -> void:
	var from_slot_data = inventory_data.slot_datas[from_index]
	var to_slot_data = inventory_data.slot_datas[to_index]

	# If items are the same and stackable, merge them
	if from_slot_data and to_slot_data and from_slot_data.item_data == to_slot_data.item_data and from_slot_data.item_data.stackable:
		to_slot_data.quantity += from_slot_data.quantity
		inventory_data.slot_datas[from_index] = null
	else:
		inventory_data.slot_datas[to_index] = from_slot_data
		inventory_data.slot_datas[from_index] = to_slot_data

	# 3D
	var picnic = get_tree().current_scene.get_node_or_null("Picnic")
	if picnic:
		picnic.set_inventory_data(inventory_data)
	
	# UI
	ui_inventory.set_inventory_data(inventory_data)
	# TODO: Fix re-applying highlight
	ui_inventory.highlight_slot(from_index)
