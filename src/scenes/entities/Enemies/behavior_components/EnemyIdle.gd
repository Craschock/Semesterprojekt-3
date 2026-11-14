extends State
class_name EnemyIdle

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from AnimatedSprite2D
@export var animation_name: String = "idle"
## Next patrol/walk State Node to transition to when timer ends
@export var next_state: State
## Chase State to transition to immediately if the player is spotted
@export var chase_state: State

@export_category("Idle Settings")
## Minimum duration entity stays idle (in seconds)
@export var min_idle_time: float = 0.5
## Maximum duration entity stays idle (in seconds)
@export var max_idle_time: float = 2.0

var timer: float = 0.0

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	if enemy.sprite:
		enemy.sprite.play(animation_name)
	timer = randf_range(min_idle_time, max_idle_time)

func physics_update(delta: float) -> void:
	# Transition to chase if player is spotted!
	if chase_state and enemy.can_see_player():
		transitioned.emit(self, chase_state.name)
		return
		
	timer -= delta
	if timer <= 0.0 and next_state:
		transitioned.emit(self, next_state.name)
