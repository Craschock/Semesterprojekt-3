extends State
class_name EnemyHit

var enemy: BaseEnemy

# What state after hit?
@export var next_state: String = "idle"

func _ready() -> void:
	enemy = owner

func enter() -> void:
	# Stop moving when hit
	enemy.velocity.x = 0 
	enemy.get_node("AnimatedSprite2D").play("hit")

func physics_update(_delta: float) -> void:
	# Return Idle when animation finishes
	if not enemy.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, next_state)
