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
		
		# Knockback
		if owner is CharacterBody2D:
			# Is enemy flying type?
			if "is_flying_entity" in owner and owner.is_flying_entity:
				var knockback_dir = attack.global_position.direction_to(global_position)
				owner.velocity = knockback_dir * attack.knockback_force
			else:
				var dir_x = sign(global_position.x - attack.global_position.x)
				# If entities are standing on the exact same spot
				if dir_x == 0:
					dir_x = 1
				owner.velocity = Vector2(dir_x * attack.knockback_force, -attack.knockback_force * 0.8)
			
		
		
		if invincibility_time > 0:
			is_invincible = true
			# Create timer for invincibility counter
			get_tree().create_timer(invincibility_time).timeout.connect(func(): is_invincible = false)
