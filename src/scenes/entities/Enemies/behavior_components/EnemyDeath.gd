extends State
class_name EnemyDeath

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "death"

@export_category("Physics")
## Reibem
@export var friction: float = 800.0

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.get_node("AnimatedSprite2D").play(animation_name)
	
	# Disable flying if flying enemy
	if "is_flying_entity" in enemy and enemy.is_flying_entity:
		enemy.is_flying_entity = false
		enemy.apply_gravity = true

func physics_update(delta: float) -> void:
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, friction * delta)
	
	if not enemy.get_node("AnimatedSprite2D").is_playing():
		enemy.queue_free()
