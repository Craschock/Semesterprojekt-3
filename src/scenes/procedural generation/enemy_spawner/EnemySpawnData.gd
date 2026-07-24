extends Resource
class_name EnemySpawnData

## Enemy scene that will be instanced
@export var scene: PackedScene
## Chance of enemy Spawning
@export_range(0.0, 1.0, 0.05) var spawn_chance: float = 1.0
