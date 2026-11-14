extends State
class_name EnemyFlyingChase

const BRAKE_FRICTION: float = 800.0
const ATTACK_RANGE_BUFFER: float = 10.0

var enemy: BaseEnemy

@export_category("Chase Settings")
## Name of Animation to be played from AnimatedSprite2D
@export var animation_name: String = "fly"
## Flying speed when chasing
@export var chase_speed: float = 70.0
## Distance that enemy will try to stay from player
@export var hover_radius: float = 100.0 
## Tolerance offset to de-jitter movement at hover_radius
@export var tolerance: float = 15.0 
## Offset to aim for body/head instead of feet
@export var target_offset: Vector2 = Vector2(0, -15)

@export_category("State Transitions")
## Attack state
@export var attack_state: State
## State to return to when the player escapes detection
@export var lost_player_state: State

func _ready() -> void:
	enemy = owner

func enter() -> void:
	if enemy.sprite:
		enemy.sprite.play(animation_name)

func physics_update(delta: float) -> void:
	if lost_player_state and not enemy.can_see_player():
		transitioned.emit(self, lost_player_state.name)
		return
		
	var target = PlayerManager.player
	if target != null:
		var target_pos = target.global_position + target_offset
		var dist = enemy.global_position.distance_to(target_pos)
		var direction = enemy.global_position.direction_to(target_pos)
		
		if direction.x != 0:
			enemy.update_facing(sign(direction.x))
		
		if dist > hover_radius + tolerance:
			# If too far away, fly to player
			enemy.velocity = direction * chase_speed
		elif dist < hover_radius - tolerance:
			# If too close, fly away from player
			enemy.velocity = -direction * (chase_speed * 0.5)
		else:
			# If perfect distance, brake and just stay
			enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, BRAKE_FRICTION * delta)
		
		if dist <= hover_radius + tolerance + ATTACK_RANGE_BUFFER:
			if attack_state and enemy.attack_cooldown_timer <= 0.0:
				enemy.attack_cooldown_timer = enemy.attack_cooldown
				transitioned.emit(self, attack_state.name)
	else:
		enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, BRAKE_FRICTION * delta)
