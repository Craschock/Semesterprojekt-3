extends State
class_name MoleORoll

var boss: boss_mole

@export_category("Roll Settings")
@export var roll_speed: float = 250.0
@export var roll_duration: float = 6.0
@export var attack_component: AttackComponent

var timer: float = 0.0
var roll_direction: int = 1

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.get_node("HitboxComponent").is_invincible = true
	boss.get_node("AnimatedSprite2D").play("O_attack_roll")
	timer = roll_duration

	var target = PlayerManager.player
	if target:
		roll_direction = sign(boss.global_position.direction_to(target.global_position).x)
		if roll_direction == 0:
			roll_direction = 1
		boss.update_facing(roll_direction)

	if attack_component:
		attack_component.clear_hit_list()
		_set_hitbox_disabled(false)

func exit() -> void:
	if attack_component:
		_set_hitbox_disabled(true)

func physics_update(delta: float) -> void:
	timer -= delta
	boss.velocity.x = roll_direction * roll_speed
	
	if timer <= 0.0:
		transitioned.emit(self, "moleorollbrake")

func _set_hitbox_disabled(is_disabled: bool) -> void:
	if attack_component:
		for child in attack_component.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", is_disabled)
