extends PanelContainer

@onready var texture_rect: TextureRect = $MarginContainer/PanelContainer/TextureRect
@onready var name_label: Label = $NameLabel
@onready var quantity_label: Label = $MarginContainer/QuantityLabel

var is_highlighted: bool = false

func set_slot_data(slot_data: SlotData) -> void:	
	if slot_data and slot_data.item_data:
		var item_data = slot_data.item_data
		texture_rect.texture = item_data.texture
		# TODO: Add another color to svg
		tooltip_text = item_data.name
		name_label.text = item_data.name
		
		if slot_data.item_data.stackable:
			quantity_label.text = "x%s" % slot_data.quantity
			quantity_label.show()
	else:
		texture_rect.texture = null
		name_label.text = ""
		quantity_label.hide()

func set_highlight(highlighted: bool) -> void:
	is_highlighted = highlighted
	if highlighted:
		self.scale = Vector2(1.2, 1.2)
	else:
		self.scale = Vector2(1, 1)
