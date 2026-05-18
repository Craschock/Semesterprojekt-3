extends State
class_name SlimeIdle

var enemy: BaseEnemy

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.velocity.x = 0
	enemy.get_node("AnimatedSprite2D").play("idle")
