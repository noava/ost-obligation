extends Node3D

const Slot = preload("res://Inventory/InvData/Slot/3d_slot.tscn")

@onready var item_grid: Node3D = $ItemGrid

func set_inventory_data(inventory_data: InventoryData) -> void:
	populate_item_grid(inventory_data.slot_datas)
	
func populate_item_grid(slot_datas: Array[SlotData]) -> void:
	for child in item_grid.get_children():
		child.queue_free()
	
	var grid_size = 3
	var grid_width = 1.4
	var grid_height = 1.4
	var spacing_x = grid_width / (grid_size - 1)
	var spacing_y = grid_height / (grid_size - 1)
	
	# First three items are in hand
	for i in range(3, len(slot_datas)):
		var slot_data = slot_datas[i]
		var slot = Slot.instantiate()
		item_grid.add_child(slot)

		var grid_index = i - 3
		var row = int(grid_index / grid_size)
		var col = grid_index % grid_size
		slot.position = Vector3(col * spacing_x - grid_width / 2, 0, row * spacing_y - grid_height / 2)

		if slot_data:
			slot.set_slot_data(slot_data)
