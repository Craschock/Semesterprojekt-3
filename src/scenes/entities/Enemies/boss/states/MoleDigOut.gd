extends State
class_name MoleDigOut

var boss: boss_mole

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	
	boss.get_node("HitboxComponent").is_invincible = true
	boss.get_node("AnimatedSprite2D").play("dig_out")
	boss.dig_out()

func physics_update(_delta: float) -> void:
	if not boss.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "moleidle")
