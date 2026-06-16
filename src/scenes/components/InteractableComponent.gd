extends Area2D
class_name InteractableComponent

# Interaction Signal for Parent
signal interacted(interactor: Node)

# Popup text var
@export var prompt_message: String = "This is an Interaction ahh text"

# Call on Interaction
func interact(interactor: Node) -> void:
	interacted.emit(interactor)
