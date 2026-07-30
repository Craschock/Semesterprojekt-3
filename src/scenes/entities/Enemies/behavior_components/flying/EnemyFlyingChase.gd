extends State
class_name EnemyFlyingChase

var enemy: BaseEnemy

@export_category("Chase Settings")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "fly"
## Flying speed when chasinhg
@export var chase_speed: float = 70.0
## Distance, that enemy will try to stay from player
@export var hover_radius: float = 100.0 
## Tolerance offset for the distance holding (var above) just to de-jitter the movement when enemy is *right* at the distance
@export var tolerance: float = 15.0 
## Offset to aim for body/head instead of feet
@export var target_offset: Vector2 = Vector2(0, -15)

@export_category("Attack Transition")
## Attack state 
@export var attack_state: State

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.get_node("AnimatedSprite2D").play(animation_name)

func physics_update(delta: float) -> void:
	var target = PlayerManager.player
	
	if target != null:
		var target_pos = target.global_position + target_offset
		var dist = enemy.global_position.distance_to(target_pos)
		var direction = enemy.global_position.direction_to(target_pos)
		
		if direction.x != 0:
			enemy.update_facing(sign(direction.x))
		
		# Distance/Hover radius movement
		if dist > hover_radius + tolerance:
			# If too far away, fly to player
			enemy.velocity = direction * chase_speed
			
		elif dist < hover_radius - tolerance:
			# If too close, fly away from player
			enemy.velocity = -direction * (chase_speed * 0.5)
			
		else:
			# If perfect distance, brake and just stay
			enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, 800 * delta)
		
		# Attack 
		if dist <= hover_radius + tolerance + 10.0:
			if attack_state and enemy.attack_cooldown_timer <= 0.0:
				enemy.attack_cooldown_timer = enemy.attack_cooldown
				transitioned.emit(self, attack_state.name)
				
	else:
		# Brake 
		enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, 800 * delta)
