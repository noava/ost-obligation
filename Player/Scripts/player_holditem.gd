extends Node

@onready var item_holder: Node3D = $"../LilMouseGuy/rig/Skeleton3D/HandR/ItemHolder"

var is_holding: bool = false
var item_candle: PackedScene = preload("res://Items/Candle/candle.tscn")

@export_category("Key Binds")
@export_subgroup("Interacting")
@export var KEY_BIND_CANDLE := "key_1"


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(KEY_BIND_CANDLE):
		is_holding = !is_holding
	if is_holding:
		if item_holder.get_child_count() == 0:
			var candle = item_candle.instantiate()
			candle.position = Vector3(0, -0.1, 0.235)
			item_holder.add_child(candle)
	else:
		if item_holder.get_child_count() > 0 and item_holder.get_child(0):
			item_holder.get_child(0).queue_free()
