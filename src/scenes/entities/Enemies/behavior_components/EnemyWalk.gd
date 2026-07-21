extends State
class_name EnemyWalk

#Izzy here: established sfx_enemy_walk as a variable
@onready var sfx_enemy_walk: AudioStreamPlayer2D = $"../../sfx_enemy_walk"

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "walk"
## Next State Node to transition to
@export var next_state: State

@export_category("Walk Settings")
@export var speed: float = 30.0
@export var min_walk_time: float = 0.3
@export var max_walk_time: float = 3.0
@export var flip_sprite: bool = false

var timer: float = 0.0
var direction: int = 1

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.get_node("AnimatedSprite2D").play(animation_name)
	
	# Pick random walk time
	timer = randf_range(min_walk_time, max_walk_time)
	
	# Pick random direction
	direction = [-1, 1].pick_random()
	#Izzy here: If the enemy walking has a sfx_enemy_walk, it will start playing the sound heree
	if sfx_enemy_walk:
		sfx_enemy_walk.play()

func physics_update(delta: float) -> void:
	timer -= delta
	
	# Apply movement
	enemy.velocity.x = direction * speed
	enemy.update_facing(direction)
	
	if timer <= 0.0:
		if next_state:
			#Izzy here: If the enemy contains sfx_enemy_walk AudioStreamer2d, it will stop as it transitions tot the next statee
			if sfx_enemy_walk:
				sfx_enemy_walk.stop()
			transitioned.emit(self, next_state.name)
			
