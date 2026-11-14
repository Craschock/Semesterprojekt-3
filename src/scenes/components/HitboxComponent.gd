extends Area2D
class_name HitboxComponent

signal parry_triggered(attack: AttackComponent)
signal hit_received(attack: AttackComponent)

@export_category("Components")
## Reference to the entity's HealthComponent
@export var health_component: HealthComponent

@export_category("Defense & Invincibility")
## Duration in seconds the entity stays invincible after taking a hit
@export var invincibility_time: float = 0.0

@export_category("Knockback Settings")
## If false, this entity will never be pushed by attacks
@export var can_receive_knockback: bool = true
## Reduces incoming knockback (0.0 = full knockback, 1.0 = completely immune)
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
## Multiplier for upward pop when grounded entities are knocked back
@export var grounded_upward_pop_ratio: float = 0.8

var is_invincible: bool = false
var is_parrying: bool = false

func take_hit(attack: AttackComponent) -> void:
	# Check Parry 
	if is_parrying and attack.can_be_parried:
		parry_triggered.emit(attack)
		return
	
	# Block damage if invincible
	if is_invincible:
		return
	
	# Apply Damage & Visuals
	if health_component:
		health_component.take_damage(attack.damage)
		EffectManager.spawn_damage_number(global_position, attack.damage)
		hit_received.emit(attack)
		
		# Apply Knockback
		if can_receive_knockback and knockback_resistance < 1.0:
			var final_force: float = attack.knockback_force * (1.0 - knockback_resistance)
			_handle_knockback(attack.global_position, final_force)
		
		# Start Invincibility Timer
		if invincibility_time > 0.0:
			is_invincible = true
			get_tree().create_timer(invincibility_time).timeout.connect(
				func(): is_invincible = false
			)

func _handle_knockback(source_pos: Vector2, force: float) -> void:
	if owner == null or not (owner is CharacterBody2D):
		return
		
	# If owner has custom knockback logic, use it
	if owner.has_method("apply_knockback"):
		owner.apply_knockback(source_pos, force, grounded_upward_pop_ratio)
	else:
		# Fallback for PlayerMovement
		var dir_x: float = sign(global_position.x - source_pos.x)
		if dir_x == 0.0:
			dir_x = 1.0
		owner.velocity = Vector2(dir_x * force, -force * grounded_upward_pop_ratio)
