extends RigidBody2D
class_name BaseItem

## Item data (Sprite, name, etc.). Create a resource and add here
@export var item_data: ItemData
## Stack size
@export var amount: int = 1
## Pickup textprompt (z.Bsp. "pick up", "consume " or "interact ") 
@export var pickup_message: String = "Pick up "

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_ol: Sprite2D = $Sprite2D_OL
@onready var interactable: InteractableComponent =$InteractableComponent

func _ready() -> void:
	sprite_ol.hide()
	
	# Update Item
	if item_data:
		if item_data.icon.size() > 0:
			sprite.texture = item_data.icon[0]
		if item_data.icon.size() > 1:
			sprite_ol.texture = item_data.icon[1]
		interactable.prompt_message = pickup_message + item_data.item_name
	
	
	# Connect Signal
	interactable.interacted.connect(_on_interacted)
	interactable.body_entered.connect(_on_player_entered)
	interactable.body_exited.connect(_on_player_exited)

func _on_player_entered(body: Node2D) -> void:
	print("player entered")
	sprite_ol.show()
	sprite.hide()

func _on_player_exited(body: Node2D) -> void:
	print("player left")
	sprite_ol.hide()
	sprite.show()

func _on_interacted(interactor: Node) -> void:
	# Get Inventory from Interactor
	var inventory: InventoryComponent = interactor.get_node_or_null("InventoryComponent")
	
	# If Inventory exists, add the item, remove taken amount or delete it
	if inventory and item_data:
		var amount_taken = inventory.add_item(item_data, amount)
		if amount_taken > 0:
			# Remove amount thjat was taken
			amount -= amount_taken
			
			# delete item when fully taken
			if amount <= 0:
				queue_free()
			
	
