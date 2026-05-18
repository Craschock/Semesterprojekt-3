extends Area2D
class_name HitboxComponent

# Drag the entity HealthComponent here
@export var health_component: HealthComponent

func take_hit(attack: AttackComponent) -> void:
	if health_component:
		health_component.take_damage(attack.damage)
		EffectManager.spawn_damage_number(global_position, attack.damage)
