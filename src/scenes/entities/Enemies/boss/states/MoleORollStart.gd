extends State
class_name MoleORollStart

var boss: boss_mole

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	boss.get_node("HitboxComponent").is_invincible = true
	boss.get_node("AnimatedSprite2D").play("O_attack_rollStart")

func physics_update(_delta: float) -> void:
	if not boss.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "moleoroll")
