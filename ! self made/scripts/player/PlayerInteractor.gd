extends Area2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# Get all InteractableComponents currently in range
		var interactables = get_overlapping_areas()
		
		if interactables.size() > 0:
			var target = interactables[0]
			if target is InteractableComponent:
				target.interact(owner) # Give Interactable the player
