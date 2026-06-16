extends State
class_name PlayerAction

var player: PlayerMovement

func _ready() -> void:
	player = owner

func physics_update(_delta: float) -> void:
	var held_item = player.inventory_component.get_active_item()
	
	if held_item == null:
		transitioned.emit(self, "attack_scratch")
	elif held_item.type == ItemData.ItemType.CONSUMABLE:
		transitioned.emit(self, "item_consume")
	elif held_item.type == ItemData.ItemType.WEAPON:
		transitioned.emit(self, "item_attack")
	elif held_item.type == ItemData.ItemType.THROWABLE:
		transitioned.emit(self, "item_throw")
