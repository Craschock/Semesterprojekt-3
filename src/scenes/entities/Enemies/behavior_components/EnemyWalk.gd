extends State
class_name EnemyWalk

#Izzy here: established sfx_enemy_walk as a variable
@onready var sfx_enemy_walk: AudioStreamPlayer2D = $"../../sfx_enemy_walk"

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from AnimatedSprite2D
@export var animation_name: String = "walk"
## Next idle State Node to transition to when timer ends
@export var next_state: State
## Chase State to transition to immediately if the player is spotted
@export var chase_state: State

@export_category("Walk Settings")
@export var speed: float = 30.0
## Minimum duration entity walks (in seconds)
@export var min_walk_time: float = 0.3
## Maximum duration entity walks (in seconds)
@export var max_walk_time: float = 3.0
@export var flip_sprite: bool = false

var timer: float = 0.0
var direction: int = 1

func _ready() -> void:
	enemy = owner

func enter() -> void:
	if enemy.sprite:
		enemy.sprite.play(animation_name)
	
	# Pick random walk time
	timer = randf_range(min_walk_time, max_walk_time)
	
	# Pick random direction
	direction = [-1, 1].pick_random()
	
	#Izzy here: If the enemy walking has a sfx_enemy_walk, it will start playing the sound heree
	if sfx_enemy_walk:
		sfx_enemy_walk.play()

func physics_update(delta: float) -> void:
	
	
	# Apply movement
	enemy.velocity.x = direction * speed
	enemy.update_facing(direction)
	
	if chase_state and enemy.can_see_player():
		transitioned.emit(self, chase_state.name)
		return
	
	timer -= delta
	if timer <= 0.0 and next_state:
		
		#Izzy here: If the enemy contains sfx_enemy_walk AudioStreamer2d, it will stop as it transitions tot the next statee
		if sfx_enemy_walk:
			sfx_enemy_walk.stop()
			
		transitioned.emit(self, next_state.name)
