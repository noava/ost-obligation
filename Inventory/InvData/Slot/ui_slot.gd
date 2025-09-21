extends PanelContainer

@onready var texture_rect: TextureRect = $MarginContainer/PanelContainer/TextureRect
@onready var name_label: Label = $NameLabel

var slot_data: SlotData = null:
	get = get_slot_data, set = set_slot_data
	
func set_slot_data(new_slot_data: SlotData) -> void:
	slot_data = new_slot_data
	
	if slot_data and slot_data.item_data:
		var item_data = slot_data.item_data
		texture_rect.texture = item_data.texture
		tooltip_text = item_data.name
		name_label.text = item_data.name
	else:
		texture_rect.texture = null
		name_label.text = ""
	
func get_slot_data() -> SlotData:
	return slot_data
