extends State
class_name EnemyFlyingMove

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from AnimatedSprite2D
@export var animation_name: String = "fly"
## Next State Node to transition to when move timer ends
@export var next_state: State
## Chase State to transition to if the player is spotted
@export var chase_state: State

@export_category("Flight Settings")
@export var speed: float = 40.0
@export var min_move_time: float = 0.5
@export var max_move_time: float = 3.0
	
var timer: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

var possible_directions: Array[Vector2] = [
	Vector2(0, -1),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(1, 0),
	Vector2(-1, -1).normalized(),
	Vector2(1, -1).normalized(),
	Vector2(-1, 1).normalized(),
	Vector2(1, 1).normalized()
]

func _ready() -> void:
	enemy = owner

func enter() -> void:
	if enemy.sprite:
		enemy.sprite.play(animation_name)
	timer = randf_range(min_move_time, max_move_time)
	move_direction = possible_directions.pick_random()

func physics_update(delta: float) -> void:
	if chase_state and enemy.can_see_player():
		transitioned.emit(self, chase_state.name)
		return
		
	timer -= delta
	enemy.velocity = move_direction * speed
	
	if move_direction.x != 0:
		enemy.update_facing(sign(move_direction.x))
	
	if timer <= 0.0 and next_state:
		transitioned.emit(self, next_state.name)
