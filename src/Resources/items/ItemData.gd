extends Resource
class_name ItemData

enum ItemType { WEAPON, THROWABLE, CONSUMABLE}
@export var type: ItemType = ItemType.CONSUMABLE

@export var item_name: String = "Unknown Item"
@export_multiline var description: String = ""
@export var icon: Array[Texture2D] = []
@export var max_stack_size: int = 99

@export_category("Usage Effect")
@export  var consume_effects: Array[ItemEffect] = []
@export  var throw_effects: Array[ItemEffect] = []
# TODO add other effects later
