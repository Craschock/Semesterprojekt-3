extends State
class_name MoleDigOut

var boss: boss_mole
@onready var mole_dig_out: MoleDigOut = $"."
#Izzy here: establishing the jump sound as a variable
@onready var mine_boss_jump: AudioStreamPlayer2D = $"../../mine_boss_jump"


func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	
	boss.get_node("HitboxComponent").is_invincible = true
	#Izzy here: if the boss jumps out of the ground, he ought to play his jump sound
	mine_boss_jump.play()
	boss.get_node("AnimatedSprite2D").play("dig_out")
	boss.dig_out()

func physics_update(_delta: float) -> void:
	if not boss.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "moleidle")
