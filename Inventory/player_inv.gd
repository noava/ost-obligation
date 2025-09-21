extends Control

@onready var player: CharacterBody3D = $"../.."
@onready var ui_inventory: PanelContainer = $UiInventory

func _ready() -> void:
	ui_inventory.set_inventory_data(player.inventory_data)
