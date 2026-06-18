extends State
class_name EnemyIdle

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "idle"
## Next State Node to transition to
@export var next_state: State

@export_category("Idle Settings")
## Minimum amount of how long entity is idle (in seconds)
@export var min_idle_time: float = 0.5
## Maximum amount of how long entity is idle (in seconds)
@export var max_idle_time: float = 2.0

var timer: float = 0.0

func _ready() -> void:
	enemy = owner

func enter() -> void:
	# Stop movement
	enemy.velocity.x = 0.0
	enemy.get_node("AnimatedSprite2D").play(animation_name)
	timer = randf_range(min_idle_time, max_idle_time)

func physics_update(delta: float) -> void:
	timer -= delta
	
	if timer <= 0.0:
		transitioned.emit(self, next_state.name)
