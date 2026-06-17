extends State
class_name EnemyWalk

var enemy: BaseEnemy

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
	enemy.get_node("AnimatedSprite2D").play("run")
	
	# Pick random walk time
	timer = randf_range(min_walk_time, max_walk_time)
	
	# Pick random direction
	direction = [-1, 1].pick_random()
	
	# Handle sprite flipping
	_flip_visuals()

func physics_update(delta: float) -> void:
	timer -= delta
	
	# Apply movement
	enemy.velocity.x = direction * speed
	
	if timer <= 0.0:
		transitioned.emit(self, "idle")

# Flip logic
func _flip_visuals() -> void:
	var sprite = enemy.get_node("AnimatedSprite2D")
	
	if flip_sprite:
		sprite.flip_h = (direction > 0)
	else:
		sprite.flip_h = (direction < 0)
