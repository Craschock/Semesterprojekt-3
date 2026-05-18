extends State
class_name EnemyPatrol

var enemy: BaseEnemy

@export var speed: float = 30.0
@export var patrol_duration: float = 5.0
@export var direction: int = 1 # -1 is Left, 1 is Right
@export var flip_sprite = false

var timer: float = 0.0

func _ready() -> void:
	enemy = owner

func enter() -> void:
	# Reset the timer when enter patrol state
	timer = patrol_duration
	enemy.get_node("AnimatedSprite2D").play("run")

func physics_update(delta: float) -> void:
	timer -= delta
	
	# When time runs out, flip direction reset timer
	if timer <= 0.0:
		direction *= -1
		timer = patrol_duration
		
	# Flip the sprite visual
	if flip_sprite:
		if direction > 0:
			enemy.get_node("AnimatedSprite2D").flip_h = true
		else:
			enemy.get_node("AnimatedSprite2D").flip_h = false
	else:     # If sprite was drawn mirrored
		if direction < 0:
			enemy.get_node("AnimatedSprite2D").flip_h = true
		else:
			enemy.get_node("AnimatedSprite2D").flip_h = false
	
	
	# Apply the movement
	enemy.velocity.x = direction * speed
