extends State
class_name EnemyHit

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "hit"
## Next State Node to transition to
@export var next_state: State

@export_category("Values")
## Friction for enemy movement
@export var friction: float = 800 

func _ready() -> void:
	enemy = owner

func enter() -> void:
	# Stop moving when hit
	enemy.get_node("AnimatedSprite2D").play(animation_name)

func physics_update(delta: float) -> void:
	# Flying enemy
	if "is_flying_entity" in enemy and enemy.is_flying_entity:
		enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, friction * delta)
	# Groundeds enemy
	else:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, friction * delta)
	
	# Return Idle when animation finishes
	if not enemy.get_node("AnimatedSprite2D").is_playing():
		if next_state:
			transitioned.emit(self, next_state.name)
