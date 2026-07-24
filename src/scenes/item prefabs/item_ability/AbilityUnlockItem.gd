extends RigidBody2D
class_name AbilityUnlockItem

enum Ability { DIGGING, TEST1, TEST2, TEST3 }

@export_category("Unlock Settings")
## Ability from enum
@export var ability_to_unlock: Ability = Ability.DIGGING
## Displayed name of ability
@export var item_name: String = "New Claw"
## Displayed prompt of interaction
@export var interact_prompt: String = "Pick up: "

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_ol: Sprite2D = $Sprite2D_OL
@onready var interactable: InteractableComponent = $InteractableComponent

func _ready() -> void:
	interactable.prompt_message = interact_prompt + item_name
	sprite_ol.hide()
	
	interactable.interacted.connect(_on_interacted)
	interactable.body_entered.connect(_on_player_entered)
	interactable.body_exited.connect(_on_player_exited)

func _on_player_entered(_body: Node2D) -> void:
	sprite_ol.show()
	sprite.hide()

func _on_player_exited(_body: Node2D) -> void:
	sprite_ol.hide()
	sprite.show()

func _on_interacted(interactor: Node) -> void:
	if interactor is PlayerMovement:
		if ability_to_unlock == Ability.DIGGING:
			interactor.unlocked_digging = true
			interactor.get_node_or_null("TextBubble").play_text("Press Q, Then Spacebar", 10)
		queue_free()
