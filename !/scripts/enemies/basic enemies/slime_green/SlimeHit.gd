extends State
class_name SlimeHit

var enemy: BaseEnemy

func _ready() -> void:
	enemy = owner

func enter() -> void:
	# Stop moving when hit
	enemy.velocity.x = 0 
	enemy.get_node("AnimatedSprite2D").play("hit")

func physics_update(_delta: float) -> void:
	# Return Idle when animation finishes
	if not enemy.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "idle")
