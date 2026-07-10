extends Node
class_name EnemySpawner

@export_category("References")
## WorldGenerator node 
@export var world_generator: WorldGenerator
## Enemy scene
@export var enemy_scene: Array[PackedScene]
## Where to place enemies in tree 
# Also einfach nur eine node als "folder". 
# Hier einfach die Root node einfügen. Funktioniert sonst nicht
# Denke mal wegen den scalierungen. Änder ich wann anders mal
@export var entity_container: Node 

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
	if world_generator == null or enemy_scene == null or entity_container == null:
		return

	for chunk_pos in world_generator._enemy_spawns.keys():
		
		if not _processed_chunks.has(chunk_pos):
			_processed_chunks.append(chunk_pos)
			
			var positions = world_generator._enemy_spawns[chunk_pos]
			
			for local_pos in positions:
				_spawn_enemy(local_pos)

func _spawn_enemy(local_pos: Vector2) -> void:
	var enemy = enemy_scene.pick_random().instantiate()
	var global_spawn_pos = world_generator.to_global(local_pos)
	
	enemy.global_position = global_spawn_pos
	entity_container.add_child(enemy)
