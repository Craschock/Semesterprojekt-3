extends Area2D
class_name HitboxComponent

# Drag the entity HealthComponent here
@export var health_component: HealthComponent
@export var invincibility_time: float = 0.0

var is_invincible: bool = false

func take_hit(attack: AttackComponent) -> void:
	# Block damage if invincible
	if is_invincible:
		return
	
	if health_component:
		health_component.take_damage(attack.damage)
		EffectManager.spawn_damage_number(global_position, attack.damage)
		
		if invincibility_time > 0:
			is_invincible = true
			# Create timer for invincibility counter
			get_tree().create_timer(invincibility_time).timeout.connect(func(): is_invincible = false)
