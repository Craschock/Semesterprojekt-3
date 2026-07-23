extends State
class_name MoleORollBrake

var boss: boss_mole

@export_category("Brake Settings")
@export var brake_friction: float = 400.0

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.get_node("HitboxComponent").is_invincible = true
	boss.get_node("AnimatedSprite2D").play("O_attack_rollBrake")

func physics_update(delta: float) -> void:
	boss.velocity.x = move_toward(boss.velocity.x, 0, brake_friction * delta)
	
	if not boss.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "moleorollstop")
