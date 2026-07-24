extends Node2D
class_name LootDropComponent

@export_category("Links")
## HealthComponent for item drop signalö
@export var health_component: HealthComponent

@export_category("Loot Settings")
## Item pool (PackedScenes, change to resource mby?)
@export var possible_drops: Array[PackedScene]
## Chance of dropping (0.0 = Never, 1.0 = Aklways)
@export_range(0.0, 1.0) var drop_chance: float = 1.0
## Velocity/Strength of item flying into the air on drop (randomize in the future)
@export var pop_force: float = 150.0

func _start_drop() -> void:
	if possible_drops.is_empty():
		return
	
	if randf() > drop_chance:
		return
	
	var chosen_item = possible_drops.pick_random()
	
	if chosen_item:
		_spawn_loot(chosen_item)

func _spawn_loot(item_scene: PackedScene) -> void:
	var loot = item_scene.instantiate()
	
	loot.global_position = global_position
	
	if loot is RigidBody2D:
		var random_dir_x = randf_range(-50.0, 50.0)
		loot.linear_velocity = Vector2(random_dir_x, -pop_force)
		
	
	get_tree().current_scene.call_deferred("add_child", loot)
