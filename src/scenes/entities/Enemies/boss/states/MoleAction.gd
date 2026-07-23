extends State
class_name MoleAction

var boss: boss_mole

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	
	boss.get_node("HitboxComponent").is_invincible = true
	boss.attack_cooldown_timer = boss.attack_cooldown

func physics_update(_delta: float) -> void:
	if boss.is_underground:
		transitioned.emit(self, "moleuscratch")
	else:
		var roll = randf() 
		
		if roll <= 0.8:
			transitioned.emit(self, "moleoscratch") # 80%
		else:
			transitioned.emit(self, "moleorollstart") # 20%	
