extends State
class_name EnemyHit

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "hit"
## Next State Node to transition to
@export var next_state: State

func _ready() -> void:
	enemy = owner

func enter() -> void:
	# Stop moving when hit
	enemy.velocity.x = 0 
	enemy.get_node("AnimatedSprite2D").play("hit")

func physics_update(_delta: float) -> void:
	# Return Idle when animation finishes
	if not enemy.get_node("AnimatedSprite2D").is_playing():
		if next_state:
			transitioned.emit(self, next_state.name)
