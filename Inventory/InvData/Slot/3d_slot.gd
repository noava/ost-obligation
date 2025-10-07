extends Node3D

@onready var item_scene: Node3D = $ItemScene
@onready var name_label: Label3D = $Name
@onready var quantity_label: Label3D = $Amount
@onready var selectable: Sprite3D = $Selectable

var slot_data: SlotData = null

var is_selectable: bool = false

func _ready() -> void:
	name_label.hide()
	quantity_label.hide()
	selectable.hide()

func set_slot_data(new_slot_data: SlotData) -> void:
	slot_data = new_slot_data
	
	if slot_data and slot_data.item_data:
		var item_data = slot_data.item_data
		var scene = item_data.item_scene.instantiate()
		item_scene.add_child(scene)
		
		name_label.text = item_data.name
		if item_data.name:
			name_label.show()
			
		if slot_data.item_data.stackable:
			quantity_label.text = "x%s" % slot_data.quantity
			quantity_label.show()
	else:
			quantity_label.text = ""
			quantity_label.hide()

func set_selectable(is_highlighted: bool) -> void:
	is_selectable = is_highlighted
	selectable.visible = is_selectable
