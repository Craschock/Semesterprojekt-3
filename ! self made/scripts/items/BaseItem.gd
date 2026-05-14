extends RigidBody2D
class_name BaseItem

@export var item_data: ItemData
@export var pickup_message: String = "Pick up "

@onready var sprite: Sprite2D = $Sprite2D
@onready var interactable: InteractableComponent =$InteractableComponent

func _ready() -> void:
	
	# Update Item
	if item_data:
		sprite.texture = item_data.icon
		interactable.prompt_message = pickup_message + item_data.item_name
	
	# Connect Signal
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	# Get Inventory from Interactor
	var inventory: InventoryComponent = interactor.get_node_or_null("InventoryComponent")
	
	# If Inventory exists, add the item and delete it
	if inventory and item_data:
		inventory.add_item(item_data)
		queue_free()
	
