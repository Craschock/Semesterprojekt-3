extends Node

# Load scene into memory
var damage_number_scene: PackedScene = preload("res://! self made/scenes/ui/text labels/damage_number.tscn")

func spawn_damage_number(spawn_position: Vector2, amount: int) -> void:
	var dmg = damage_number_scene.instantiate()
	
	# Add to game tree so it doesn't move
	get_tree().current_scene.add_child(dmg)
	
	dmg.global_position = spawn_position
	dmg.start(amount)
