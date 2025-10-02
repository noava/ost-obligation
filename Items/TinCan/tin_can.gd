@tool #For showing updated textures in the 3D view
extends Node3D

@export var image: Texture2D
@onready var tin_can: MeshInstance3D = $tin_can
@export var is_carryable: bool = true
@onready var item_scene: PackedScene = preload("res://Items/TinCan/tin_can.tscn")
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	if image:
		tin_can.mesh = tin_can.mesh.duplicate()
		
		var material = tin_can.mesh.surface_get_material(1)
		if material:
			var unique_material = material.duplicate()
			unique_material.albedo_texture = image
			tin_can.mesh.surface_set_material(1, unique_material)

func get_carryable_node():
	if is_carryable:
		return self
	else:
		return null

func grab_item(is_grabbed: bool):
	if collision_shape_3d:
		collision_shape_3d.disabled = is_grabbed
	if is_grabbed:
		self.gravity_scale = 0
	else:
		self.gravity_scale = 1
