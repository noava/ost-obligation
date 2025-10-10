extends Resource
class_name ItemData

@export var name: String = ""
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var texture: Texture2D
enum ItemType { NONE, EQUIPMENT, MATERIAL, CURRENCY, OTHER }
@export var item_type: ItemType = ItemType.NONE
@export var item_scene: PackedScene
@export var item_offset: Vector3 = Vector3.ZERO
@export var collision_height: float = 0.5
