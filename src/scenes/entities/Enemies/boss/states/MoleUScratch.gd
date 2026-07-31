extends State
class_name MoleUScratch

var boss: boss_mole
var has_attacked: bool = false
@onready var mine_boss_attack_underground: AudioStreamPlayer2D = $"../../mine_boss_attack_underground"

@export_category("Attack Settings")
@export var attack_component: AttackComponent

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	boss.get_node("HitboxComponent").is_invincible = true
	has_attacked = false
	#Izzy here: when mole attacks underground, the attack underground plays
	mine_boss_attack_underground.play()
	boss.get_node("AnimatedSprite2D").play("U_attack_scratch")
	
	if attack_component:
		attack_component.clear_hit_list()
		_set_hitbox_disabled(true)

func exit() -> void:
	if attack_component:
		_set_hitbox_disabled(true)

func physics_update(_delta: float) -> void:
	var sprite = boss.get_node("AnimatedSprite2D")
	if not has_attacked and sprite.frame >= 6:
		has_attacked = true
		if attack_component:
			_set_hitbox_disabled(false)
	
	if not sprite.is_playing():
		transitioned.emit(self, "moleidle")

func _set_hitbox_disabled(is_disabled: bool) -> void:
	if attack_component:
		for child in attack_component.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", is_disabled)
