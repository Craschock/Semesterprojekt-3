extends Node
class_name EnemySpawner

@export_category("References")
## WorldGenerator node 
@export var world_generator: WorldGenerator
## Where to place enemies in tree 
@export var entity_container: Node 

@export_category("Spawns")
## Enemy scene
@export var enemy_pool: Array[EnemySpawnData]

# To keep track chunks
var _processed_chunks: Array[Vector2i] = []

func _ready() -> void:
	# For performance, spawns enemy every 0.5 seconds
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_check_for_spawns)
	add_child(timer)

func _check_for_spawns() -> void:
	if world_generator == null or enemy_pool.is_empty() or entity_container == null:
		return

	for chunk_pos in world_generator._enemy_spawns.keys():
		
		if not _processed_chunks.has(chunk_pos):
			_processed_chunks.append(chunk_pos)
			
			var positions = world_generator._enemy_spawns[chunk_pos]
			
			for local_pos in positions:
				_spawn_enemy(local_pos)

func _spawn_enemy(local_pos: Vector2) -> void:
	var total_weight: float = 0.0
	
	for enemy_data in enemy_pool:
		total_weight += enemy_data.spawn_chance
	
	var random_value: float = randf_range(0.0, total_weight)
	var current_weight: float = 0.0
	var chosen_scene: PackedScene = null
	
	for enemy_data in enemy_pool:
		current_weight += enemy_data.spawn_chance
		if random_value <= current_weight:
			chosen_scene = enemy_data.scene
			break
		
	
	if chosen_scene:
		var enemy = chosen_scene.instantiate()
		var global_spawn_pos = world_generator.to_global(local_pos)
		
		enemy.global_position = global_spawn_pos
		entity_container.add_child(enemy)
