extends State
class_name MoleAction

var boss: boss_mole
#Izzy here: establishing that if boss is underground, the underground movement sound plays
@onready var mine_boss_walk_underground: AudioStreamPlayer2D = $"../../mine_boss_walk_underground"

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	
	boss.get_node("HitboxComponent").is_invincible = true
	boss.attack_cooldown_timer = boss.attack_cooldown

func physics_update(_delta: float) -> void:
	if boss.is_underground:
		transitioned.emit(self, "moleuscratch")
		#Izzy here: if the boss is underground he should play his underground movement sound
		mine_boss_walk_underground.play()
	else:
		var roll = randf() 
		#Izzy here: if the boss is not underground he must stop from playing his sound
		mine_boss_walk_underground.stop()
		if roll <= 0.8:
			transitioned.emit(self, "moleoscratch") # 80%
		else:
			transitioned.emit(self, "moleorollstart") # 20%	
