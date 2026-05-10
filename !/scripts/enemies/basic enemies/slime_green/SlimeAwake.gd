extends State
class_name SlimeAwake

var enemy: BaseEnemy

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.velocity.x = 0
	enemy.get_node("AnimatedSprite2D").play("awake")

func physics_update(_delta: float) -> void:
	# Return Idle when animation finishes
	if not enemy.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "idle")
