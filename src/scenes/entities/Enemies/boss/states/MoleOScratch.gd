extends State
class_name MoleOScratch

var boss: boss_mole

@export_category("Attack Settings")
@export var attack_component: AttackComponent

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	boss.get_node("HitboxComponent").is_invincible = true
	boss.get_node("AnimatedSprite2D").play("O_attack_scratch")
	
	if attack_component:
		attack_component.clear_hit_list()
		_set_hitbox_disabled(false)

func exit() -> void:
	if attack_component:
		_set_hitbox_disabled(true)

func physics_update(_delta: float) -> void:
	if not boss.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "moleidle")

func _set_hitbox_disabled(is_disabled: bool) -> void:
	if attack_component:
		for child in attack_component.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", is_disabled)
