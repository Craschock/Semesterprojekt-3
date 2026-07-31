extends State
class_name MoleDigIn

var boss: boss_mole
@onready var mine_boss_dig: AudioStreamPlayer2D = $"../../mine_boss_dig"


func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	
	boss.get_node("HitboxComponent").is_invincible = true
	#Izzy here: Playing sound for digging in: boss_dig
	mine_boss_dig.play()
	boss.get_node("AnimatedSprite2D").play("dig_in")
	boss.dig_in()

func physics_update(_delta: float) -> void:
	if not boss.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "moleidle")
