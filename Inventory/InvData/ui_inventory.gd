extends PanelContainer

const Slot = preload("res://Inventory/InvData/Slot/ui_slot.tscn")

@onready var item_grid: GridContainer = $MarginContainer/ItemGrid

func set_inventory_data(inventory_data: InventoryData) -> void:
	populate_item_grid(inventory_data)

func populate_item_grid(inventory_data: InventoryData) -> void:
	for child in item_grid.get_children():
		child.queue_free()
	
	# Show the first three items
	for i in range(3):
		var slot_data = inventory_data.slot_datas[i]
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		if slot_data:
			slot.set_slot_data(slot_data)

func highlight_slot(index: int) -> void:
	for slot in item_grid.get_children():
		if slot.get_index() == index:
			slot.set_highlight(true)
		else:
			slot.set_highlight(false)
